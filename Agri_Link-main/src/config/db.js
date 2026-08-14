const { Pool } = require('pg');
const logger = require('../utils/logger');

const rawUrl = process.env.DATABASE_URL;
if (!rawUrl) {
  logger.error('CRITICAL: DATABASE_URL environment variable is missing.');
  throw new Error('DATABASE_URL environment variable is not defined.');
}

// Parse the DATABASE_URL manually using Node's built-in URL API.
// This COMPLETELY bypasses pg-connection-string, which in v2.12+ treats
// sslmode=require as sslmode=verify-full — causing "Connection terminated
// unexpectedly" when connecting to Render/Supabase PostgreSQL.
function parseDbUrl(rawUrl) {
  const u = new URL(rawUrl);
  return {
    host:     u.hostname,
    port:     parseInt(u.port) || 5432,
    database: u.pathname.replace(/^\//, ''),
    user:     decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
  };
}

const isRemote =
  rawUrl.includes('render.com')     ||
  rawUrl.includes('supabase.co')    ||
  rawUrl.includes('neon.tech')      ||
  rawUrl.includes('sslmode=require') ||
  rawUrl.includes('ssl=true')       ||
  process.env.NODE_ENV === 'production';

const dbConfig = {
  ...parseDbUrl(rawUrl),
  ssl: isRemote ? { rejectUnauthorized: false } : false,
};

dbConfig.max = 10;
dbConfig.idleTimeoutMillis = 30000;
dbConfig.connectionTimeoutMillis = 30000;

const pool = new Pool(dbConfig);

pool.on('error', (err) => {
  logger.error('Unexpected PostgreSQL pool error:', err);
});

async function testConnection() {
  const client = await pool.connect();
  try {
    const res = await client.query('SELECT NOW() as now');
    logger.info(`PostgreSQL connected — server time: ${res.rows[0].now}`);
    
    // Create password_resets table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS password_resets (
        id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email      VARCHAR(150) NOT NULL,
        otp        VARCHAR(6) NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_password_resets_email ON password_resets(email);
    `);
    logger.info('password_resets table checked/created');
  } finally {
    client.release();
  }
}

/**
 * Convenience query helper
 * @param {string} text  SQL string
 * @param {any[]}  params Parameterized values
 */
async function query(text, params) {
  const start = Date.now();
  const res = await pool.query(text, params);
  const duration = Date.now() - start;
  if (duration > 300) {
    logger.warn(`Slow query (${duration}ms): ${text.substring(0, 80)}`);
  }
  return res;
}

module.exports = { pool, query, testConnection };
