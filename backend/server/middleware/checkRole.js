'use strict';

/**
 * Role-based access control middleware.
 *
 * Usage:
 *   router.get('/admin', authenticate, checkRole('admin', 'superadmin'), handler)
 *
 * Accepts one or more allowed role strings. Returns 403 if req.user.role
 * is not in the allowed set. Must be used after authenticate middleware.
 *
 * Role hierarchy (for reference — enforced per-route, not globally):
 *   superadmin > admin > client
 *
 * @param {...string} allowedRoles - Roles permitted to access the route
 */
function checkRole(...allowedRoles) {
  return function (req, res, next) {
    if (!req.user || !req.user.role) {
      return res.status(401).json({ message: 'No autenticado.' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Acceso denegado. Permisos insuficientes.' });
    }

    next();
  };
}

module.exports = checkRole;
