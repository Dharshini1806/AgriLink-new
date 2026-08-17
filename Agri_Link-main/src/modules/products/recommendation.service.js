const db = require('../../config/db');

/**
 * Calculates review-based recommendation scores and lists products accordingly
 */
async function getRecommendedProducts(userId, filters) {
  const { lat, lng, radius = 50, category, q, grade, minPrice, maxPrice, page = 1, limit = 20 } = filters;
  const offset = (page - 1) * limit;
  const params = [];
  const conditions = ['p.is_active = TRUE', 'p.is_approved = TRUE', 'p.quantity > 0'];

  // 1. Fetch user's purchased categories for personalization boost
  let purchasedCategoryIds = [];
  if (userId) {
    const catRes = await db.query(
      `SELECT DISTINCT p.category_id 
       FROM order_items oi 
       JOIN orders o ON o.id = oi.order_id 
       JOIN products p ON p.id = oi.product_id 
       WHERE o.buyer_id = $1 AND o.status = 'delivered'`,
      [userId]
    );
    purchasedCategoryIds = catRes.rows.map(r => r.category_id);
  }

  // Geo filter using Haversine in SQL
  if (lat && lng) {
    params.push(parseFloat(lat), parseFloat(lng));
    conditions.push(`(
      u.latitude IS NULL OR u.longitude IS NULL
      OR (
        6371 * 2 * ASIN(SQRT(
          POWER(SIN((RADIANS(u.latitude) - RADIANS($${params.length - 1})) / 2), 2) +
          COS(RADIANS($${params.length - 1})) * COS(RADIANS(u.latitude)) *
          POWER(SIN((RADIANS(u.longitude) - RADIANS($${params.length})) / 2), 2)
        ))
      ) <= p.delivery_radius_km
    )`);
  }

  if (category) {
    params.push(category);
    conditions.push(`c.name ILIKE $${params.length}`);
  }

  if (q) {
    params.push(q);
    conditions.push(`(p.search_vector @@ plainto_tsquery('english', $${params.length})
      OR p.name ILIKE '%' || $${params.length} || '%')`);
  }

  if (grade) {
    params.push(grade.toUpperCase());
    conditions.push(`p.quality_grade = $${params.length}`);
  }

  if (minPrice) {
    params.push(parseFloat(minPrice));
    conditions.push(`p.price >= $${params.length}`);
  }

  if (maxPrice) {
    params.push(parseFloat(maxPrice));
    conditions.push(`p.price <= $${params.length}`);
  }

  const whereClause = conditions.join(' AND ');

  // Distance expression (reused for ORDER BY)
  const distanceExpr = (lat && lng)
    ? `6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(u.latitude) - RADIANS(${parseFloat(lat)})) / 2), 2) +
        COS(RADIANS(${parseFloat(lat)})) * COS(RADIANS(u.latitude)) *
        POWER(SIN((RADIANS(u.longitude) - RADIANS(${parseFloat(lng)})) / 2), 2)
      ))`
    : '0';

  // Build the query
  let categoryBoostExpr = '1.0';
  if (purchasedCategoryIds.length > 0) {
    params.push(purchasedCategoryIds);
    categoryBoostExpr = `CASE WHEN p.category_id = ANY($${params.length}::uuid[]) THEN 1.15 ELSE 1.0 END`;
  }

  params.push(limit, offset);

  const sql = `
    WITH review_stats AS (
      SELECT
        product_id,
        COUNT(id)::INT AS count,
        AVG(rating)::DECIMAL(3,2) AS avg_rating,
        COUNT(id) FILTER (WHERE sentiment_label = 'positive')::INT AS positive_count,
        COUNT(id) FILTER (WHERE sentiment_label = 'neutral')::INT AS neutral_count,
        COUNT(id) FILTER (WHERE sentiment_label = 'negative')::INT AS negative_count,
        MAX(created_at) AS latest_review_at,
        COALESCE(VAR_SAMP(rating), 0.0)::DECIMAL(5,2) AS rating_variance
      FROM reviews
      WHERE product_id IS NOT NULL
      GROUP BY product_id
    ),
    delivered_qty AS (
      SELECT
        oi.product_id,
        SUM(oi.quantity)::INT AS qty_sold
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE o.status = 'delivered'
      GROUP BY oi.product_id
    )
    SELECT
      p.*,
      c.name AS category_name,
      c.icon_url AS category_icon,
      u.name AS seller_name,
      u.trust_score AS seller_trust,
      u.latitude AS seller_lat,
      u.longitude AS seller_lng,
      ROUND((${distanceExpr})::NUMERIC, 1) AS distance_km,
      COALESCE(dq.qty_sold, 0)::INT AS qty_sold,
      COALESCE(rs.count, 0)::INT AS review_count,
      COALESCE(rs.avg_rating, 0)::DECIMAL(3,2) AS avg_rating,
      -- Calculations
      ROUND((((5 * 4.0) + (COALESCE(rs.count, 0) * COALESCE(rs.avg_rating, 4.0))) / (5 + COALESCE(rs.count, 0)) * 20)::NUMERIC, 2) AS rating_score,
      CASE WHEN COALESCE(rs.count, 0) > 0 THEN ROUND((COALESCE(rs.positive_count, 0) * 1.0 + COALESCE(rs.neutral_count, 0) * 0.5) / COALESCE(rs.count, 1) * 100, 2) ELSE 70.0 END AS sentiment_score,
      CASE WHEN rs.latest_review_at IS NOT NULL THEN ROUND((100.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - rs.latest_review_at)) / 86400.0) / 30.0))::NUMERIC, 2) ELSE 50.0 END AS recency_score,
      CASE WHEN COALESCE(rs.count, 0) <= 1 THEN 100.0 ELSE ROUND(GREATEST(0.0, 100.0 * (1.0 - COALESCE(rs.rating_variance, 0.0) / 4.0))::NUMERIC, 2) END AS consistency_score,
      ROUND((1.0 - EXP(-COALESCE(rs.count, 0)::DECIMAL / 10.0))::NUMERIC, 4) AS volume_confidence,
      -- Final Scores
      ROUND((
        (
          0.40 * ROUND((((5 * 4.0) + (COALESCE(rs.count, 0) * COALESCE(rs.avg_rating, 4.0))) / (5 + COALESCE(rs.count, 0)) * 20)::NUMERIC, 2)
          + 0.30 * CASE WHEN COALESCE(rs.count, 0) > 0 THEN ROUND((COALESCE(rs.positive_count, 0) * 1.0 + COALESCE(rs.neutral_count, 0) * 0.5) / COALESCE(rs.count, 1) * 100, 2) ELSE 70.0 END
          + 0.15 * CASE WHEN rs.latest_review_at IS NOT NULL THEN ROUND((100.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - rs.latest_review_at)) / 86400.0) / 30.0))::NUMERIC, 2) ELSE 50.0 END
          + 0.15 * CASE WHEN COALESCE(rs.count, 0) <= 1 THEN 100.0 ELSE ROUND(GREATEST(0.0, 100.0 * (1.0 - COALESCE(rs.rating_variance, 0.0) / 4.0))::NUMERIC, 2) END
        ) * ROUND((1.0 - EXP(-COALESCE(rs.count, 0)::DECIMAL / 10.0))::NUMERIC, 4)
        * ${categoryBoostExpr}
      )::NUMERIC, 2) AS recommendation_score
    FROM products p
    JOIN users u ON u.id = p.seller_id
    JOIN categories c ON c.id = p.category_id
    LEFT JOIN review_stats rs ON rs.product_id = p.id
    LEFT JOIN delivered_qty dq ON dq.product_id = p.id
    WHERE ${whereClause}
    ORDER BY recommendation_score DESC, distance_km ASC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `;

  const result = await db.query(sql, params);
  return result.rows;
}

async function getProductRecommendationBreakdown(productId) {
  const sql = `
    SELECT
      p.id,
      p.name,
      COALESCE(rs.count, 0)::INT AS review_count,
      COALESCE(rs.avg_rating, 0)::DECIMAL(3,2) AS avg_rating,
      -- Components
      ROUND((((5 * 4.0) + (COALESCE(rs.count, 0) * COALESCE(rs.avg_rating, 4.0))) / (5 + COALESCE(rs.count, 0)) * 20)::NUMERIC, 2) AS rating_score,
      CASE WHEN COALESCE(rs.count, 0) > 0 THEN ROUND((COALESCE(rs.positive_count, 0) * 1.0 + COALESCE(rs.neutral_count, 0) * 0.5) / COALESCE(rs.count, 1) * 100, 2) ELSE 70.0 END AS sentiment_score,
      CASE WHEN rs.latest_review_at IS NOT NULL THEN ROUND((100.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - rs.latest_review_at)) / 86400.0) / 30.0))::NUMERIC, 2) ELSE 50.0 END AS recency_score,
      CASE WHEN COALESCE(rs.count, 0) <= 1 THEN 100.0 ELSE ROUND(GREATEST(0.0, 100.0 * (1.0 - COALESCE(rs.rating_variance, 0.0) / 4.0))::NUMERIC, 2) END AS consistency_score,
      ROUND((1.0 - EXP(-COALESCE(rs.count, 0)::DECIMAL / 10.0))::NUMERIC, 4) AS volume_confidence,
      -- Combined
      ROUND((
        (
          0.40 * ROUND((((5 * 4.0) + (COALESCE(rs.count, 0) * COALESCE(rs.avg_rating, 4.0))) / (5 + COALESCE(rs.count, 0)) * 20)::NUMERIC, 2)
          + 0.30 * CASE WHEN COALESCE(rs.count, 0) > 0 THEN ROUND((COALESCE(rs.positive_count, 0) * 1.0 + COALESCE(rs.neutral_count, 0) * 0.5) / COALESCE(rs.count, 1) * 100, 2) ELSE 70.0 END
          + 0.15 * CASE WHEN rs.latest_review_at IS NOT NULL THEN ROUND((100.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - rs.latest_review_at)) / 86400.0) / 30.0))::NUMERIC, 2) ELSE 50.0 END
          + 0.15 * CASE WHEN COALESCE(rs.count, 0) <= 1 THEN 100.0 ELSE ROUND(GREATEST(0.0, 100.0 * (1.0 - COALESCE(rs.rating_variance, 0.0) / 4.0))::NUMERIC, 2) END
        ) * ROUND((1.0 - EXP(-COALESCE(rs.count, 0)::DECIMAL / 10.0))::NUMERIC, 4)
      )::NUMERIC, 2) AS recommendation_score
    FROM products p
    LEFT JOIN (
      SELECT
        product_id,
        COUNT(id)::INT AS count,
        AVG(rating)::DECIMAL(3,2) AS avg_rating,
        COUNT(id) FILTER (WHERE sentiment_label = 'positive')::INT AS positive_count,
        COUNT(id) FILTER (WHERE sentiment_label = 'neutral')::INT AS neutral_count,
        COUNT(id) FILTER (WHERE sentiment_label = 'negative')::INT AS negative_count,
        MAX(created_at) AS latest_review_at,
        COALESCE(VAR_SAMP(rating), 0.0)::DECIMAL(5,2) AS rating_variance
      FROM reviews
      WHERE product_id IS NOT NULL
      GROUP BY product_id
    ) rs ON rs.product_id = p.id
    WHERE p.id = $1
  `;
  const res = await db.query(sql, [productId]);
  return res.rows[0];
}

module.exports = {
  getRecommendedProducts,
  getProductRecommendationBreakdown
};
