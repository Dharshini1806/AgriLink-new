const db = require('../../config/db');
const { updateTrustScore } = require('../smart/trust.service');
const { BadRequestError, NotFoundError, ForbiddenError } = require('../../middleware/errorHandler');
const { analyzeSentiment } = require('../../utils/sentiment');

/**
 * Creates a product/seller review and performs sentiment analysis automatically
 */
async function createReview(reviewerId, { productId, revieweeId, orderId, rating, comment, feedbackTags = [] }) {
  // 1. Verify order exists and reviewer is the buyer
  const orderRes = await db.query(
    'SELECT buyer_id, seller_id, status FROM orders WHERE id=$1', [orderId]
  );
  if (!orderRes.rows[0]) throw new NotFoundError('Order not found');
  const order = orderRes.rows[0];

  if (order.buyer_id !== reviewerId) {
    throw new ForbiddenError('Only the buyer of this order can submit feedback');
  }

  if (order.status !== 'delivered') {
    throw new BadRequestError('Order must be delivered before giving feedback');
  }

  // 2. If productId is provided, verify it is part of this order
  if (productId) {
    const itemRes = await db.query(
      'SELECT 1 FROM order_items WHERE order_id = $1 AND product_id = $2',
      [orderId, productId]
    );
    if (!itemRes.rows[0]) {
      throw new BadRequestError('Product is not part of this order');
    }
  }

  // 3. Prevent duplicate reviews
  const dupRes = await db.query(
    `SELECT id FROM reviews 
     WHERE order_id = $1 AND reviewer_id = $2 
       AND COALESCE(product_id, '00000000-0000-0000-0000-000000000000'::uuid) = COALESCE($3, '00000000-0000-0000-0000-000000000000'::uuid)`,
    [orderId, reviewerId, productId || null]
  );
  if (dupRes.rows.length > 0) {
    throw new BadRequestError('You have already submitted feedback for this order item');
  }

  // 4. Validate and filter feedback tags
  const allowedTags = [
    'Good Quality', 'Excellent Product', 'Value for Money', 'Fast Delivery',
    'Poor Quality', 'Not as Expected', 'Damaged Product', 'Wrong Product'
  ];
  const validTags = (feedbackTags || []).filter(t => allowedTags.includes(t));

  // 5. Analyze sentiment with rating context
  const sent = analyzeSentiment(comment, rating);

  // 6. Insert review
  const res = await db.query(
    `INSERT INTO reviews (
       reviewer_id, user_id, product_id, reviewee_id, order_id, 
       rating, comment, review_text, sentiment, sentiment_score, 
       sentiment_label, feedback_tags
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
     RETURNING *`,
    [
      reviewerId, reviewerId, productId || null, revieweeId || order.seller_id || null, orderId,
      rating, comment || null, comment || null, sent.sentiment, sent.sentiment_score,
      sent.sentiment_label, validTags
    ]
  );

  // 7. Update trust score for reviewee
  const targetRevieweeId = revieweeId || order.seller_id;
  if (targetRevieweeId) await updateTrustScore(targetRevieweeId);

  return res.rows[0];
}

async function getProductReviews(productId, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT r.*, u.name AS reviewer_name, u.profile_img AS reviewer_img
     FROM reviews r
     JOIN users u ON u.id = r.reviewer_id
     WHERE r.product_id=$1
     ORDER BY r.created_at DESC
     LIMIT $2 OFFSET $3`,
    [productId, limit, offset]
  );
  const countRes = await db.query('SELECT COUNT(*)::INT AS total FROM reviews WHERE product_id=$1', [productId]);
  return { data: res.rows, total: countRes.rows[0].total, page, limit };
}

async function getUserReviews(userId, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT r.*, p.name AS product_name, p.image_urls AS product_images
     FROM reviews r
     LEFT JOIN products p ON p.id = r.product_id
     WHERE r.reviewer_id = $1
     ORDER BY r.created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  const countRes = await db.query('SELECT COUNT(*)::INT AS total FROM reviews WHERE reviewer_id=$1', [userId]);
  return { data: res.rows, total: countRes.rows[0].total, page, limit };
}

async function getReviewEligibility(userId, productId) {
  const sql = `
    SELECT o.id AS order_id
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.buyer_id = $1 AND oi.product_id = $2 AND o.status = 'delivered'
      AND o.id NOT IN (
        SELECT order_id FROM reviews 
        WHERE reviewer_id = $1 AND product_id = $2
      )
    ORDER BY o.created_at DESC
    LIMIT 1
  `;
  const res = await db.query(sql, [userId, productId]);
  if (res.rows.length > 0) {
    return { eligible: true, orderId: res.rows[0].order_id };
  }
  return { eligible: false, reason: 'You must purchase and receive the product before leaving a review' };
}

async function reanalyzeReviewSentiment(reviewId) {
  const res = await db.query('SELECT id, comment FROM reviews WHERE id = $1', [reviewId]);
  if (!res.rows[0]) throw new NotFoundError('Review not found');

  const { comment } = res.rows[0];
  const sent = analyzeSentiment(comment);

  const updateRes = await db.query(
    `UPDATE reviews SET
       sentiment = $1,
       sentiment_score = $2,
       sentiment_label = $3,
       updated_at = NOW()
     WHERE id = $4
     RETURNING *`,
    [sent.sentiment, sent.sentiment_score, sent.sentiment_label, reviewId]
  );
  return updateRes.rows[0];
}

async function getProductReviewSummary(productId) {
  const sql = `
    SELECT
      COUNT(*)::INT AS total_reviews,
      COALESCE(AVG(rating), 0)::DECIMAL(3,2) AS average_rating,
      COUNT(*) FILTER (WHERE rating = 5)::INT AS rating_5_count,
      COUNT(*) FILTER (WHERE rating = 4)::INT AS rating_4_count,
      COUNT(*) FILTER (WHERE rating = 3)::INT AS rating_3_count,
      COUNT(*) FILTER (WHERE rating = 2)::INT AS rating_2_count,
      COUNT(*) FILTER (WHERE rating = 1)::INT AS rating_1_count,
      COUNT(*) FILTER (WHERE sentiment_label = 'positive')::INT AS positive_count,
      COUNT(*) FILTER (WHERE sentiment_label = 'negative')::INT AS negative_count,
      COUNT(*) FILTER (WHERE sentiment_label = 'neutral' OR sentiment_label IS NULL)::INT AS neutral_count
    FROM reviews
    WHERE product_id = $1
  `;
  const res = await db.query(sql, [productId]);
  const stats = res.rows[0];
  const total = stats.total_reviews || 0;

  if (total === 0) {
    return {
      averageRating: 0,
      totalReviews: 0,
      distribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 },
      sentimentSummary: { positive: 0, neutral: 0, negative: 0 },
    };
  }

  const distribution = {
    5: Math.round((stats.rating_5_count / total) * 100),
    4: Math.round((stats.rating_4_count / total) * 100),
    3: Math.round((stats.rating_3_count / total) * 100),
    2: Math.round((stats.rating_2_count / total) * 100),
    1: Math.round((stats.rating_1_count / total) * 100),
  };
  const sentimentSummary = {
    positive: Math.round((stats.positive_count / total) * 100),
    neutral:  Math.round((stats.neutral_count  / total) * 100),
    negative: Math.round((stats.negative_count / total) * 100),
  };
  return {
    averageRating: parseFloat(stats.average_rating) || 0,
    totalReviews: stats.total_reviews,
    distribution,
    sentimentSummary
  };
}

/**
 * Re-analyze sentiment for all reviews of a product where sentiment is missing or null.
 * Also re-analyzes any reviews with comment text regardless of existing label,
 * so existing reviews get correct sentiment scores.
 */
async function bulkReanalyzeProductSentiment(productId) {
  const res = await db.query(
    `SELECT id, COALESCE(comment, review_text) AS text FROM reviews WHERE product_id = $1`,
    [productId]
  );
  let updated = 0;
  for (const row of res.rows) {
    const sent = analyzeSentiment(row.text || '');
    await db.query(
      `UPDATE reviews SET
         sentiment = $1,
         sentiment_score = $2,
         sentiment_label = $3,
         updated_at = NOW()
       WHERE id = $4`,
      [sent.sentiment, sent.sentiment_score, sent.sentiment_label, row.id]
    );
    updated++;
  }
  return { updated };
}

/**
 * Admin: Re-analyze ALL reviews in the database that have missing sentiment.
 */
async function bulkReanalyzeAllSentiment() {
  const res = await db.query(
    `SELECT id, COALESCE(comment, review_text) AS text FROM reviews WHERE sentiment_label IS NULL OR sentiment_label = ''`
  );
  let updated = 0;
  for (const row of res.rows) {
    const sent = analyzeSentiment(row.text || '');
    await db.query(
      `UPDATE reviews SET
         sentiment = $1,
         sentiment_score = $2,
         sentiment_label = $3,
         updated_at = NOW()
       WHERE id = $4`,
      [sent.sentiment, sent.sentiment_score, sent.sentiment_label, row.id]
    );
    updated++;
  }
  return { updated };
}

module.exports = {
  createReview,
  getProductReviews,
  getUserReviews,
  getReviewEligibility,
  reanalyzeReviewSentiment,
  getProductReviewSummary,
  bulkReanalyzeProductSentiment,
  bulkReanalyzeAllSentiment,
};
