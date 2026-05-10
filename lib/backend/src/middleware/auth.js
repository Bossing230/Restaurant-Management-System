const jwt = require('jsonwebtoken');

// ── AppError class ────────────────────────────────────────────
class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

// ── JWT Middleware ────────────────────────────────────────────
const authenticate = (req, res, next) => {
  try {
    const JWT_SECRET = process.env.JWT_SECRET || 'restaurantos_jwt_secret_change_this_in_production_2025';
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new AppError('No token provided', 401));
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    next(new AppError('Invalid or expired token', 401));
  }
};

// ── Role-based Authorization ──────────────────────────────────
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new AppError('No user in request', 401));
    }
    if (!allowedRoles.includes(req.user.role)) {
      return next(new AppError('Forbidden: insufficient permissions', 403));
    }
    next();
  };
};

module.exports = { AppError, authenticate, authorize };