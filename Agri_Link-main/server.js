require('dotenv').config();
const http = require('http');
const app = require('./src/app');
const { initSocket } = require('./src/config/socket');
const { testConnection } = require('./src/config/db');
const logger = require('./src/utils/logger');

const PORT = process.env.PORT || 10000;

const httpServer = http.createServer(app);

// Attach Socket.io to the HTTP server
initSocket(httpServer);

// Start server
async function bootstrap() {
  try {
    await testConnection();
    httpServer.listen(PORT, () => {
      logger.info(`AgriLink API running on port ${PORT} [${process.env.NODE_ENV}]`);
    });
  } catch (err) {
    logger.error('Failed to start server:', err);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received. Shutting down gracefully...');
  httpServer.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

bootstrap();
