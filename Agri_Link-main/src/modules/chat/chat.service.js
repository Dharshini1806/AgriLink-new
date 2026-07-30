const db = require('../../config/db');
const { ForbiddenError, NotFoundError } = require('../../middleware/errorHandler');

async function saveMessage({ orderId, senderId, content }) {
  const res = await db.query(
    `INSERT INTO messages (order_id, sender_id, content)
     VALUES ($1,$2,$3)
     RETURNING id, order_id, sender_id, content, is_read, sent_at`,
    [orderId, senderId, content]
  );
  // Enrich with sender name
  const senderRes = await db.query('SELECT name, profile_img FROM users WHERE id=$1', [senderId]);
  return {
    ...res.rows[0],
    sender_name: senderRes.rows[0]?.name,
    sender_img:  senderRes.rows[0]?.profile_img,
  };
}

async function getChatHistory(orderId, userId, page = 1, limit = 50) {
  // Verify user is party to this order
  const orderRes = await db.query(
    'SELECT buyer_id, seller_id FROM orders WHERE id=$1', [orderId]
  );
  if (!orderRes.rows[0]) throw new NotFoundError('Order not found');
  const { buyer_id, seller_id } = orderRes.rows[0];
  if (userId !== buyer_id && userId !== seller_id) throw new ForbiddenError('Access denied');

  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT m.id, m.order_id, m.sender_id, m.content, m.is_read, m.sent_at,
            u.name AS sender_name, u.profile_img AS sender_img
     FROM messages m
     JOIN users u ON u.id = m.sender_id
     WHERE m.order_id=$1
     ORDER BY m.sent_at ASC
     LIMIT $2 OFFSET $3`,
    [orderId, limit, offset]
  );
  return res.rows;
}

async function markRead(orderId, readerId) {
  await db.query(
    `UPDATE messages SET is_read=TRUE
     WHERE order_id=$1 AND sender_id != $2 AND is_read=FALSE`,
    [orderId, readerId]
  );
}

async function getUnreadCount(userId) {
  const res = await db.query(
    `SELECT COUNT(*)::INT AS unread
     FROM messages m
     JOIN orders o ON o.id = m.order_id
     WHERE (o.buyer_id=$1 OR o.seller_id=$1)
       AND m.sender_id != $1
       AND m.is_read = FALSE`,
    [userId]
  );
  return res.rows[0].unread;
}

module.exports = { saveMessage, getChatHistory, markRead, getUnreadCount };
