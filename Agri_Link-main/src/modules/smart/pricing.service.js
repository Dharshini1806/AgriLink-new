// ============================================================
// src/modules/smart/pricing.service.js
// Demand-based price suggestion engine
// ============================================================
const db = require('../../config/db');
const { NotFoundError } = require('../../middleware/errorHandler');

async function getPriceSuggestion(categoryId, sellerId) {
  // Validate category exists
  const catRes = await db.query('SELECT name FROM categories WHERE id=$1', [categoryId]);
  if (!catRes.rows[0]) throw new NotFoundError('Category not found');

  // Market average from active sellers
  const avgRes = await db.query(
    `SELECT AVG(price)::DECIMAL(10,2) AS avg_price,
            COUNT(*)::INT AS listing_count
     FROM products
     WHERE category_id=$1 AND is_active=TRUE`,
    [categoryId]
  );
  const avgPrice = parseFloat(avgRes.rows[0].avg_price) || 0;
  const listingCount = avgRes.rows[0].listing_count;

  // Demand score: orders last 7 days vs prior 7 days
  const demandRes = await db.query(
    `SELECT
       COUNT(*) FILTER (WHERE o.created_at > NOW() - INTERVAL '7 days')::INT AS recent_orders,
       COUNT(*) FILTER (
         WHERE o.created_at BETWEEN NOW() - INTERVAL '14 days' AND NOW() - INTERVAL '7 days'
       )::INT AS prior_orders
     FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     JOIN products p ON p.id = oi.product_id
     WHERE p.category_id=$1 AND o.status='delivered'`,
    [categoryId]
  );
  const recent = demandRes.rows[0].recent_orders || 1;
  const prior  = demandRes.rows[0].prior_orders  || 1;
  const demandScore = recent / prior;

  // Price adjustment
  let multiplier = 1.0;
  let trend = 'stable';
  if (demandScore > 1.5) { multiplier = 1.10; trend = 'high'; }
  else if (demandScore > 1.2) { multiplier = 1.05; trend = 'rising'; }
  else if (demandScore < 0.8) { multiplier = 0.95; trend = 'falling'; }

  const suggestedPrice = avgPrice > 0
    ? +(avgPrice * multiplier).toFixed(2)
    : null;

  return {
    categoryName:    catRes.rows[0].name,
    suggestedPrice,
    categoryAvgPrice: avgPrice,
    demandScore:     +demandScore.toFixed(2),
    trend,
    listingCount,
    priceRange: avgPrice > 0
      ? { min: +(avgPrice * 0.85).toFixed(2), max: +(avgPrice * 1.15).toFixed(2) }
      : null,
    note: avgPrice === 0
      ? 'Not enough market data yet. Set your own price.'
      : `Based on ${listingCount} active listings. Demand is ${trend}.`,
  };
}

module.exports = { getPriceSuggestion };
