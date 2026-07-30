const express = require('express');
const Joi = require('joi');
const router = express.Router();
const controller = require('./smart.controller');
const verifyToken = require('../../middleware/auth');
const requireRole = require('../../middleware/role');
const validate = require('../../middleware/validate');

const recipeSchema = Joi.object({
  recipe_name: Joi.string().min(2).max(150).required(),
  latitude:    Joi.number().min(-90).max(90).optional(),
  longitude:   Joi.number().min(-180).max(180).optional(),
});

// Price suggestion — seller only
router.get('/price-suggestion', verifyToken, requireRole('seller'), controller.getPriceSuggestion);

// Product comparison — any authenticated user
router.get('/compare', verifyToken, controller.compareProducts);

// Recipes
router.get('/recipes', verifyToken, controller.getRecipes);
router.post('/recipe-to-cart', verifyToken, requireRole('buyer'), validate(recipeSchema), controller.recipeToCart);

module.exports = router;
