const db = require('../../config/db');
const { haversineKm } = require('../../utils/geoDistance');
const { BadRequestError } = require('../../middleware/errorHandler');

async function compareProducts(productIds, buyerLat, buyerLng) {
  if (!productIds || productIds.length < 2) throw new BadRequestError('Provide at least 2 product IDs');
  if (productIds.length > 5) throw new BadRequestError('Maximum 5 products for comparison');

  const res = await db.query(
    `SELECT p.id, p.name, p.price, p.quality_grade, p.image_urls, p.delivery_radius_km,
            c.name AS category_name,
            u.id AS seller_id, u.name AS seller_name, u.trust_score,
            u.latitude AS seller_lat, u.longitude AS seller_lng,
            COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating,
            COUNT(r.id)::INT AS review_count
     FROM products p
     JOIN users u ON u.id = p.seller_id
     JOIN categories c ON c.id = p.category_id
     LEFT JOIN reviews r ON r.product_id = p.id
     WHERE p.id = ANY($1::uuid[]) AND p.is_active = TRUE
     GROUP BY p.id, c.id, u.id`,
    [productIds]
  );

  const products = res.rows.map(p => {
    const distKm = (buyerLat && buyerLng)
      ? +haversineKm(parseFloat(buyerLat), parseFloat(buyerLng), parseFloat(p.seller_lat), parseFloat(p.seller_lng)).toFixed(1)
      : null;
    const valueScore = +(parseFloat(p.trust_score) * parseFloat(p.avg_rating) / parseFloat(p.price) * 100).toFixed(1);
    return { ...p, distance_km: distKm, value_score: valueScore };
  });

  // Compute winners per attribute
  const winners = {
    price:       products.reduce((a, b) => parseFloat(a.price) < parseFloat(b.price) ? a : b).id,
    avg_rating:  products.reduce((a, b) => parseFloat(a.avg_rating) > parseFloat(b.avg_rating) ? a : b).id,
    trust_score: products.reduce((a, b) => parseFloat(a.trust_score) > parseFloat(b.trust_score) ? a : b).id,
    value_score: products.reduce((a, b) => a.value_score > b.value_score ? a : b).id,
  };
  if (products[0]?.distance_km !== null) {
    winners.distance = products.filter(p => p.distance_km !== null)
      .reduce((a, b) => a.distance_km < b.distance_km ? a : b).id;
  }

  return { products, winners };
}

module.exports = { compareProducts };
