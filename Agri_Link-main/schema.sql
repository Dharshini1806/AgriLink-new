-- ============================================================
-- AgriLink Complete Database Schema
-- Run this in Neon SQL Editor in order
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ─── CATEGORIES ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name      VARCHAR(80) UNIQUE NOT NULL,
  icon_url  VARCHAR(300)
);

-- ─── USERS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role          VARCHAR(10) CHECK (role IN ('buyer','seller','admin')) NOT NULL,
  phone         VARCHAR(20),
  latitude      DECIMAL(9,6),
  longitude     DECIMAL(9,6),
  trust_score   DECIMAL(3,2) DEFAULT 0.00,
  is_active     BOOLEAN DEFAULT TRUE,
  fcm_token     VARCHAR(255),
  farm_name     VARCHAR(150),
  farm_desc     TEXT,
  profile_img   VARCHAR(300),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_role     ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email    ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_location ON users(latitude, longitude);

-- ─── PRODUCTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id        UUID NOT NULL REFERENCES categories(id),
  name               VARCHAR(150) NOT NULL,
  description        TEXT,
  price              DECIMAL(10,2) NOT NULL CHECK (price > 0),
  quantity           INTEGER NOT NULL CHECK (quantity >= 0),
  quality_grade      CHAR(1) CHECK (quality_grade IN ('A','B','C')),
  delivery_area      VARCHAR(100),
  delivery_radius_km DECIMAL(6,2) DEFAULT 30,
  image_urls         TEXT[] DEFAULT '{}',
  is_active          BOOLEAN DEFAULT TRUE,
  is_approved        BOOLEAN DEFAULT TRUE,
  search_vector      TSVECTOR,
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_seller   ON products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active   ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_search   ON products USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_products_trgm     ON products USING GIN(name gin_trgm_ops);

-- Auto-update search vector
CREATE OR REPLACE FUNCTION products_search_vector_update() RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    COALESCE(NEW.name,'') || ' ' || COALESCE(NEW.description,'')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS products_search_vector_trigger ON products;
CREATE TRIGGER products_search_vector_trigger
  BEFORE INSERT OR UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION products_search_vector_update();

-- ─── ORDERS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id          UUID NOT NULL REFERENCES users(id),
  seller_id         UUID NOT NULL REFERENCES users(id),
  status            VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending','confirmed','packed',
                                      'out_for_delivery','delivered','cancelled')),
  total_amount      DECIMAL(12,2) NOT NULL,
  buyer_commission  DECIMAL(10,2) NOT NULL,
  seller_commission DECIMAL(10,2) NOT NULL,
  delivery_address  TEXT,
  notes             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_buyer  ON orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller ON orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- ─── ORDER ITEMS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id   UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- ─── TRANSACTIONS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID UNIQUE NOT NULL REFERENCES orders(id),
  gross_amount      DECIMAL(12,2) NOT NULL,
  platform_fee      DECIMAL(10,2) NOT NULL,
  net_seller_payout DECIMAL(12,2) NOT NULL,
  status            VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending','settled','failed')),
  settled_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ─── REVIEWS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES users(id),
  product_id  UUID REFERENCES products(id),
  reviewee_id UUID REFERENCES users(id),
  rating      INTEGER CHECK (rating BETWEEN 1 AND 5) NOT NULL,
  comment     TEXT,
  order_id    UUID REFERENCES orders(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_product  ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_order_reviewer
  ON reviews(order_id, reviewer_id, COALESCE(product_id, '00000000-0000-0000-0000-000000000000'::uuid));

-- ─── MESSAGES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id  UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  content   TEXT NOT NULL,
  is_read   BOOLEAN DEFAULT FALSE,
  sent_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_order ON messages(order_id, sent_at);

-- ─── RECIPES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recipes (
  id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(150) UNIQUE NOT NULL,
  description TEXT,
  image_url VARCHAR(300)
);

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id      UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  category_id    UUID NOT NULL REFERENCES categories(id),
  typical_qty_g  INTEGER DEFAULT 200,
  notes          VARCHAR(200)
);

-- ─── WISHLISTS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wishlists (
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  added_at   TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, product_id)
);

-- ─── REFRESH TOKENS (blacklist) ───────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- ─── SEED: CATEGORIES ─────────────────────────────────────
INSERT INTO categories (name, icon_url) VALUES
  ('Vegetables',   'https://cdn-icons-png.flaticon.com/512/1625/1625048.png'),
  ('Fruits',       'https://cdn-icons-png.flaticon.com/512/1625/1625133.png'),
  ('Grains',       'https://cdn-icons-png.flaticon.com/512/3082/3082044.png'),
  ('Dairy',        'https://cdn-icons-png.flaticon.com/512/2674/2674487.png'),
  ('Pulses',       'https://cdn-icons-png.flaticon.com/512/2553/2553691.png'),
  ('Spices',       'https://cdn-icons-png.flaticon.com/512/3081/3081870.png'),
  ('Leafy Greens', 'https://cdn-icons-png.flaticon.com/512/2909/2909766.png'),
  ('Roots & Tubers','https://cdn-icons-png.flaticon.com/512/2723/2723645.png'),
  ('Herbs',        'https://cdn-icons-png.flaticon.com/512/4046/4046244.png'),
  ('Oilseeds',     'https://cdn-icons-png.flaticon.com/512/3082/3082062.png')
ON CONFLICT (name) DO NOTHING;

-- ─── SEED: RECIPES ────────────────────────────────────────
WITH
  veg  AS (SELECT id FROM categories WHERE name='Vegetables'),
  fruits AS (SELECT id FROM categories WHERE name='Fruits'),
  grains AS (SELECT id FROM categories WHERE name='Grains'),
  dairy AS (SELECT id FROM categories WHERE name='Dairy'),
  pulses AS (SELECT id FROM categories WHERE name='Pulses'),
  spices AS (SELECT id FROM categories WHERE name='Spices'),
  leafy AS (SELECT id FROM categories WHERE name='Leafy Greens'),
  roots AS (SELECT id FROM categories WHERE name='Roots & Tubers'),
  herbs AS (SELECT id FROM categories WHERE name='Herbs')

INSERT INTO recipes (name, description) VALUES
  ('Sambar',        'South Indian lentil-vegetable stew'),
  ('Vegetable Curry','Mixed vegetable curry with spices'),
  ('Dal Tadka',     'Yellow lentil soup with tempering'),
  ('Palak Paneer',  'Cottage cheese in spinach gravy'),
  ('Aloo Gobi',     'Potato and cauliflower dry curry'),
  ('Rasam',         'Thin tomato-tamarind soup'),
  ('Upma',          'Semolina breakfast dish'),
  ('Fruit Salad',   'Fresh seasonal fruit mix')
ON CONFLICT (name) DO NOTHING;

-- Admin seed (password: Admin@1234 — change immediately in prod)
INSERT INTO users (name, email, password_hash, role, phone)
VALUES (
  'AgriLink Admin',
  'admin@agrilink.in',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RgY4e4I3y',
  'admin',
  '+919999999999'
) ON CONFLICT (email) DO NOTHING;
