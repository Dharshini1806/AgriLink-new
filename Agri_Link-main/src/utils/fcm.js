const logger = require('./logger');
const db = require('../config/db');

let admin;

function getAdmin() {
  if (!admin) {
    try {
      admin = require('firebase-admin');
      const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
      if (serviceAccountPath && !admin.apps.length) {
        const serviceAccount = require(require('path').resolve(serviceAccountPath));
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        logger.info('Firebase Admin SDK initialized');
      }
    } catch (err) {
      logger.warn('Firebase Admin SDK not initialized — FCM disabled:', err.message);
      return null;
    }
  }
  return admin;
}

/**
 * Send FCM push notification to a user
 * @param {string} userId
 * @param {string} title
 * @param {string} body
 * @param {object} data   Extra key-value data
 */
async function sendToUser(userId, title, body, data = {}) {
  const firebaseAdmin = getAdmin();
  if (!firebaseAdmin) return;
  try {
    const res = await db.query('SELECT fcm_token FROM users WHERE id=$1', [userId]);
    const token = res.rows[0]?.fcm_token;
    if (!token) return;

    await firebaseAdmin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
    });
  } catch (err) {
    logger.warn(`FCM send failed for user ${userId}:`, err.message);
  }
}

/**
 * Notify order status change to both buyer and seller
 */
async function notifyOrderStatus(orderId, status, buyerId, sellerId) {
  const statusMessages = {
    confirmed:        { title: '✅ Order Confirmed', body: 'Your order has been confirmed by the seller.' },
    packed:           { title: '📦 Order Packed',    body: 'Your order is packed and ready to ship.' },
    out_for_delivery: { title: '🚚 Out for Delivery', body: 'Your order is on the way!' },
    delivered:        { title: '🎉 Order Delivered',  body: 'Your order has been delivered. Please rate your experience.' },
    cancelled:        { title: '❌ Order Cancelled',  body: 'Your order has been cancelled.' },
  };
  const msg = statusMessages[status] || { title: 'Order Update', body: `Status: ${status}` };
  const data = { orderId, status, type: 'ORDER_STATUS' };
  await Promise.allSettled([
    sendToUser(buyerId,  msg.title, msg.body, data),
    sendToUser(sellerId, `Order ${status}`, `Buyer notified. Status: ${status}`, data),
  ]);
}

/**
 * Notify new chat message to the other party
 */
async function notifyNewMessage(orderId, senderId, content) {
  try {
    const res = await db.query(
      'SELECT buyer_id, seller_id FROM orders WHERE id=$1', [orderId]
    );
    if (!res.rows[0]) return;
    const { buyer_id, seller_id } = res.rows[0];
    const recipientId = senderId === buyer_id ? seller_id : buyer_id;
    await sendToUser(recipientId, '💬 New Message', content.substring(0, 80), {
      orderId, type: 'CHAT_MESSAGE',
    });
  } catch (err) {
    logger.warn('notifyNewMessage error:', err.message);
  }
}

module.exports = { sendToUser, notifyOrderStatus, notifyNewMessage };
