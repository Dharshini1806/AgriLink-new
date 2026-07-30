const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');

// Route imports
const authRoutes    = require('./modules/auth/auth.routes');
const userRoutes    = require('./modules/users/users.routes');
const productRoutes = require('./modules/products/products.routes');
const orderRoutes   = require('./modules/orders/orders.routes');
const reviewRoutes  = require('./modules/reviews/reviews.routes');
const chatRoutes    = require('./modules/chat/chat.routes');
const smartRoutes   = require('./modules/smart/smart.routes');
const adminRoutes   = require('./modules/admin/admin.routes');

const app = express();

// ─── Security Headers ────────────────────────────────────
app.use(helmet());

// ─── CORS ────────────────────────────────────────────────
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '*')
  .split(',')
  .map(o => o.trim());

app.use(cors({
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);
    const isLocalhost = origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1');
    const isVercel = origin.endsWith('.vercel.app');
    if (
      allowedOrigins.includes('*') ||
      allowedOrigins.includes(origin) ||
      process.env.NODE_ENV === 'development' ||
      isLocalhost ||
      isVercel
    ) {
      cb(null, true);
    } else {
      cb(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
}));

// ─── Body Parsing ────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Request Logging ─────────────────────────────────────
app.use(morgan('combined', {
  stream: { write: msg => logger.info(msg.trim()) },
  skip: (req) => req.path === '/health',
}));

// ─── Global Rate Limit ───────────────────────────────────
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
}));

// ─── Health Check ────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: Date.now(), uptime: process.uptime() });
});

// ─── API Routes ──────────────────────────────────────────
app.use('/api/auth',     authRoutes);
app.use('/api/users',    userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders',   orderRoutes);
app.use('/api/reviews',  reviewRoutes);
app.use('/api/chat',     chatRoutes);
app.use('/api/smart',    smartRoutes);
app.use('/api/admin',    adminRoutes);

// ─── 404 ─────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Global Error Handler ────────────────────────────────
app.use(errorHandler);

module.exports = app;
