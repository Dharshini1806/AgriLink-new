const express = require('express');
const Joi = require('joi');
const router = express.Router();
const controller = require('./users.controller');
const verifyToken = require('../../middleware/auth');
const requireRole = require('../../middleware/role');
const validate   = require('../../middleware/validate');
const upload     = require('../../middleware/upload');

const profileSchema = Joi.object({
  name:      Joi.string().trim().min(2).max(100).optional(),
  phone:     Joi.string().pattern(/^\+?[\d\s\-]{7,20}$/).optional().allow(''),
  latitude:  Joi.number().min(-90).max(90).optional(),
  longitude: Joi.number().min(-180).max(180).optional(),
  farm_name: Joi.string().max(150).optional().allow(''),
  farm_desc: Joi.string().max(1000).optional().allow(''),
});

router.get('/profile',              verifyToken, controller.getProfile);
router.put('/profile',              verifyToken, upload.single('avatar'), validate(profileSchema), controller.updateProfile);
router.get('/analytics/seller',     verifyToken, requireRole('seller'), controller.getSellerAnalytics);
router.get('/:id/profile',          verifyToken, controller.getPublicProfile);

module.exports = router;
