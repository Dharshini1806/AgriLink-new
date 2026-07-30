const logger = require('../utils/logger');

// Custom error classes
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
  }
}
class NotFoundError    extends AppError { constructor(msg = 'Not found') { super(msg, 404); } }
class UnauthorizedError extends AppError { constructor(msg = 'Unauthorized') { super(msg, 401); } }
class ForbiddenError   extends AppError { constructor(msg = 'Forbidden') { super(msg, 403); } }
class BadRequestError  extends AppError { constructor(msg = 'Bad request') { super(msg, 400); } }
class ConflictError    extends AppError { constructor(msg = 'Conflict') { super(msg, 409); } }

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  // Operational / known errors
  if (err.isOperational) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  // PostgreSQL unique violation
  if (err.code === '23505') {
    const field = err.detail?.match(/\((.+?)\)/)?.[1] || 'field';
    return res.status(409).json({ error: `${field} already exists` });
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    return res.status(400).json({ error: 'Referenced record does not exist' });
  }

  // Multer file size
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'File too large. Maximum 5 MB per image.' });
  }

  // JWT errors (shouldn't reach here but safety net)
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ error: 'Invalid token' });
  }

  // Unknown / unexpected
  logger.error('Unhandled error:', { message: err.message, stack: err.stack, path: req.path });
  res.status(500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
  });
}

module.exports = errorHandler;
module.exports.AppError        = AppError;
module.exports.NotFoundError   = NotFoundError;
module.exports.UnauthorizedError = UnauthorizedError;
module.exports.ForbiddenError  = ForbiddenError;
module.exports.BadRequestError = BadRequestError;
module.exports.ConflictError   = ConflictError;
