const { Pool } = require('pg');
const parse = require('pg-connection-string').parse;
const logger = require('../utils/logger');

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  logger.error('CRITICAL: DATABASE_URL environment variable is missing. Please set DATABASE_URL in your Render dashboard environment variables.');
  throw new Error('DATABASE_URL environment variable is not defined.');
}

const dbConfig = parse(connectionString);

if (
  connectionString.includes('sslmode=require') ||
  connectionString.includes('ssl=true') ||
  connectionString.includes('render.com') ||
  connectionString.includes('supabase.co') ||
  process.env.NODE_ENV === 'production'
) {
  dbConfig.ssl = { rejectUnauthorized: false };
} else {
  delete dbConfig.ssl;
}

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
