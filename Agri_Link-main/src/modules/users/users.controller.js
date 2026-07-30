const userService = require('./users.service');

async function getProfile(req, res, next) {
  try {
    const user = await userService.getProfile(req.user.id);
    res.json(user);
  } catch (err) { next(err); }
}

async function getPublicProfile(req, res, next) {
  try {
    const user = await userService.getProfile(req.params.id);
    res.json(user);
  } catch (err) { next(err); }
}

async function updateProfile(req, res, next) {
  try {
    const user = await userService.updateProfile(
      req.user.id,
      req.body,
      req.file || null
    );
    res.json(user);
  } catch (err) { next(err); }
}

async function getSellerAnalytics(req, res, next) {
  try {
    const analytics = await userService.getSellerAnalytics(req.user.id);
    res.json(analytics);
  } catch (err) { next(err); }
}

module.exports = { getProfile, getPublicProfile, updateProfile, getSellerAnalytics };
