const express = require('express');
const Joi = require('joi');
const router = express.Router();
const reviewService = require('./reviews.service');
const verifyToken = require('../../middleware/auth');
const validate = require('../../middleware/validate');

const reviewSchema = Joi.object({
  orderId:    Joi.string().uuid().required(),
  rating:     Joi.number().integer().min(1).max(5).required(),
  comment:    Joi.string().max(1000).optional().allow(''),
  productId:  Joi.string().uuid().optional(),
  revieweeId: Joi.string().uuid().optional(),
}).or('productId', 'revieweeId');

router.post('/', verifyToken, validate(reviewSchema), async (req, res, next) => {
  try {
    const review = await reviewService.createReview(req.user.id, req.body);
    res.status(201).json(review);
  } catch (err) { next(err); }
});

router.get('/product/:id', verifyToken, async (req, res, next) => {
  try {
    const result = await reviewService.getProductReviews(req.params.id, req.query.page, req.query.limit);
    res.json(result);
  } catch (err) { next(err); }
});

module.exports = router;
