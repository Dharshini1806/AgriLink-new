const productService = require('./products.service');
const recommendationService = require('./recommendation.service');
const reviewService = require('../reviews/reviews.service');

async function getFeed(req, res, next) {
  try {
    const products = await productService.getProductFeed(req.query);
    res.json({ data: products, count: products.length });
  } catch (err) { next(err); }
}

async function getOne(req, res, next) {
  try {
    const product = await productService.getProductById(req.params.id);
    res.json(product);
  } catch (err) { next(err); }
}

async function getMyProducts(req, res, next) {
  try {
    const products = await productService.getSellerProducts(
      req.user.id, req.query.page, req.query.limit
    );
    res.json({ data: products });
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const product = await productService.createProduct(req.user.id, req.body, req.files || []);
    res.status(201).json(product);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const product = await productService.updateProduct(
      req.params.id, req.user.id, req.body, req.files || []
    );
    res.json(product);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    await productService.softDeleteProduct(req.params.id, req.user.id);
    res.json({ message: 'Product deactivated' });
  } catch (err) { next(err); }
}

async function getCategories(req, res, next) {
  try {
    const categories = await productService.getCategories();
    res.json(categories);
  } catch (err) { next(err); }
}

async function toggleWishlist(req, res, next) {
  try {
    const result = await productService.toggleWishlist(req.user.id, req.params.id);
    res.json(result);
  } catch (err) { next(err); }
}

async function getWishlist(req, res, next) {
  try {
    const items = await productService.getWishlist(req.user.id);
    res.json({ data: items });
  } catch (err) { next(err); }
}

async function getTopSellers(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 5, 10);
    const sellers = await productService.getTopSellers(limit);
    res.json({ data: sellers });
  } catch (err) { next(err); }
}

async function getTopSellerDetails(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const sellers = await productService.getTopSellerDetails(limit);
    res.json({ data: sellers });
  } catch (err) { next(err); }
}

async function getRecommended(req, res, next) {
  try {
    const userId = req.user?.id;
    const products = await recommendationService.getRecommendedProducts(userId, req.query);
    res.json({ products });
  } catch (err) { next(err); }
}

async function getRecommendationScore(req, res, next) {
  try {
    const scoreBreakdown = await recommendationService.getProductRecommendationBreakdown(req.params.id);
    if (!scoreBreakdown) return res.status(404).json({ error: 'Product not found' });
    res.json(scoreBreakdown);
  } catch (err) { next(err); }
}

async function getReviewSummary(req, res, next) {
  try {
    const summary = await reviewService.getProductReviewSummary(req.params.id);
    res.json(summary);
  } catch (err) { next(err); }
}

module.exports = {
  getFeed, getOne, getMyProducts, create, update, remove,
  getCategories, toggleWishlist, getWishlist, getTopSellers,
  getTopSellerDetails, getRecommended, getRecommendationScore,
  getReviewSummary
};
