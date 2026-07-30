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
      6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(u.latitude) - RADIANS($${params.length - 1})) / 2), 2) +
        COS(RADIANS($${params.length - 1})) * COS(RADIANS(u.latitude)) *
        POWER(SIN((RADIANS(u.longitude) - RADIANS($${params.length})) / 2), 2)
      ))
    ) <= p.delivery_radius_km`);
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
  const sql = `
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
      ROUND((${distanceExpr})::NUMERIC, 1) AS distance_km
    FROM products p
    JOIN users u ON u.id = p.seller_id
    JOIN categories c ON c.id = p.category_id
    LEFT JOIN reviews r ON r.product_id = p.id
    WHERE ${whereClause}
    GROUP BY p.id, c.id, u.id
    ORDER BY distance_km ASC, avg_rating DESC
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

module.exports = {
  getProductFeed, getProductById, getSellerProducts,
  createProduct, updateProduct, softDeleteProduct,
  getCategories, toggleWishlist, getWishlist,
};
