const db = require('../../config/db');
const { haversineKm } = require('../../utils/geoDistance');
const { NotFoundError } = require('../../middleware/errorHandler');

async function getAllRecipes() {
  const res = await db.query('SELECT id, name, description, image_url FROM recipes ORDER BY name');
  return res.rows;
}

async function recipeToCart(recipeName, buyerLat, buyerLng) {
  // 1. Find recipe
  const recipeRes = await db.query(
    `SELECT r.id, r.name, ri.category_id, ri.typical_qty_g, c.name AS category_name
     FROM recipes r
     JOIN recipe_ingredients ri ON ri.recipe_id = r.id
     JOIN categories c ON c.id = ri.category_id
     WHERE LOWER(r.name) = LOWER($1)`,
    [recipeName]
  );
  if (!recipeRes.rows.length) throw new NotFoundError(`Recipe "${recipeName}" not found`);

  const recipeMeta = { id: recipeRes.rows[0].id, name: recipeRes.rows[0].name };

  // 2. For each ingredient category, find the best-matching product
  const cartItems = [];
  const missingIngredients = [];

  for (const ing of recipeRes.rows) {
    const productsRes = await db.query(
      `SELECT p.id, p.name, p.price, p.quantity, p.image_urls, p.quality_grade,
              u.id AS seller_id, u.name AS seller_name, u.trust_score,
              u.latitude, u.longitude,
              COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating
       FROM products p
       JOIN users u ON u.id = p.seller_id
       LEFT JOIN reviews r ON r.product_id = p.id
       WHERE p.category_id=$1 AND p.is_active=TRUE AND p.quantity > 0
       GROUP BY p.id, u.id`,
      [ing.category_id]
    );

    if (!productsRes.rows.length) {
      missingIngredients.push(ing.category_name);
      continue;
    }

    // Score: 60% trust + 40% proximity
    const scored = productsRes.rows.map(p => {
      const distKm = (buyerLat && buyerLng)
        ? haversineKm(parseFloat(buyerLat), parseFloat(buyerLng), parseFloat(p.latitude), parseFloat(p.longitude))
        : 0;
      const proximityScore = 1 / (1 + distKm);
      return {
        ...p,
        distance_km: +distKm.toFixed(1),
        score: 0.6 * parseFloat(p.trust_score) + 0.4 * proximityScore,
      };
    }).sort((a, b) => b.score - a.score);

    const best = scored[0];
    const requiredQty = Math.ceil(ing.typical_qty_g / 200); // 1 unit = ~200g

    cartItems.push({
      product: best,
      quantity: requiredQty,
      categoryName: ing.category_name,
      typicalQtyG: ing.typical_qty_g,
    });
  }

  const subtotal = cartItems.reduce(
    (sum, item) => sum + parseFloat(item.product.price) * item.quantity, 0
  );

  return {
    recipe: recipeMeta,
    cartItems,
    missingIngredients,
    estimatedSubtotal: +subtotal.toFixed(2),
    message: missingIngredients.length
      ? `Could not find: ${missingIngredients.join(', ')}. Added available items.`
      : 'All ingredients added to cart!',
  };
}

module.exports = { getAllRecipes, recipeToCart };
