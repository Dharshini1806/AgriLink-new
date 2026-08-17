require('dotenv').config();
const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');
const bcrypt = require('bcryptjs');

jest.setTimeout(180000);

describe('Review-Based Recommendation System Integration Tests', () => {
  let buyerToken, sellerId, buyerId;
  let catId;
  let prodAId, prodBId, prodCId;
  let orderAId, orderBId, orderCId, orderCId2, extraOrderBIds = [];

  beforeAll(async () => {
    // We already cleared old test data, but let's make sure it is cleared
  }, 180000);

  beforeAll(async () => {
    // 1. Connect and migrate schema
    await db.testConnection();

    // 2. Clear old test data if any
    await db.query(`DELETE FROM reviews WHERE comment LIKE 'TEST_%'`);
    await db.query(`DELETE FROM order_items WHERE quantity = 9999 OR quantity = 8888`);
    await db.query(`DELETE FROM orders WHERE notes LIKE 'TEST_%'`);
    await db.query(`DELETE FROM products WHERE name LIKE 'TEST_%'`);
    await db.query(`DELETE FROM users WHERE email LIKE 'test_%@example.com'`);

    // 3. Create category
    const catRes = await db.query(
      `INSERT INTO categories (name, icon_url) 
       VALUES ('TEST_Produce', 'http://example.com/icon.png') 
       ON CONFLICT (name) DO UPDATE SET icon_url=EXCLUDED.icon_url 
       RETURNING id`
    );
    catId = catRes.rows[0].id;

    // 4. Create Seller & Buyer
    const passwordHash = await bcrypt.hash('TestPass123!', 12);
    const sellerRes = await db.query(
      `INSERT INTO users (name, email, password_hash, role, trust_score) 
       VALUES ('TEST Seller', 'test_seller@example.com', $1, 'seller', 4.0) RETURNING id`,
      [passwordHash]
    );
    sellerId = sellerRes.rows[0].id;

    const buyerRes = await db.query(
      `INSERT INTO users (name, email, password_hash, role) 
       VALUES ('TEST Buyer', 'test_buyer@example.com', $1, 'buyer') RETURNING id`,
      [passwordHash]
    );
    buyerId = buyerRes.rows[0].id;

    // 5. Get Buyer Auth Token
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test_buyer@example.com', password: 'TestPass123!' });
    buyerToken = loginRes.body.accessToken;

    // 6. Create Products
    const prodARes = await db.query(
      `INSERT INTO products (seller_id, category_id, name, description, price, quantity, quality_grade, is_active, is_approved)
       VALUES ($1, $2, 'TEST Product A (High Sales, Poor Reviews)', 'TEST description', 100, 1000, 'A', TRUE, TRUE) RETURNING id`,
      [sellerId, catId]
    );
    prodAId = prodARes.rows[0].id;

    const prodBRes = await db.query(
      `INSERT INTO products (seller_id, category_id, name, description, price, quantity, quality_grade, is_active, is_approved)
       VALUES ($1, $2, 'TEST Product B (Lower Sales, Excellent Reviews)', 'TEST description', 200, 500, 'B', TRUE, TRUE) RETURNING id`,
      [sellerId, catId]
    );
    prodBId = prodBRes.rows[0].id;

    const prodCRes = await db.query(
      `INSERT INTO products (seller_id, category_id, name, description, price, quantity, quality_grade, is_active, is_approved)
       VALUES ($1, $2, 'TEST Product C (Few Reviews, 5 Stars)', 'TEST description', 300, 100, 'A', TRUE, TRUE) RETURNING id`,
      [sellerId, catId]
    );
    prodCId = prodCRes.rows[0].id;

    // 7. Create orders and delivered order items (representing sales volume)
    const orderARes = await db.query(
      `INSERT INTO orders (buyer_id, seller_id, status, total_amount, buyer_commission, seller_commission, notes)
       VALUES ($1, $2, 'delivered', 999900, 0, 0, 'TEST_A') RETURNING id`,
      [buyerId, sellerId]
    );
    orderAId = orderARes.rows[0].id;
    await db.query(
      `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
       VALUES ($1, $2, 9999, 100)`,
      [orderAId, prodAId]
    );

    const orderBRes = await db.query(
      `INSERT INTO orders (buyer_id, seller_id, status, total_amount, buyer_commission, seller_commission, notes)
       VALUES ($1, $2, 'delivered', 20000, 0, 0, 'TEST_B') RETURNING id`,
      [buyerId, sellerId]
    );
    orderBId = orderBRes.rows[0].id;
    await db.query(
      `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
       VALUES ($1, $2, 100, 200)`,
      [orderBId, prodBId]
    );

    const orderCRes = await db.query(
      `INSERT INTO orders (buyer_id, seller_id, status, total_amount, buyer_commission, seller_commission, notes)
       VALUES ($1, $2, 'delivered', 1500, 0, 0, 'TEST_C') RETURNING id`,
      [buyerId, sellerId]
    );
    orderCId = orderCRes.rows[0].id;
    await db.query(
      `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
       VALUES ($1, $2, 5, 300)`,
      [orderCId, prodCId]
    );

    // Order 2 for Product C
    const orderC2Res = await db.query(
      `INSERT INTO orders (buyer_id, seller_id, status, total_amount, buyer_commission, seller_commission, notes)
       VALUES ($1, $2, 'delivered', 1500, 0, 0, 'TEST_C2') RETURNING id`,
      [buyerId, sellerId]
    );
    orderCId2 = orderC2Res.rows[0].id;
    await db.query(
      `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
       VALUES ($1, $2, 5, 300)`,
      [orderCId2, prodCId]
    );

    // Extra orders for Product B (for volume reviews)
    for (let i = 0; i < 5; i++) {
      const extraOrderRes = await db.query(
        `INSERT INTO orders (buyer_id, seller_id, status, total_amount, buyer_commission, seller_commission, notes)
         VALUES ($1, $2, 'delivered', 200, 0, 0, 'TEST_B_vol') RETURNING id`,
        [buyerId, sellerId]
      );
      const eId = extraOrderRes.rows[0].id;
      extraOrderBIds.push(eId);
      await db.query(
        `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
         VALUES ($1, $2, 1, 200)`,
        [eId, prodBId]
      );
    }
  });

  afterAll(async () => {
    // Clean up
    await db.query(`DELETE FROM reviews WHERE comment LIKE 'TEST_%'`);
    await db.query(`DELETE FROM order_items WHERE quantity = 9999 OR quantity = 8888 OR quantity = 100 OR quantity = 5 OR quantity = 1`);
    await db.query(`DELETE FROM orders WHERE notes LIKE 'TEST_%'`);
    await db.query(`DELETE FROM products WHERE name LIKE 'TEST_%'`);
    await db.query(`DELETE FROM users WHERE email LIKE 'test_%@example.com'`);
    await db.query(`DELETE FROM categories WHERE name = 'TEST_Produce'`);
    await db.pool.end();
  }, 180000);

  test('Buyer can submit reviews with tags, and sentiment analysis runs automatically', async () => {
    // 1. Submit negative review for Product A
    const resA = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({
        orderId: orderAId,
        productId: prodAId,
        rating: 2,
        comment: 'TEST_A Awful quality. The produce arrived damaged, and I am very disappointed.',
        feedbackTags: ['Poor Quality', 'Damaged Product']
      });

    expect(resA.status).toBe(201);
    expect(resA.body.sentiment_label).toBe('negative');
    expect(resA.body.feedback_tags).toContain('Poor Quality');

    // 2. Submit positive review for Product B
    const resB = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({
        orderId: orderBId,
        productId: prodBId,
        rating: 5,
        comment: 'TEST_B Excellent quality! The product is super fresh and value for money.',
        feedbackTags: ['Excellent Product', 'Value for Money']
      });

    expect(resB.status).toBe(201);
    expect(resB.body.sentiment_label).toBe('positive');

    // 3. Submit reviews for Product C
    const resC = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${buyerToken}`)
      .send({
        orderId: orderCId,
        productId: prodCId,
        rating: 5,
        comment: 'TEST_C Great product, love it.',
        feedbackTags: ['Good Quality']
      });
    expect(resC.status).toBe(201);

    // Insert a second review for C manually
    await db.query(
      `INSERT INTO reviews (reviewer_id, user_id, product_id, order_id, rating, comment, review_text, sentiment_label)
       VALUES ($1, $1, $2, $3, 5, 'TEST_C2 fantastic product', 'TEST_C2 fantastic product', $4)`,
      [buyerId, prodCId, orderCId2, 'positive']
    );

    // Insert 5 more positive reviews for B
    for (let i = 0; i < 5; i++) {
      await db.query(
        `INSERT INTO reviews (reviewer_id, user_id, product_id, order_id, rating, comment, review_text, sentiment_label)
         VALUES ($1, $1, $2, $3, 5, 'TEST_B_vol excellent', 'TEST_B_vol excellent', $4)`,
        [buyerId, prodBId, extraOrderBIds[i], 'positive']
      );
    }
  });

  test('Product B (lower sales, excellent reviews) outranks Product A (high sales, poor reviews)', async () => {
    const res = await request(app)
      .get('/api/products/recommended')
      .set('Authorization', `Bearer ${buyerToken}`);

    expect(res.status).toBe(200);
    const products = res.body.products;
    
    const idxA = products.findIndex(p => p.id === prodAId);
    const idxB = products.findIndex(p => p.id === prodBId);

    expect(idxB).toBeGreaterThan(-1);
    expect(idxA).toBeGreaterThan(-1);
    expect(idxB).toBeLessThan(idxA);
  });

  test('Product B (6 reviews, 5.0) outranks Product C (2 reviews, 5.0) due to review volume confidence', async () => {
    const res = await request(app)
      .get('/api/products/recommended')
      .set('Authorization', `Bearer ${buyerToken}`);

    expect(res.status).toBe(200);
    const products = res.body.products;

    const idxB = products.findIndex(p => p.id === prodBId);
    const idxC = products.findIndex(p => p.id === prodCId);

    expect(idxB).toBeGreaterThan(-1);
    expect(idxC).toBeGreaterThan(-1);
    expect(idxB).toBeLessThan(idxC);
  });

  test('Retrieving recommendation breakdown endpoint works', async () => {
    const res = await request(app)
      .get(`/api/products/${prodBId}/recommendation-score`)
      .set('Authorization', `Bearer ${buyerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.recommendation_score).toBeDefined();
    expect(res.body.rating_score).toBeDefined();
    expect(res.body.sentiment_score).toBeDefined();
  });

  test('Retrieving review summary endpoint works', async () => {
    const res = await request(app)
      .get(`/api/products/${prodBId}/review-summary`)
      .set('Authorization', `Bearer ${buyerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.averageRating).toBeDefined();
    expect(res.body.sentimentSummary).toBeDefined();
    expect(res.body.distribution).toBeDefined();
  });
});
