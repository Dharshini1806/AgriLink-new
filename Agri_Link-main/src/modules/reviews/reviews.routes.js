const express = require('express');
const Joi = require('joi');
const router = express.Router();
const reviewService = require('./reviews.service');
const verifyToken = require('../../middleware/auth');
const requireRole = require('../../middleware/role');
const validate = require('../../middleware/validate');

const reviewSchema = Joi.object({
  orderId:      Joi.string().uuid().required(),
  rating:       Joi.number().integer().min(1).max(5).required(),
  comment:      Joi.string().max(1000).optional().allow(''),
  productId:    Joi.string().uuid().optional(),
  revieweeId:   Joi.string().uuid().optional(),
  feedbackTags: Joi.array().items(Joi.string()).optional(),
}).or('productId', 'revieweeId');

// Create review (Buyers only)
router.post('/', verifyToken, requireRole('buyer'), validate(reviewSchema), async (req, res, next) => {
  try {
    const review = await reviewService.createReview(req.user.id, req.body);
    res.status(201).json(review);
  } catch (err) { next(err); }
});

// Check eligibility to review product
router.get('/eligibility/:productId', verifyToken, async (req, res, next) => {
  try {
    const result = await reviewService.getReviewEligibility(req.user.id, req.params.productId);
    res.json(result);
  } catch (err) { next(err); }
});

// Get reviews written by a user
router.get('/user/:userId', verifyToken, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await reviewService.getUserReviews(req.params.userId, page, limit);
    res.json(result);
  } catch (err) { next(err); }
});

// Get reviews for a product
router.get('/product/:id', verifyToken, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await reviewService.getProductReviews(req.params.id, page, limit);
    res.json(result);
  } catch (err) { next(err); }
});

// Re-analyze a single review's sentiment
router.post('/:reviewId/analyze', verifyToken, async (req, res, next) => {
  try {
    const result = await reviewService.reanalyzeReviewSentiment(req.params.reviewId);
    res.json({ message: 'Sentiment analysis updated successfully', review: result });
  } catch (err) { next(err); }
});

// Re-analyze ALL reviews for a specific product (fixes existing reviews with NULL sentiment)
router.post('/product/:productId/reanalyze', verifyToken, async (req, res, next) => {
  try {
    const result = await reviewService.bulkReanalyzeProductSentiment(req.params.productId);
    res.json({ message: `Sentiment re-analyzed for ${result.updated} reviews`, ...result });
  } catch (err) { next(err); }
});

// Admin: Re-analyze all reviews globally that are missing sentiment labels
router.post('/admin/reanalyze-all', verifyToken, requireRole('admin'), async (req, res, next) => {
  try {
    const result = await reviewService.bulkReanalyzeAllSentiment();
    res.json({ message: `Global sentiment re-analysis complete: ${result.updated} reviews updated`, ...result });
  } catch (err) { next(err); }
});

module.exports = router;
