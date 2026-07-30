const express = require('express');
const rateLimit = require('express-rate-limit');
const Joi = require('joi');
const controller = require('./auth.controller');
const verifyToken = require('../../middleware/auth');
const validate = require('../../middleware/validate');

const router = express.Router();

// Strict rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 10,
  message: { error: 'Too many auth attempts. Try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const registerSchema = Joi.object({
  name:      Joi.string().trim().min(2).max(100).required(),
  email:     Joi.string().email().lowercase().required(),
  password:  Joi.string().min(8).max(72)
               .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
               .message('Password must contain uppercase, lowercase, and a digit')
               .required(),
  role:      Joi.string().valid('buyer', 'seller').required(),
  phone:     Joi.string().pattern(/^\+?[\d\s\-]{7,20}$/).optional(),
  latitude:  Joi.number().min(-90).max(90).optional(),
  longitude: Joi.number().min(-180).max(180).optional(),
});

const loginSchema = Joi.object({
  email:    Joi.string().email().required(),
  password: Joi.string().required(),
});

const refreshSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

const fcmSchema = Joi.object({
  fcmToken: Joi.string().required(),
});

router.post('/register', authLimiter, validate(registerSchema), controller.register);
router.post('/login',    authLimiter, validate(loginSchema),    controller.login);
router.post('/refresh',  validate(refreshSchema), controller.refresh);
router.post('/logout',   verifyToken, controller.logout);
router.get('/me',        verifyToken, controller.getMe);
router.patch('/fcm-token', verifyToken, validate(fcmSchema), controller.updateFcmToken);

module.exports = router;
