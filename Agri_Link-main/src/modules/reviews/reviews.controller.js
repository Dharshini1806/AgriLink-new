const reviewService = require('./reviews.service');

async function createReview(req, res, next) {
  try {
    const review = await reviewService.createReview(req.user.id, req.body);
    res.status(201).json(review);
  } catch (err) { next(err); }
}

async function getProductReviews(req, res, next) {
  try {
    const result = await reviewService.getProductReviews(
      req.params.id,
      req.query.page,
      req.query.limit
    );
    res.json(result);
  } catch (err) { next(err); }
}

module.exports = { createReview, getProductReviews };
