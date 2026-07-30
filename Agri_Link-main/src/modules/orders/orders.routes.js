const express = require('express');
const Joi = require('joi');
const router = express.Router();
const controller = require('./orders.controller');
const verifyToken = require('../../middleware/auth');
const requireRole = require('../../middleware/role');
const validate = require('../../middleware/validate');

const orderSchema = Joi.object({
  items: Joi.array().items(Joi.object({
    productId: Joi.string().uuid().required(),
    quantity:  Joi.number().integer().min(1).required(),
  })).min(1).required(),
  deliveryAddress: Joi.string().min(5).max(500).required(),
  notes: Joi.string().max(500).optional().allow(''),
});

const statusSchema = Joi.object({
  status: Joi.string()
    .valid('confirmed','packed','out_for_delivery','delivered','cancelled')
    .required(),
});

router.post('/', verifyToken, requireRole('buyer'), validate(orderSchema), controller.placeOrder);
router.get('/buyer/mine', verifyToken, requireRole('buyer'), controller.getBuyerOrders);
router.get('/seller/mine', verifyToken, requireRole('seller'), controller.getSellerOrders);
router.get('/:id', verifyToken, controller.getOrder);
router.patch('/:id/status', verifyToken, requireRole('seller'), validate(statusSchema), controller.updateStatus);
router.patch('/:id/cancel', verifyToken, controller.cancelOrder);

module.exports = router;
