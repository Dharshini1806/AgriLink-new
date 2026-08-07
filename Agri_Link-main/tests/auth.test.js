require('dotenv').config();
const request = require('supertest');
const app = require('../src/app');
const db = require('../src/config/db');
const bcrypt = require('bcryptjs');

jest.setTimeout(30000);

describe('Auth Password Reset Integration Tests', () => {
  const testEmail = `temp_test_${Date.now()}@example.com`;
  const originalPassword = 'TestPassword123!';
  const newPassword = 'NewPassword123!';

  beforeAll(async () => {
    // Make sure DB is connected and tables exist
    await db.testConnection();
    
    // Create a temporary test user
    const password_hash = await bcrypt.hash(originalPassword, 12);
    await db.query(
      `INSERT INTO users (name, email, password_hash, role) VALUES ($1, $2, $3, $4)`,
      ['Test User', testEmail, password_hash, 'buyer']
    );
  });

  afterAll(async () => {
    // Clean up test user and password resets
    await db.query('DELETE FROM users WHERE email = $1', [testEmail]);
    await db.query('DELETE FROM password_resets WHERE email = $1', [testEmail]);
    // Close the database pool
    await db.pool.end();
  });

  test('Forgot password, verify OTP, and reset password successfully', async () => {
    // 1. Request OTP (Forgot Password)
    const forgotRes = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: testEmail });
      
    expect(forgotRes.status).toBe(200);
    expect(forgotRes.body.message).toBe('OTP sent successfully');

    // 2. Query the DB to retrieve the generated OTP
    const dbRes = await db.query(
      'SELECT otp FROM password_resets WHERE email = $1 ORDER BY created_at DESC LIMIT 1',
      [testEmail]
    );
    expect(dbRes.rows.length).toBe(1);
    const otpCode = dbRes.rows[0].otp;
    expect(otpCode).toMatch(/^\d{6}$/); // 6-digit number

    // 3. Verify OTP
    const verifyRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ email: testEmail, otp: otpCode });
      
    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.valid).toBe(true);

    // 4. Reset Password
    const resetRes = await request(app)
      .post('/api/auth/reset-password')
      .send({
        email: testEmail,
        otp: otpCode,
        password: newPassword
      });
      
    expect(resetRes.status).toBe(200);
    expect(resetRes.body.message).toBe('Password reset successfully');

    // 5. Verify OTP is deleted from DB
    const dbResAfterReset = await db.query(
      'SELECT id FROM password_resets WHERE email = $1',
      [testEmail]
    );
    expect(dbResAfterReset.rows.length).toBe(0);

    // 6. Verify Login with new password works
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({
        email: testEmail,
        password: newPassword
      });
      
    expect(loginRes.status).toBe(200);
    expect(loginRes.body.accessToken).toBeDefined();
  });

  test('Fails on invalid email', async () => {
    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'nonexistent_user_email_12345@example.com' });
      
    expect(res.status).toBe(404);
  });

  test('Fails on incorrect OTP code', async () => {
    const res = await request(app)
      .post('/api/auth/verify-otp')
      .send({ email: testEmail, otp: '000000' });
      
    expect(res.status).toBe(200);
    expect(res.body.valid).toBe(false);
  });
});
