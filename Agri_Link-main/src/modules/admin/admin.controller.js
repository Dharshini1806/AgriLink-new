const adminService = require('./admin.service');

async function getDashboard(req, res, next) {
  try { res.json(await adminService.getDashboardStats()); } catch (e) { next(e); }
}
async function listUsers(req, res, next) {
  try { res.json(await adminService.listUsers(req.query)); } catch (e) { next(e); }
}
async function banUser(req, res, next) {
  try {
    const result = await adminService.setUserBanStatus(req.params.id, true, req.body.reason);
    res.json(result);
  } catch (e) { next(e); }
}
async function unbanUser(req, res, next) {
  try {
    const result = await adminService.setUserBanStatus(req.params.id, false);
    res.json(result);
  } catch (e) { next(e); }
}
async function getPendingProducts(req, res, next) {
  try { res.json(await adminService.listPendingProducts(req.query)); } catch (e) { next(e); }
}
async function moderateProduct(req, res, next) {
  try {
    const result = await adminService.moderateProduct(req.params.id, req.body.approve);
    res.json(result);
  } catch (e) { next(e); }
}
async function getRevenue(req, res, next) {
  try {
    res.json(await adminService.getRevenueAnalytics(req.query.from, req.query.to, req.query.groupBy));
  } catch (e) { next(e); }
}
async function getFraudSignals(req, res, next) {
  try { res.json(await adminService.getFraudSignals()); } catch (e) { next(e); }
}

module.exports = { getDashboard, listUsers, banUser, unbanUser, getPendingProducts, moderateProduct, getRevenue, getFraudSignals };
