const db = require('../../config/db');
const { NotFoundError } = require('../../middleware/errorHandler');

// ── User Management ───────────────────────────────────────

async function listUsers({ page = 1, limit = 20, role, q }) {
  const offset = (page - 1) * limit;
  const params = [limit, offset];
  const conditions = [];

  if (role) { params.push(role); conditions.push(`role=$${params.length}`); }
  if (q)    { params.push(`%${q}%`); conditions.push(`(name ILIKE $${params.length} OR email ILIKE $${params.length})`); }

  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  const res = await db.query(
    `SELECT id, name, email, role, phone, trust_score, is_active, created_at,
            (SELECT COUNT(*) FROM orders WHERE buyer_id=users.id OR seller_id=users.id)::INT AS order_count
     FROM users ${where}
     ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
    params
  );
  const count = await db.query(`SELECT COUNT(*)::INT AS total FROM users ${where}`, params.slice(2));
  return { data: res.rows, total: count.rows[0].total };
}

async function setUserBanStatus(userId, isBanned, reason) {
  const res = await db.query('SELECT id FROM users WHERE id=$1', [userId]);
  if (!res.rows[0]) throw new NotFoundError('User not found');
  await db.query('UPDATE users SET is_active=$1, updated_at=NOW() WHERE id=$2', [!isBanned, userId]);
  return { userId, is_active: !isBanned, reason };
}

// ── Product Moderation ────────────────────────────────────

async function listPendingProducts({ page = 1, limit = 20 }) {
  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT p.*, u.name AS seller_name, u.email AS seller_email, c.name AS category_name
     FROM products p
     JOIN users u ON u.id = p.seller_id
     JOIN categories c ON c.id = p.category_id
     WHERE p.is_approved = FALSE
     ORDER BY p.created_at ASC
     LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  return res.rows;
}

async function moderateProduct(productId, approve) {
  const res = await db.query('SELECT id FROM products WHERE id=$1', [productId]);
  if (!res.rows[0]) throw new NotFoundError('Product not found');
  await db.query(
    'UPDATE products SET is_approved=$1, is_active=$1, updated_at=NOW() WHERE id=$2',
    [approve, productId]
  );
  return { productId, approved: approve };
}

// ── Revenue Analytics ─────────────────────────────────────

async function getRevenueAnalytics(from, to, groupBy = 'day') {
  const truncFunc = groupBy === 'month' ? 'month' : groupBy === 'week' ? 'week' : 'day';

  const res = await db.query(
    `SELECT
       DATE_TRUNC($1, t.created_at) AS period,
       COUNT(*)::INT AS order_count,
       SUM(t.platform_fee)::DECIMAL(12,2) AS platform_revenue,
       SUM(t.gross_amount)::DECIMAL(12,2) AS gross_volume,
       SUM(t.net_seller_payout)::DECIMAL(12,2) AS seller_payouts
     FROM transactions t
     JOIN orders o ON o.id = t.order_id
     WHERE t.status='settled' AND t.created_at BETWEEN $2 AND $3
     GROUP BY period
     ORDER BY period ASC`,
    [truncFunc, from || new Date(Date.now() - 30 * 86400000), to || new Date()]
  );

  const summary = await db.query(
    `SELECT
       COUNT(*)::INT AS total_orders,
       SUM(platform_fee)::DECIMAL(12,2) AS total_revenue,
       SUM(gross_amount)::DECIMAL(12,2) AS total_volume,
       AVG(platform_fee)::DECIMAL(10,2) AS avg_order_revenue
     FROM transactions
     WHERE status='settled' AND created_at BETWEEN $1 AND $2`,
    [from || new Date(Date.now() - 30 * 86400000), to || new Date()]
  );

  const topSellers = await db.query(
    `SELECT u.id, u.name, u.email, u.trust_score,
            COUNT(o.id)::INT AS order_count,
            SUM(t.net_seller_payout)::DECIMAL(12,2) AS total_earnings
     FROM users u
     JOIN orders o ON o.seller_id = u.id
     JOIN transactions t ON t.order_id = o.id
     WHERE t.status='settled' AND t.created_at BETWEEN $1 AND $2
     GROUP BY u.id
     ORDER BY total_earnings DESC LIMIT 10`,
    [from || new Date(Date.now() - 30 * 86400000), to || new Date()]
  );

  const topCategories = await db.query(
    `SELECT c.name, COUNT(oi.id)::INT AS item_count, SUM(oi.quantity * oi.unit_price)::DECIMAL(12,2) AS volume
     FROM order_items oi
     JOIN products p ON p.id = oi.product_id
     JOIN categories c ON c.id = p.category_id
     JOIN orders o ON o.id = oi.order_id
     WHERE o.status='delivered' AND o.created_at BETWEEN $1 AND $2
     GROUP BY c.name ORDER BY volume DESC LIMIT 5`,
    [from || new Date(Date.now() - 30 * 86400000), to || new Date()]
  );

  return {
    timeline: res.rows,
    summary: summary.rows[0],
    topSellers: topSellers.rows,
    topCategories: topCategories.rows,
  };
}

// ── Platform Overview ─────────────────────────────────────

async function getDashboardStats() {
  const [users, products, orders, revenue] = await Promise.all([
    db.query(`SELECT
      COUNT(*)::INT AS total,
      COUNT(*) FILTER (WHERE role='buyer')::INT AS buyers,
      COUNT(*) FILTER (WHERE role='seller')::INT AS sellers,
      COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '7 days')::INT AS new_this_week
      FROM users WHERE role != 'admin'`),

    db.query(`SELECT
      COUNT(*)::INT AS total,
      COUNT(*) FILTER (WHERE is_active=TRUE)::INT AS active,
      COUNT(*) FILTER (WHERE is_approved=FALSE)::INT AS pending_moderation
      FROM products`),

    db.query(`SELECT
      COUNT(*)::INT AS total,
      COUNT(*) FILTER (WHERE status='pending')::INT AS pending,
      COUNT(*) FILTER (WHERE status='delivered')::INT AS delivered,
      COUNT(*) FILTER (WHERE status='cancelled')::INT AS cancelled,
      COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 day')::INT AS today
      FROM orders`),

    db.query(`SELECT
      COALESCE(SUM(platform_fee),0)::DECIMAL(12,2) AS total_revenue,
      COALESCE(SUM(platform_fee) FILTER (WHERE created_at > NOW() - INTERVAL '1 day'),0)::DECIMAL(10,2) AS today_revenue,
      COALESCE(SUM(platform_fee) FILTER (WHERE created_at > NOW() - INTERVAL '7 days'),0)::DECIMAL(10,2) AS week_revenue
      FROM transactions WHERE status='settled'`),
  ]);

  return {
    users: users.rows[0],
    products: products.rows[0],
    orders: orders.rows[0],
    revenue: revenue.rows[0],
  };
}

// ── Fraud Detection ───────────────────────────────────────

async function getFraudSignals() {
  // High cancellation rate sellers (>30%)
  const highCancellations = await db.query(
    `SELECT u.id, u.name, u.email,
            COUNT(*)::INT AS total_orders,
            COUNT(*) FILTER (WHERE o.status='cancelled')::INT AS cancellations,
            ROUND(100.0 * COUNT(*) FILTER (WHERE o.status='cancelled') / COUNT(*), 1) AS cancel_rate
     FROM orders o JOIN users u ON u.id = o.seller_id
     GROUP BY u.id
     HAVING COUNT(*) >= 5 AND
            (100.0 * COUNT(*) FILTER (WHERE o.status='cancelled') / COUNT(*)) > 30
     ORDER BY cancel_rate DESC`
  );

  // Review velocity anomalies (>5 reviews in 1 day)
  const reviewVelocity = await db.query(
    `SELECT reviewer_id, u.name, u.email, COUNT(*)::INT AS reviews_today
     FROM reviews r JOIN users u ON u.id = r.reviewer_id
     WHERE r.created_at > NOW() - INTERVAL '1 day'
     GROUP BY reviewer_id, u.name, u.email
     HAVING COUNT(*) > 5
     ORDER BY reviews_today DESC`
  );

  // New accounts with large orders (account < 3 days, order > ₹5000)
  const suspiciousNewAccounts = await db.query(
    `SELECT u.id, u.name, u.email, u.created_at,
            COUNT(o.id)::INT AS order_count,
            SUM(o.total_amount)::DECIMAL(12,2) AS total_spent
     FROM users u JOIN orders o ON o.buyer_id = u.id
     WHERE u.created_at > NOW() - INTERVAL '3 days'
       AND o.total_amount > 5000
     GROUP BY u.id
     ORDER BY total_spent DESC LIMIT 20`
  );

  return {
    highCancellationSellers: highCancellations.rows,
    reviewVelocityAnomalies: reviewVelocity.rows,
    suspiciousNewAccounts: suspiciousNewAccounts.rows,
    generatedAt: new Date().toISOString(),
  };
}

async function listReviews({ page = 1, limit = 20 }) {
  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT r.*, u.name AS reviewer_name, p.name AS product_name, p.image_urls AS product_images
     FROM reviews r
     JOIN users u ON u.id = r.reviewer_id
     LEFT JOIN products p ON p.id = r.product_id
     ORDER BY r.created_at DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  const count = await db.query('SELECT COUNT(*)::INT AS total FROM reviews');
  return { data: res.rows, total: count.rows[0].total };
}

async function deleteReview(reviewId) {
  const res = await db.query('SELECT id, reviewee_id FROM reviews WHERE id = $1', [reviewId]);
  if (!res.rows[0]) throw new NotFoundError('Review not found');
  const { reviewee_id } = res.rows[0];

  await db.query('DELETE FROM reviews WHERE id = $1', [reviewId]);

  if (reviewee_id) {
    const { updateTrustScore } = require('../smart/trust.service');
    await updateTrustScore(reviewee_id);
  }
}

async function getReviewStats() {
  const totalStats = await db.query(
    `SELECT 
       COUNT(*)::INT AS count,
       COALESCE(AVG(rating), 0)::DECIMAL(3,2) AS avg_rating,
       COUNT(*) FILTER (WHERE sentiment_label = 'positive')::INT AS positive_count,
       COUNT(*) FILTER (WHERE sentiment_label = 'neutral')::INT AS neutral_count,
       COUNT(*) FILTER (WHERE sentiment_label = 'negative')::INT AS negative_count
     FROM reviews`
  );

  const highlyNegative = await db.query(
    `SELECT 
       p.id, p.name, p.price, p.image_urls,
       COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating,
       COUNT(r.id)::INT AS review_count,
       ROUND(100.0 * COUNT(r.id) FILTER (WHERE r.sentiment_label = 'negative') / COUNT(r.id), 1) AS negative_pct
     FROM products p
     JOIN reviews r ON r.product_id = p.id
     GROUP BY p.id
     HAVING COUNT(r.id) >= 2 AND (AVG(r.rating) <= 2.5 OR (100.0 * COUNT(r.id) FILTER (WHERE r.sentiment_label = 'negative') / COUNT(r.id)) >= 40)
     ORDER BY avg_rating ASC, negative_pct DESC`
  );

  const consistentlyPositive = await db.query(
    `SELECT 
       p.id, p.name, p.price, p.image_urls,
       COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating,
       COUNT(r.id)::INT AS review_count,
       ROUND(100.0 * COUNT(r.id) FILTER (WHERE r.sentiment_label = 'positive') / COUNT(r.id), 1) AS positive_pct
     FROM products p
     JOIN reviews r ON r.product_id = p.id
     GROUP BY p.id
     HAVING COUNT(r.id) >= 3 AND AVG(r.rating) >= 4.5
     ORDER BY avg_rating DESC, positive_pct DESC`
  );

  const recommendationScores = await db.query(
    `SELECT p.id, p.name, COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating, COUNT(r.id)::INT AS review_count
     FROM products p
     LEFT JOIN reviews r ON r.product_id = p.id
     WHERE p.is_active = TRUE AND p.is_approved = TRUE
     GROUP BY p.id
     LIMIT 10`
  );
  
  const { getProductRecommendationBreakdown } = require('../products/recommendation.service');
  const productsWithScores = [];
  for (const prod of recommendationScores.rows) {
    const scoreData = await getProductRecommendationBreakdown(prod.id);
    if (scoreData) {
      productsWithScores.push(scoreData);
    }
  }
  productsWithScores.sort((a, b) => b.recommendation_score - a.recommendation_score);

  const stats = totalStats.rows[0];
  const total = stats.count || 1;

  return {
    summary: {
      totalReviews: stats.count,
      averageRating: parseFloat(stats.avg_rating),
      sentimentSplit: {
        positive: Math.round((stats.positive_count / total) * 100),
        neutral: Math.round((stats.neutral_count / total) * 100),
        negative: Math.round((stats.negative_count / total) * 100),
      }
    },
    highlyNegativeProducts: highlyNegative.rows,
    consistentlyPositiveProducts: consistentlyPositive.rows,
    topRankedProducts: productsWithScores.slice(0, 5)
  };
}

module.exports = {
  listUsers, setUserBanStatus,
  listPendingProducts, moderateProduct,
  getRevenueAnalytics, getDashboardStats, getFraudSignals,
  listReviews, deleteReview, getReviewStats
};
