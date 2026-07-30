const db = require('../../config/db');
const { uploadBuffer } = require('../../config/cloudinary');
const { NotFoundError } = require('../../middleware/errorHandler');

async function getProfile(userId) {
  const res = await db.query(
    `SELECT id, name, email, role, phone, latitude, longitude, trust_score,
            farm_name, farm_desc, profile_img, created_at,
            (SELECT COUNT(*) FROM reviews WHERE reviewee_id=users.id)::INT AS review_count
     FROM users WHERE id=$1`,
    [userId]
  );
  if (!res.rows[0]) throw new NotFoundError('User not found');
  return res.rows[0];
}

async function updateProfile(userId, data, avatarFile) {
  let profileImg;
  if (avatarFile) {
    const { url } = await uploadBuffer(avatarFile.buffer, 'agrilink/avatars');
    profileImg = url;
  }

  const { name, phone, latitude, longitude, farm_name, farm_desc } = data;
  const res = await db.query(
    `UPDATE users SET
       name=COALESCE($1, name), phone=COALESCE($2, phone),
       latitude=COALESCE($3, latitude), longitude=COALESCE($4, longitude),
       farm_name=COALESCE($5, farm_name), farm_desc=COALESCE($6, farm_desc),
       profile_img=COALESCE($7, profile_img), updated_at=NOW()
     WHERE id=$8
     RETURNING id, name, email, role, phone, latitude, longitude, trust_score, farm_name, farm_desc, profile_img`,
    [name||null, phone||null, latitude||null, longitude||null, farm_name||null, farm_desc||null, profileImg||null, userId]
  );
  return res.rows[0];
}

async function getSellerAnalytics(sellerId) {
  const [earningsRes, ordersRes, productsRes] = await Promise.all([
    db.query(
      `SELECT
         COALESCE(SUM(net_seller_payout),0)::DECIMAL(12,2) AS total_earnings,
         COALESCE(SUM(net_seller_payout) FILTER (WHERE t.created_at > NOW() - INTERVAL '30 days'),0)::DECIMAL(10,2) AS month_earnings,
         COALESCE(SUM(net_seller_payout) FILTER (WHERE t.created_at > NOW() - INTERVAL '7 days'),0)::DECIMAL(10,2) AS week_earnings
       FROM transactions t JOIN orders o ON o.id=t.order_id
       WHERE o.seller_id=$1 AND t.status='settled'`,
      [sellerId]
    ),
    db.query(
      `SELECT
         COUNT(*)::INT AS total,
         COUNT(*) FILTER (WHERE status='pending')::INT AS pending,
         COUNT(*) FILTER (WHERE status='delivered')::INT AS delivered,
         COUNT(*) FILTER (WHERE status='cancelled')::INT AS cancelled
       FROM orders WHERE seller_id=$1`,
      [sellerId]
    ),
    db.query(
      `SELECT p.id, p.name, p.price, p.quantity, p.image_urls[1] AS thumbnail,
              COUNT(oi.id)::INT AS times_ordered,
              COALESCE(AVG(r.rating),0)::DECIMAL(3,2) AS avg_rating
       FROM products p
       LEFT JOIN order_items oi ON oi.product_id=p.id
       LEFT JOIN reviews r ON r.product_id=p.id
       WHERE p.seller_id=$1 AND p.is_active=TRUE
       GROUP BY p.id ORDER BY times_ordered DESC LIMIT 5`,
      [sellerId]
    ),
  ]);
  return {
    earnings: earningsRes.rows[0],
    orders:   ordersRes.rows[0],
    topProducts: productsRes.rows,
  };
}

module.exports = { getProfile, updateProfile, getSellerAnalytics };
