const express = require('express');
const Joi = require('joi');
const router = express.Router();
const controller = require('./products.controller');
const verifyToken = require('../../middleware/auth');
const requireRole = require('../../middleware/role');
const validate = require('../../middleware/validate');
const upload = require('../../middleware/upload');

const productSchema = Joi.object({
  name:               Joi.string().trim().min(2).max(150).required(),
  description:        Joi.string().max(2000).optional().allow(''),
  category_id:        Joi.string().uuid().required(),
  price:              Joi.number().positive().precision(2).required(),
  quantity:           Joi.number().integer().min(0).required(),
  quality_grade:      Joi.string().valid('A','B','C').optional(),
  delivery_area:      Joi.string().max(100).optional().allow(''),
  delivery_radius_km: Joi.number().min(1).max(500).optional(),
});

const updateSchema = productSchema.fork(
  ['name','category_id','price','quantity'],
  field => field.optional()
).append({ is_active: Joi.boolean().optional() });

// Public-ish (needs auth)
router.get('/',             verifyToken, controller.getFeed);
router.get('/categories',   verifyToken, controller.getCategories);
router.get('/wishlist',     verifyToken, requireRole('buyer'), controller.getWishlist);
router.get('/mine',         verifyToken, requireRole('seller'), controller.getMyProducts);
router.get('/:id',          verifyToken, controller.getOne);

// Seller only
router.post('/',
  verifyToken, requireRole('seller'),
  upload.array('images', 5),
  validate(productSchema),
  controller.create
);
router.put('/:id',
  verifyToken, requireRole('seller'),
  upload.array('images', 5),
  validate(updateSchema),
  controller.update
);
router.delete('/:id', verifyToken, requireRole('seller'), controller.remove);

// Wishlist
router.post('/:id/wishlist', verifyToken, requireRole('buyer'), controller.toggleWishlist);

module.exports = router;
