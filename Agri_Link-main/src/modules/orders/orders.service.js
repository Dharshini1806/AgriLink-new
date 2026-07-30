const db = require('../../config/db');
const commission = require('../../utils/commission');
const fcm = require('../../utils/fcm');
const { NotFoundError, ForbiddenError, BadRequestError } = require('../../middleware/errorHandler');
const { haversineKm } = require('../../utils/geoDistance');

const VALID_STATUS_TRANSITIONS = {
  pending:          ['confirmed', 'cancelled'],
  confirmed:        ['packed', 'cancelled'],
  packed:           ['out_for_delivery'],
  out_for_delivery: ['delivered'],
  delivered:        [],
  cancelled:        [],
};

/**
 * Place order — splits cart by seller, creates separate orders per seller atomically
 * @param {string} buyerId
 * @param {{ productId, quantity }[]} items
 * @param {string} deliveryAddress
 * @param {string} [notes]
 */
async function createOrder(buyerId, items, deliveryAddress, notes) {
  if (!items?.length) throw new BadRequestError('Cart is empty');

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    // Fetch all products and validate
    const productIds = items.map(i => i.productId);
    const prodRes = await client.query(
      `SELECT p.id, p.seller_id, p.price, p.quantity, p.name, p.is_active,
              u.name AS seller_name, u.fcm_token AS seller_fcm,
              u.latitude AS seller_lat, u.longitude AS seller_lng
       FROM products p JOIN users u ON u.id = p.seller_id
       WHERE p.id = ANY($1::uuid[])`,
      [productIds]
    );
    const productMap = Object.fromEntries(prodRes.rows.map(p => [p.id, p]));

    // Fetch buyer details
    const buyerRes = await client.query('SELECT latitude, longitude FROM users WHERE id=$1', [buyerId]);
    const buyer = buyerRes.rows[0];

    // Validate each item
    for (const item of items) {
      const product = productMap[item.productId];
      if (!product) throw new NotFoundError(`Product ${item.productId} not found`);
      if (!product.is_active) throw new BadRequestError(`Product "${product.name}" is no longer available`);
      if (product.quantity < item.quantity) {
        throw new BadRequestError(`Insufficient stock for "${product.name}". Available: ${product.quantity}`);
      }
    }

    // Group items by seller
    const bySeller = {};
    for (const item of items) {
      const product = productMap[item.productId];
      if (!bySeller[product.seller_id]) bySeller[product.seller_id] = [];
      bySeller[product.seller_id].push({ ...item, product });
    }

    const createdOrderIds = [];

    for (const [sellerId, sellerItems] of Object.entries(bySeller)) {
      const subtotal = sellerItems.reduce(
        (sum, i) => sum + parseFloat(i.product.price) * i.quantity, 0
      );
      const { buyerFee, sellerFee, platformFee, netPayout, buyerTotal } = commission.calculate(subtotal);

      // Calculate delivery fee
      const firstItem = sellerItems[0].product;
      const dist = (buyer && buyer.latitude && buyer.longitude && firstItem.seller_lat && firstItem.seller_lng)
        ? haversineKm(parseFloat(buyer.latitude), parseFloat(buyer.longitude), parseFloat(firstItem.seller_lat), parseFloat(firstItem.seller_lng))
        : 0;
      const deliveryFee = +(dist * 2).toFixed(2);
      const finalBuyerTotal = +(buyerTotal + deliveryFee).toFixed(2);
      const finalNetPayout = +(netPayout + deliveryFee).toFixed(2);

      // Create order
      const orderRes = await client.query(
        `INSERT INTO orders (buyer_id, seller_id, total_amount, buyer_commission, seller_commission, delivery_fee, delivery_address, notes)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
        [buyerId, sellerId, finalBuyerTotal, buyerFee, sellerFee, deliveryFee, deliveryAddress, notes || null]
      );
      const orderId = orderRes.rows[0].id;

      // Insert order items + decrement product quantity
      for (const item of sellerItems) {
        await client.query(
          `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
           VALUES ($1,$2,$3,$4)`,
          [orderId, item.productId, item.quantity, item.product.price]
        );
        await client.query(
          'UPDATE products SET quantity = quantity - $1 WHERE id=$2',
          [item.quantity, item.productId]
        );
      }

      // Create transaction record
      await client.query(
        `INSERT INTO transactions (order_id, gross_amount, platform_fee, net_seller_payout)
         VALUES ($1,$2,$3,$4)`,
        [orderId, finalBuyerTotal, platformFee, finalNetPayout]
      );

      createdOrderIds.push({ orderId, sellerId, sellerFcm: sellerItems[0].product.seller_fcm });
    }

    await client.query('COMMIT');

    // Send FCM notifications (outside transaction)
    for (const { orderId, sellerId } of createdOrderIds) {
      await fcm.notifyOrderStatus(orderId, 'pending', buyerId, sellerId);
    }

    return createdOrderIds.map(o => o.orderId);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function getBuyerOrders(buyerId, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT o.*, u.name AS seller_name, u.phone AS seller_phone,
            json_agg(json_build_object(
              'id', oi.id, 'product_id', oi.product_id, 'name', p.name,
              'quantity', oi.quantity, 'unit_price', oi.unit_price,
              'image_url', p.image_urls[1]
            )) AS items
     FROM orders o
     JOIN users u ON u.id = o.seller_id
     JOIN order_items oi ON oi.order_id = o.id
     JOIN products p ON p.id = oi.product_id
     WHERE o.buyer_id = $1
     GROUP BY o.id, u.id
     ORDER BY o.created_at DESC
     LIMIT $2 OFFSET $3`,
    [buyerId, limit, offset]
  );
  return res.rows;
}

async function getSellerOrders(sellerId, page = 1, limit = 20, status) {
  const offset = (page - 1) * limit;
  const params = [sellerId, limit, offset];
  let statusClause = '';
  if (status) {
    params.push(status);
    statusClause = `AND o.status = $${params.length}`;
  }
  const res = await db.query(
    `SELECT o.*, u.name AS buyer_name, u.phone AS buyer_phone,
            json_agg(json_build_object(
              'id', oi.id, 'product_id', oi.product_id, 'name', p.name,
              'quantity', oi.quantity, 'unit_price', oi.unit_price,
              'image_url', p.image_urls[1]
            )) AS items
     FROM orders o
     JOIN users u ON u.id = o.buyer_id
     JOIN order_items oi ON oi.order_id = o.id
     JOIN products p ON p.id = oi.product_id
     WHERE o.seller_id = $1 ${statusClause}
     GROUP BY o.id, u.id
     ORDER BY o.created_at DESC
     LIMIT $2 OFFSET $3`,
    params
  );
  return res.rows;
}

async function getOrderById(orderId, userId) {
  const res = await db.query(
    `SELECT o.*,
            buyer.name AS buyer_name, buyer.phone AS buyer_phone,
            seller.name AS seller_name, seller.phone AS seller_phone,
            t.gross_amount, t.platform_fee, t.net_seller_payout, t.status AS payment_status,
            json_agg(json_build_object(
              'id', oi.id, 'product_id', oi.product_id, 'name', p.name,
              'quantity', oi.quantity, 'unit_price', oi.unit_price,
              'image_urls', p.image_urls
            )) AS items
     FROM orders o
     JOIN users buyer ON buyer.id = o.buyer_id
     JOIN users seller ON seller.id = o.seller_id
     LEFT JOIN transactions t ON t.order_id = o.id
     JOIN order_items oi ON oi.order_id = o.id
     JOIN products p ON p.id = oi.product_id
     WHERE o.id = $1
     GROUP BY o.id, buyer.id, seller.id, t.id`,
    [orderId]
  );
  if (!res.rows[0]) throw new NotFoundError('Order not found');
  const order = res.rows[0];

  // Only buyer or seller of this order can view it
  if (order.buyer_id !== userId && order.seller_id !== userId) {
    throw new ForbiddenError('Access denied');
  }
  return order;
}

async function updateOrderStatus(orderId, sellerId, newStatus) {
  const res = await db.query(
    'SELECT buyer_id, seller_id, status FROM orders WHERE id=$1', [orderId]
  );
  if (!res.rows[0]) throw new NotFoundError('Order not found');
  const order = res.rows[0];

  if (order.seller_id !== sellerId) throw new ForbiddenError('Not your order');

  const allowed = VALID_STATUS_TRANSITIONS[order.status] || [];
  if (!allowed.includes(newStatus)) {
    throw new BadRequestError(
      `Cannot transition from "${order.status}" to "${newStatus}". Allowed: ${allowed.join(', ')}`
    );
  }

  await db.query(
    'UPDATE orders SET status=$1, updated_at=NOW() WHERE id=$2',
    [newStatus, orderId]
  );

  // Settle transaction on delivery
  if (newStatus === 'delivered') {
    await db.query(
      `UPDATE transactions SET status='settled', settled_at=NOW() WHERE order_id=$1`,
      [orderId]
    );
    // Recalculate seller trust score
    const { updateTrustScore } = require('../smart/trust.service');
    await updateTrustScore(sellerId);
  }

  // FCM notification
  await fcm.notifyOrderStatus(orderId, newStatus, order.buyer_id, sellerId);

  return { orderId, newStatus };
}

async function cancelOrder(orderId, userId) {
  const res = await db.query(
    'SELECT buyer_id, seller_id, status FROM orders WHERE id=$1', [orderId]
  );
  if (!res.rows[0]) throw new NotFoundError('Order not found');
  const order = res.rows[0];

  if (order.buyer_id !== userId && order.seller_id !== userId) {
    throw new ForbiddenError('Not your order');
  }
  if (order.status !== 'pending' && order.status !== 'confirmed') {
    throw new BadRequestError('Only pending or confirmed orders can be cancelled');
  }

  await db.query(
    'UPDATE orders SET status=$1, updated_at=NOW() WHERE id=$2',
    ['cancelled', orderId]
  );

  // Restore product quantities
  const items = await db.query('SELECT product_id, quantity FROM order_items WHERE order_id=$1', [orderId]);
  for (const item of items.rows) {
    await db.query('UPDATE products SET quantity = quantity + $1 WHERE id=$2', [item.quantity, item.product_id]);
  }

  await fcm.notifyOrderStatus(orderId, 'cancelled', order.buyer_id, order.seller_id);
  return { message: 'Order cancelled' };
}

module.exports = { createOrder, getBuyerOrders, getSellerOrders, getOrderById, updateOrderStatus, cancelOrder };
