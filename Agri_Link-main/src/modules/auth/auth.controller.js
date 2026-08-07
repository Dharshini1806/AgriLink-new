const authService = require('./auth.service');

async function register(req, res, next) {
  try {
    const result = await authService.register(req.body);
    res.status(201).json({ message: 'Registration successful', ...result });
  } catch (err) { next(err); }
}

async function login(req, res, next) {
  try {
    const result = await authService.login(req.body.email, req.body.password);
    res.json(result);
  } catch (err) { next(err); }
}

async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    const tokens = await authService.refreshTokens(refreshToken);
    res.json(tokens);
  } catch (err) { next(err); }
}

async function logout(req, res, next) {
  try {
    const { refreshToken } = req.body;
    await authService.logout(req.user.id, refreshToken);
    res.json({ message: 'Logged out successfully' });
  } catch (err) { next(err); }
}

async function getMe(req, res, next) {
  try {
    const user = await authService.getMe(req.user.id);
    res.json(user);
  } catch (err) { next(err); }
}

async function updateFcmToken(req, res, next) {
  try {
    await authService.updateFcmToken(req.user.id, req.body.fcmToken);
    res.json({ message: 'FCM token updated' });
  } catch (err) { next(err); }
}

async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body;
    const message = await authService.forgotPassword(email);
    res.json({ message });
  } catch (err) { next(err); }
}

async function verifyOtp(req, res, next) {
  try {
    const { email, otp } = req.body;
    const valid = await authService.verifyOtp(email, otp);
    res.json({ valid });
  } catch (err) { next(err); }
}

async function resetPassword(req, res, next) {
  try {
    const { email, otp, password } = req.body;
    const message = await authService.resetPassword(email, otp, password);
    res.json({ message });
  } catch (err) { next(err); }
}

module.exports = {
  register,
  login,
  refresh,
  logout,
  getMe,
  updateFcmToken,
  forgotPassword,
  verifyOtp,
  resetPassword,
};
