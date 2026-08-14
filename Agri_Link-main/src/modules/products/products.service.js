const db = require('../../config/db');
const { uploadBuffer } = require('../../config/cloudinary');
const { NotFoundError, ForbiddenError, BadRequestError } = require('../../middleware/errorHandler');

/**
 * Geo-filtered product feed for buyers
 * Filters products where the buyer's location is within the seller's delivery_radius_km
 */
async function getProductFeed({ lat, lng, radius = 50, category, q, grade, minPrice, maxPrice, page = 1, limit = 20 }) {
  const offset = (page - 1) * limit;
  const params = [];
  const conditions = ['p.is_active = TRUE', 'p.is_approved = TRUE', 'p.quantity > 0'];

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

  params.push(limit, offset);

  // ── Recommendation system ─────────────────────────────────────────────────
  // CTEs compute:
  //   qty_sold        – units of this product delivered to buyers
  //   seller_total_qty – total units the seller has ever delivered
  //   sell_pct        – share of this product in seller's total sales (%)
  //   seller_score    – composite score: sales_volume (×0.5) + avg_rating (×10) + trust (×2)
  //
  // Products are ordered by seller_score DESC so buyers see the most active,
  // highly-rated sellers first — a simple collaborative-filter-style ranking.
  const sql = `
    WITH delivered_qty AS (
      SELECT
        oi.product_id,
        p.seller_id,
        SUM(oi.quantity)::INT AS qty_sold
      FROM order_items oi
      JOIN orders o   ON o.id  = oi.order_id
      JOIN products p ON p.id  = oi.product_id
      WHERE o.status = 'delivered'
      GROUP BY oi.product_id, p.seller_id
    ),
    seller_total_qty AS (
      SELECT seller_id, SUM(qty_sold)::INT AS total_qty
      FROM delivered_qty
      GROUP BY seller_id
    )
    SELECT
      p.*,
      c.name AS category_name,
      c.icon_url AS category_icon,
      u.name AS seller_name,
      u.trust_score AS seller_trust,
      u.latitude AS seller_lat,
      u.longitude AS seller_lng,
      COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating,
      COUNT(r.id)::INT AS review_count,
      ROUND((${distanceExpr})::NUMERIC, 1) AS distance_km,
      COALESCE(dq.qty_sold, 0)::INT AS qty_sold,
      CASE
        WHEN stq.total_qty > 0
          THEN ROUND((COALESCE(dq.qty_sold, 0)::DECIMAL / stq.total_qty * 100)::NUMERIC, 1)
        ELSE 0
      END AS sell_pct,
      ROUND((
        COALESCE(stq.total_qty, 0) * 0.5
        + COALESCE(AVG(r.rating), 0) * 10
        + COALESCE(u.trust_score, 0) * 2
      )::NUMERIC, 2) AS seller_score
    FROM products p
    JOIN users u ON u.id = p.seller_id
    JOIN categories c ON c.id = p.category_id
    LEFT JOIN reviews r ON r.product_id = p.id
    LEFT JOIN delivered_qty    dq  ON dq.product_id = p.id
    LEFT JOIN seller_total_qty stq ON stq.seller_id = p.seller_id
    WHERE ${whereClause}
    GROUP BY p.id, c.id, u.id, dq.qty_sold, stq.total_qty
    ORDER BY seller_score DESC, sell_pct DESC, distance_km ASC
    LIMIT $${params.length - 1} OFFSET $${params.length}
  `;

  const result = await db.query(sql, params);
  return result.rows;
}

async function getProductById(productId) {
  const res = await db.query(
    `SELECT p.*, c.name AS category_name, c.icon_url AS category_icon,
            u.name AS seller_name, u.phone AS seller_phone,
            u.trust_score AS seller_trust, u.farm_name, u.farm_desc,
            u.latitude AS seller_lat, u.longitude AS seller_lng,
            COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating,
            COUNT(r.id)::INT AS review_count
     FROM products p
     JOIN users u ON u.id = p.seller_id
     JOIN categories c ON c.id = p.category_id
     LEFT JOIN reviews r ON r.product_id = p.id
     WHERE p.id = $1
     GROUP BY p.id, c.id, u.id`,
    [productId]
  );
  if (!res.rows[0]) throw new NotFoundError('Product not found');
  return res.rows[0];
}

async function getSellerProducts(sellerId, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const res = await db.query(
    `SELECT p.*, c.name AS category_name,
            COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating,
            COUNT(r.id)::INT AS review_count
     FROM products p
     JOIN categories c ON c.id = p.category_id
     LEFT JOIN reviews r ON r.product_id = p.id
     WHERE p.seller_id = $1
     GROUP BY p.id, c.id
     ORDER BY p.created_at DESC
     LIMIT $2 OFFSET $3`,
    [sellerId, limit, offset]
  );
  return res.rows;
}

async function createProduct(sellerId, data, files = []) {
  // Upload images to Cloudinary
  const imageUrls = [];
  for (const file of files) {
    const { url } = await uploadBuffer(file.buffer, 'agrilink/products');
    imageUrls.push(url);
  }

  const {
    name, description, category_id, price, quantity, quantity_unit,
    quality_grade, delivery_area, delivery_radius_km,
  } = data;

  const res = await db.query(
    `INSERT INTO products
       (seller_id, category_id, name, description, price, quantity, quantity_unit,
        quality_grade, delivery_area, delivery_radius_km, image_urls)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     RETURNING *`,
    [sellerId, category_id, name, description || null, parseFloat(price), parseInt(quantity), quantity_unit || 'kg',
      quality_grade || null, delivery_area || null, parseFloat(delivery_radius_km || 30), imageUrls]
  );
  return res.rows[0];
}

async function updateProduct(productId, sellerId, data, newFiles = []) {
  // Ownership check
  const existing = await db.query('SELECT * FROM products WHERE id=$1', [productId]);
  if (!existing.rows[0]) throw new NotFoundError('Product not found');
  if (existing.rows[0].seller_id !== sellerId) throw new ForbiddenError('Not your product');

  // Upload any new images
  let imageUrls = existing.rows[0].image_urls || [];
  for (const file of newFiles) {
    const { url } = await uploadBuffer(file.buffer, 'agrilink/products');
    imageUrls.push(url);
  }
  if (imageUrls.length > 5) imageUrls = imageUrls.slice(-5);

  const {
    name, description, category_id, price, quantity, quantity_unit,
    quality_grade, delivery_area, delivery_radius_km, is_active,
  } = data;

  const res = await db.query(
    `UPDATE products SET
       name=$1, description=$2, category_id=$3, price=$4, quantity=$5, quantity_unit=$6,
       quality_grade=$7, delivery_area=$8, delivery_radius_km=$9,
       image_urls=$10, is_active=$11, updated_at=NOW()
     WHERE id=$12 AND seller_id=$13
     RETURNING *`,
    [
      name ?? existing.rows[0].name,
      description ?? existing.rows[0].description,
      category_id ?? existing.rows[0].category_id,
      price !== undefined ? parseFloat(price) : existing.rows[0].price,
      quantity !== undefined ? parseInt(quantity) : existing.rows[0].quantity,
      quantity_unit ?? existing.rows[0].quantity_unit ?? 'kg',
      quality_grade ?? existing.rows[0].quality_grade,
      delivery_area ?? existing.rows[0].delivery_area,
      delivery_radius_km !== undefined ? parseFloat(delivery_radius_km) : existing.rows[0].delivery_radius_km,
      imageUrls,
      is_active !== undefined ? is_active : existing.rows[0].is_active,
      productId,
      sellerId,
    ]
  );
  return res.rows[0];
}

async function softDeleteProduct(productId, sellerId) {
  const res = await db.query('SELECT seller_id FROM products WHERE id=$1', [productId]);
  if (!res.rows[0]) throw new NotFoundError('Product not found');
  if (res.rows[0].seller_id !== sellerId) throw new ForbiddenError('Not your product');
  await db.query('UPDATE products SET is_active=FALSE, updated_at=NOW() WHERE id=$1', [productId]);
}

async function getCategories() {
  const res = await db.query('SELECT * FROM categories ORDER BY name');
  return res.rows;
}

// Wishlist
async function toggleWishlist(userId, productId) {
  const existing = await db.query(
    'SELECT 1 FROM wishlists WHERE user_id=$1 AND product_id=$2', [userId, productId]
  );
  if (existing.rows.length) {
    await db.query('DELETE FROM wishlists WHERE user_id=$1 AND product_id=$2', [userId, productId]);
    return { wishlisted: false };
  } else {
    await db.query('INSERT INTO wishlists (user_id, product_id) VALUES ($1,$2)', [userId, productId]);
    return { wishlisted: true };
  }
}

async function getWishlist(userId) {
  const res = await db.query(
    `SELECT p.*, c.name AS category_name,
            COALESCE(AVG(r.rating), 0)::DECIMAL(3,2) AS avg_rating
     FROM wishlists w
     JOIN products p ON p.id = w.product_id
     JOIN categories c ON c.id = p.category_id
     LEFT JOIN reviews r ON r.product_id = p.id
          WHERE w.user_id=$1 AND p.is_active=TRUE
     GROUP BY p.id, c.id, w.added_at
     ORDER BY w.added_at DESC`,
    [userId]
  );
  return res.rows;
}

async function getTopSellers(limit = 5) {
  const res = await db.query(`
    WITH seller_revenue AS (
      SELECT
        o.seller_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
      FROM orders o
      JOIN order_items oi ON oi.order_id = o.id
      WHERE o.status = 'delivered'
      GROUP BY o.seller_id
    ),
    total_rev AS (
      SELECT COALESCE(SUM(revenue), 0) AS total FROM seller_revenue
    ),
    seller_ratings AS (
      SELECT reviewee_id,
             COALESCE(AVG(rating), 0)::DECIMAL(3,2) AS avg_rating,
             COUNT(*)::INT                           AS review_count
      FROM reviews
      GROUP BY reviewee_id
    ),
    ranked AS (
      SELECT
        u.id,
        u.name,
        u.farm_name,
        u.profile_img,
        u.trust_score,
        COALESCE(sr.avg_rating, 0)::DECIMAL(3,2)  AS avg_rating,
        COALESCE(sr.review_count, 0)::INT          AS review_count,
        COALESCE(rev.revenue, 0)                   AS revenue,
        CASE
          WHEN tr.total > 0
            THEN ROUND((COALESCE(rev.revenue, 0) / tr.total * 100)::NUMERIC, 1)
          ELSE 0
        END AS sales_pct,
        ROW_NUMBER() OVER (
          ORDER BY COALESCE(sr.avg_rating, 0) DESC,
                   u.trust_score              DESC,
                   COALESCE(rev.revenue, 0)   DESC
        ) AS rank
      FROM users u
      CROSS JOIN total_rev tr
      LEFT JOIN seller_revenue rev ON rev.seller_id  = u.id
      LEFT JOIN seller_ratings sr  ON sr.reviewee_id = u.id
      WHERE u.role = 'seller' AND u.is_active = TRUE
    )
    SELECT
      r.*,
      (
        SELECT COALESCE(json_agg(pd ORDER BY pd.avg_rating DESC), '[]'::json)
        FROM (
          SELECT
            p.id, p.name, p.price, p.image_urls, p.quality_grade,
            COALESCE(AVG(rv.rating), 0)::DECIMAL(3,2) AS avg_rating
          FROM products p
          LEFT JOIN reviews rv ON rv.product_id = p.id
          WHERE p.seller_id = r.id
            AND p.is_active = TRUE
            AND p.is_approved = TRUE
            AND p.quantity > 0
          GROUP BY p.id
          ORDER BY avg_rating DESC
          LIMIT 2
        ) pd
      ) AS top_products
    FROM ranked r
    ORDER BY r.rank
    LIMIT $1
  `, [limit]);
  return res.rows;
}

async function getTopSellerDetails(limit = 20) {
  const res = await db.query(`
    WITH delivered_qty AS (
      SELECT
        oi.product_id,
        p.seller_id,
        SUM(oi.quantity)::INT AS qty_sold
      FROM order_items oi
      JOIN orders o   ON o.id  = oi.order_id
      JOIN products p ON p.id  = oi.product_id
      WHERE o.status = 'delivered'
      GROUP BY oi.product_id, p.seller_id
    ),
    seller_total_qty AS (
      SELECT seller_id, SUM(qty_sold)::INT AS total_qty
      FROM delivered_qty
      GROUP BY seller_id
    ),
    seller_ratings AS (
      SELECT reviewee_id,
             COALESCE(AVG(rating), 0)::DECIMAL(3,2) AS avg_rating,
             COUNT(*)::INT                           AS review_count
      FROM reviews
      GROUP BY reviewee_id
    ),
    ranked AS (
      SELECT
        u.id,
        u.name,
        u.farm_name,
        u.farm_desc,
        u.profile_img,
        u.trust_score,
        COALESCE(sr.avg_rating, 0)::DECIMAL(3,2) AS avg_rating,
        COALESCE(sr.review_count, 0)::INT         AS review_count,
        ROW_NUMBER() OVER (
          ORDER BY COALESCE(sr.avg_rating, 0) DESC,
                   u.trust_score              DESC
        ) AS rank
      FROM users u
      LEFT JOIN seller_ratings sr ON sr.reviewee_id = u.id
      WHERE u.role = 'seller' AND u.is_active = TRUE
    )
    SELECT
      rs.*,
      (
        SELECT COALESCE(json_agg(pd ORDER BY pd.sell_pct DESC, pd.avg_rating DESC), '[]'::json)
        FROM (
          SELECT
            p.id,
            p.name,
            p.price,
            p.image_urls,
            p.quality_grade,
            p.quantity,
            COALESCE(dq.qty_sold, 0)::INT                       AS qty_sold,
            COALESCE(AVG(rv.rating), 0)::DECIMAL(3,2)           AS avg_rating,
            CASE
              WHEN stq.total_qty > 0
                THEN ROUND((COALESCE(dq.qty_sold, 0)::DECIMAL / stq.total_qty * 100)::NUMERIC, 1)
              ELSE 0
            END AS sell_pct
          FROM products p
          LEFT JOIN delivered_qty    dq  ON dq.product_id = p.id
          LEFT JOIN seller_total_qty stq ON stq.seller_id = p.seller_id
          LEFT JOIN reviews          rv  ON rv.product_id = p.id
          WHERE p.seller_id = rs.id
            AND p.is_active   = TRUE
            AND p.is_approved = TRUE
          GROUP BY p.id, dq.qty_sold, stq.total_qty
          ORDER BY sell_pct DESC, avg_rating DESC
        ) pd
      ) AS products
    FROM ranked rs
    ORDER BY rs.rank
    LIMIT $1
  `, [limit]);
  return res.rows;
}

module.exports = {
  getProductFeed, getProductById, getSellerProducts,
  createProduct, updateProduct, softDeleteProduct,
  getCategories, toggleWishlist, getWishlist,
  getTopSellers, getTopSellerDetails,
};
