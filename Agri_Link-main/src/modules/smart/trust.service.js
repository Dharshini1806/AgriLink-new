const db = require('../../config/db');
const logger = require('../../utils/logger');

/**
 * Recalculate and update a user's trust score using exponential moving average
 * of their last 10 reviews. Requires minimum 3 reviews.
 */
async function updateTrustScore(userId) {
  try {
    const res = await db.query(
      `SELECT AVG(rating)::DECIMAL(3,2) AS avg_rating, COUNT(*)::INT AS count
       FROM (
         SELECT rating FROM reviews WHERE reviewee_id=$1
         ORDER BY created_at DESC LIMIT 10
       ) recent`,
      [userId]
    );

    const { avg_rating, count } = res.rows[0];
    if (count < 3) return; // Need min 3 reviews to establish score

    const newAvg = parseFloat(avg_rating);
    // EMA: 80% weight on existing score, 20% weight on new data
    await db.query(
      `UPDATE users
       SET trust_score = LEAST(5.0, ROUND((0.8 * trust_score + 0.2 * $1)::NUMERIC, 2)),
           updated_at = NOW()
       WHERE id = $2`,
      [newAvg, userId]
    );
    logger.info(`Trust score updated for user ${userId}: new_avg=${newAvg}, count=${count}`);
  } catch (err) {
    logger.error('updateTrustScore error:', err.message);
  }
}

module.exports = { updateTrustScore };
