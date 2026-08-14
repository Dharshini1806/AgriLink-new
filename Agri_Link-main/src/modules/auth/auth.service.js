const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../../config/db');
const { ConflictError, UnauthorizedError, NotFoundError } = require('../../middleware/errorHandler');
const { sendEmail } = require('../../utils/email');

const ACCESS_EXPIRES  = process.env.JWT_ACCESS_EXPIRES  || '15m';
const REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES || '7d';

function signAccess(payload)  {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: ACCESS_EXPIRES });
}
function signRefresh(payload) {
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: REFRESH_EXPIRES });
}
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function register({ name, email, password, role, phone, latitude, longitude }) {
  // Check email uniqueness
  const exists = await db.query('SELECT id FROM users WHERE email=$1', [email]);
  if (exists.rows.length) throw new ConflictError('Email already registered');

  const password_hash = await bcrypt.hash(password, 12);
  const result = await db.query(
    `INSERT INTO users (name, email, password_hash, role, phone, latitude, longitude)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id, name, email, role, trust_score, created_at`,
    [name, email, password_hash, role, phone || null, latitude || null, longitude || null]
  );
  const user = result.rows[0];

  const accessToken  = signAccess({ id: user.id, role: user.role });
  const refreshToken = signRefresh({ id: user.id });
  await storeRefreshToken(user.id, refreshToken);

  return { accessToken, refreshToken, user };
}

async function login(email, password) {
  const res = await db.query(
    `SELECT id, name, email, password_hash, role, phone, latitude, longitude,
            trust_score, is_active, farm_name, farm_desc, profile_img, created_at, fcm_token
     FROM users WHERE email=$1`,
    [email]
  );
  const user = res.rows[0];
  if (!user) throw new UnauthorizedError('Email is not registered');
  if (!user.is_active) throw new UnauthorizedError('Account suspended. Contact support.');

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) throw new UnauthorizedError('Incorrect password');

  const { password_hash, ...safeUser } = user;

  const accessToken  = signAccess({ id: user.id, role: user.role });
  const refreshToken = signRefresh({ id: user.id });
  await storeRefreshToken(user.id, refreshToken);

  return { accessToken, refreshToken, user: safeUser };
}

async function refreshTokens(incomingRefreshToken) {
  let payload;
  try {
    payload = jwt.verify(incomingRefreshToken, process.env.JWT_REFRESH_SECRET);
  } catch {
    throw new UnauthorizedError('Invalid or expired refresh token');
  }

  // Check token exists in DB (not revoked)
  const tokenHash = hashToken(incomingRefreshToken);
  const stored = await db.query(
    'SELECT id FROM refresh_tokens WHERE token_hash=$1 AND user_id=$2 AND expires_at > NOW()',
    [tokenHash, payload.id]
  );
  if (!stored.rows.length) throw new UnauthorizedError('Refresh token revoked or expired');

  // Rotate: delete old, issue new pair
  await db.query('DELETE FROM refresh_tokens WHERE token_hash=$1', [tokenHash]);

  const userRes = await db.query('SELECT id, role FROM users WHERE id=$1', [payload.id]);
  if (!userRes.rows[0]) throw new NotFoundError('User not found');

  const user = userRes.rows[0];
  const accessToken  = signAccess({ id: user.id, role: user.role });
  const refreshToken = signRefresh({ id: user.id });
  await storeRefreshToken(user.id, refreshToken);

  return { accessToken, refreshToken };
}

async function logout(userId, refreshToken) {
  if (refreshToken) {
    const tokenHash = hashToken(refreshToken);
    await db.query('DELETE FROM refresh_tokens WHERE token_hash=$1', [tokenHash]);
  }
  // Optionally invalidate all sessions: DELETE FROM refresh_tokens WHERE user_id=$1
}

async function getMe(userId) {
  const res = await db.query(
    `SELECT id, name, email, role, phone, latitude, longitude,
            trust_score, is_active, farm_name, farm_desc, profile_img, created_at
     FROM users WHERE id=$1`,
    [userId]
  );
  if (!res.rows[0]) throw new NotFoundError('User not found');
  return res.rows[0];
}

async function updateFcmToken(userId, fcmToken) {
  await db.query('UPDATE users SET fcm_token=$1 WHERE id=$2', [fcmToken, userId]);
}

async function forgotPassword(email) {
  const normalizedEmail = email.toLowerCase().trim();
  const res = await db.query('SELECT id FROM users WHERE email=$1', [normalizedEmail]);
  if (!res.rows.length) {
    throw new NotFoundError('Email is not registered');
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  const text = `Your AgriLink password reset OTP is ${otp}. This code is valid for 10 minutes.`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
      <h2 style="color: #4CAF50; text-align: center;">AgriLink Password Reset</h2>
      <p>Hello,</p>
      <p>You requested to reset your password. Use the following 6-digit One-Time Password (OTP) to proceed:</p>
      <div style="font-size: 24px; font-weight: bold; letter-spacing: 4px; text-align: center; margin: 30px 0; padding: 15px; background-color: #f9f9f9; border-radius: 4px; color: #333;">
        ${otp}
      </div>
      <p style="color: #666; font-size: 12px;">This code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
      <hr style="border: 0; border-top: 1px solid #eee; margin-top: 30px;" />
      <p style="text-align: center; color: #999; font-size: 11px;">&copy; ${new Date().getFullYear()} AgriLink. All rights reserved.</p>
    </div>
  `;

  // Send email BEFORE storing OTP — fail fast if email cannot be delivered
  const emailResult = await sendEmail({
    to: normalizedEmail,
    subject: 'AgriLink Password Reset OTP',
    text,
    html,
  });

  if (emailResult.status === 'FAILED') {
    throw new Error(`Failed to send OTP email: ${emailResult.error || 'Unknown email error'}`);
  }

  // Clear previous OTPs and store the new one only after email is confirmed sent
  await db.query('DELETE FROM password_resets WHERE email=$1', [normalizedEmail]);
  await db.query(
    'INSERT INTO password_resets (email, otp, expires_at) VALUES ($1, $2, $3)',
    [normalizedEmail, otp, expiresAt]
  );

  return 'OTP sent successfully. Please check your email.';
}

async function verifyOtp(email, otp) {
  const normalizedEmail = email.toLowerCase().trim();
  const normalizedOtp = String(otp).trim();
  const res = await db.query(
    'SELECT id FROM password_resets WHERE email=$1 AND otp=$2 AND expires_at > NOW()',
    [normalizedEmail, normalizedOtp]
  );
  return res.rows.length > 0;
}

async function resetPassword(email, otp, newPassword) {
  const normalizedEmail = email.toLowerCase().trim();
  const isValid = await verifyOtp(normalizedEmail, otp);
  if (!isValid) {
    throw new UnauthorizedError('Invalid or expired OTP code');
  }

  const password_hash = await bcrypt.hash(newPassword, 12);
  const res = await db.query(
    'UPDATE users SET password_hash=$1 WHERE email=$2 RETURNING id',
    [password_hash, normalizedEmail]
  );
  if (!res.rows.length) {
    throw new NotFoundError('User not found');
  }

  await db.query('DELETE FROM password_resets WHERE email=$1', [normalizedEmail]);
  return 'Password reset successfully';
}

// ── Internal helpers ──────────────────────────────────────
async function storeRefreshToken(userId, token) {
  const tokenHash = hashToken(token);
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  // Limit to 5 active sessions per user
  await db.query(
    `DELETE FROM refresh_tokens WHERE user_id=$1 AND id NOT IN (
       SELECT id FROM refresh_tokens WHERE user_id=$1 ORDER BY created_at DESC LIMIT 4
     )`,
    [userId]
  );
  await db.query(
    'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1,$2,$3)',
    [userId, tokenHash, expiresAt]
  );
}

module.exports = {
  register,
  login,
  refreshTokens,
  logout,
  getMe,
  updateFcmToken,
  forgotPassword,
  verifyOtp,
  resetPassword,
};
