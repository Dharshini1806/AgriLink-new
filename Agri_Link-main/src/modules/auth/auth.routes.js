const express = require('express');
const rateLimit = require('express-rate-limit');
const Joi = require('joi');
const controller = require('./auth.controller');
const verifyToken = require('../../middleware/auth');
const validate = require('../../middleware/validate');

const router = express.Router();

// Strict rate limit for auth endpoints (login/register)
const authLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 10,
  message: { error: 'Too many auth attempts. Try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// More permissive rate limit for OTP / password reset flow
const otpLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.OTP_RATE_LIMIT_MAX) || 20,
  message: { error: 'Too many password reset attempts. Try again in 15 minutes.' },
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

const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().lowercase().required(),
});

const verifyOtpSchema = Joi.object({
  email: Joi.string().email().lowercase().required(),
  otp:   Joi.string().length(6).pattern(/^\d+$/).message('OTP must be a 6-digit number').required(),
});

const resetPasswordSchema = Joi.object({
  email:    Joi.string().email().lowercase().required(),
  otp:      Joi.string().length(6).pattern(/^\d+$/).message('OTP must be a 6-digit number').required(),
  password: Joi.string().min(8).max(72)
               .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
               .message('Password must contain uppercase, lowercase, and a digit')
               .required(),
});

router.post('/register', authLimiter, validate(registerSchema), controller.register);
router.post('/login',    authLimiter, validate(loginSchema),    controller.login);
router.post('/refresh',  validate(refreshSchema), controller.refresh);
router.post('/logout',   verifyToken, controller.logout);
router.get('/me',        verifyToken, controller.getMe);
router.patch('/fcm-token', verifyToken, validate(fcmSchema), controller.updateFcmToken);
router.post('/forgot-password', otpLimiter, validate(forgotPasswordSchema), controller.forgotPassword);
router.post('/verify-otp',      otpLimiter, validate(verifyOtpSchema),      controller.verifyOtp);
router.post('/reset-password',  otpLimiter, validate(resetPasswordSchema),  controller.resetPassword);

module.exports = router;
