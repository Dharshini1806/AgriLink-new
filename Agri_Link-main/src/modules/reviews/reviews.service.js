const db = require('../../config/db');
const { updateTrustScore } = require('../smart/trust.service');
const { BadRequestError, NotFoundError, ForbiddenError } = require('../../middleware/errorHandler');

async function createReview(reviewerId, { productId, revieweeId, orderId, rating, comment }) {
  // Validate the order is delivered and reviewer is a party
  const orderRes = await db.query(
    'SELECT buyer_id, seller_id, status FROM orders WHERE id=$1', [orderId]
  );
  if (!orderRes.rows[0]) throw new NotFoundError('Order not found');
  const order = orderRes.rows[0];

  if (order.status !== 'delivered') throw new BadRequestError('Order must be delivered before reviewing');
  if (order.buyer_id !== reviewerId && order.seller_id !== reviewerId) {
    throw new ForbiddenError('Not a party to this order');
  }

  const res = await db.query(
    `INSERT INTO reviews (reviewer_id, product_id, reviewee_id, order_id, rating, comment)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [reviewerId, productId || null, revieweeId || null, orderId, rating, comment || null]
  );

  // Update trust score for reviewee
  if (revieweeId) await updateTrustScore(revieweeId);

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

module.exports = { createReview, getProductReviews };
