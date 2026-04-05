'use strict';

const { verifyToken } = require('../utils/jwt');

/**
 * JWT authentication middleware.
 *
 * Reads `Authorization: Bearer <token>` header, verifies the token,
 * and attaches the decoded payload to `req.user`.
 *
 * Responds 401 if the header is missing or the token is invalid/expired.
 */
function authenticate(req, res, next) {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Token de autenticación requerido.' });
  }

  const token = authHeader.slice(7); // strip "Bearer "

  try {
    const decoded = verifyToken(token);
    req.user = decoded; // { id, email, role, iat, exp }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Token expirado.' });
    }
    return res.status(401).json({ success: false, error: 'Token inválido.' });
  }
}

module.exports = authenticate;
