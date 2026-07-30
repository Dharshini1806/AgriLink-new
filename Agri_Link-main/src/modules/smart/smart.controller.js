const pricingService    = require('./pricing.service');
const comparisonService = require('./comparison.service');
const recipeService     = require('./recipe.service');

async function getPriceSuggestion(req, res, next) {
  try {
    const { categoryId } = req.query;
    if (!categoryId) return res.status(422).json({ error: 'categoryId is required' });
    const result = await pricingService.getPriceSuggestion(categoryId, req.user.id);
    res.json(result);
  } catch (err) { next(err); }
}

async function compareProducts(req, res, next) {
  try {
    const ids = (req.query.ids || '').split(',').map(s => s.trim()).filter(Boolean);
    const { lat, lng } = req.query;
    const result = await comparisonService.compareProducts(ids, lat, lng);
    res.json(result);
  } catch (err) { next(err); }
}

async function getRecipes(req, res, next) {
  try {
    const recipes = await recipeService.getAllRecipes();
    res.json(recipes);
  } catch (err) { next(err); }
}

async function recipeToCart(req, res, next) {
  try {
    const { recipe_name, latitude, longitude } = req.body;
    const result = await recipeService.recipeToCart(recipe_name, latitude, longitude);
    res.json(result);
  } catch (err) { next(err); }
}

module.exports = { getPriceSuggestion, compareProducts, getRecipes, recipeToCart };
