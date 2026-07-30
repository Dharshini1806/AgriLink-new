/**
 * RBAC middleware factory
 * Usage: requireRole('seller') or requireRole('admin','seller')
 */
const requireRole = (...roles) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  if (!roles.includes(req.user.role)) {
    return res.status(403).json({
      error: `Forbidden: requires role [${roles.join(', ')}], you have [${req.user.role}]`,
    });
  }
  next();
};

module.exports = requireRole;
