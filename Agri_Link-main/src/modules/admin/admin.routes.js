const express = require('express');
const router = express.Router();
const controller = require('./admin.controller');
const verifyToken = require('../../middleware/auth');
const requireRole = require('../../middleware/role');

// All admin routes require admin role
router.use(verifyToken, requireRole('admin'));

router.get('/dashboard',                    controller.getDashboard);
router.get('/users',                        controller.listUsers);
router.patch('/users/:id/ban',              controller.banUser);
router.patch('/users/:id/unban',            controller.unbanUser);
router.get('/products/pending',             controller.getPendingProducts);
router.patch('/products/:id/moderate',      controller.moderateProduct);
router.get('/analytics/revenue',            controller.getRevenue);
router.get('/fraud-signals',                controller.getFraudSignals);

module.exports = router;
