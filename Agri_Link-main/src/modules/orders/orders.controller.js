const orderService = require('./orders.service');

async function placeOrder(req, res, next) {
  try {
    const { items, deliveryAddress, notes } = req.body;
    const orderIds = await orderService.createOrder(req.user.id, items, deliveryAddress, notes);
    res.status(201).json({ message: 'Order placed successfully', orderIds });
  } catch (err) { next(err); }
}

async function getBuyerOrders(req, res, next) {
  try {
    const orders = await orderService.getBuyerOrders(req.user.id, req.query.page, req.query.limit);
    res.json({ data: orders });
  } catch (err) { next(err); }
}

async function getSellerOrders(req, res, next) {
  try {
    const orders = await orderService.getSellerOrders(
      req.user.id, req.query.page, req.query.limit, req.query.status
    );
    res.json({ data: orders });
  } catch (err) { next(err); }
}

async function getOrder(req, res, next) {
  try {
    const order = await orderService.getOrderById(req.params.id, req.user.id);
    res.json(order);
  } catch (err) { next(err); }
}

async function updateStatus(req, res, next) {
  try {
    const result = await orderService.updateOrderStatus(req.params.id, req.user.id, req.body.status);
    res.json(result);
  } catch (err) { next(err); }
}

async function cancelOrder(req, res, next) {
  try {
    const result = await orderService.cancelOrder(req.params.id, req.user.id);
    res.json(result);
  } catch (err) { next(err); }
}

module.exports = { placeOrder, getBuyerOrders, getSellerOrders, getOrder, updateStatus, cancelOrder };
