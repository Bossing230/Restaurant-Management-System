const { AppError } = require('./auth');

const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const isDev      = process.env.NODE_ENV === 'development';

  // Operational errors: send clean message
  if (err.isOperational) {
    return res.status(statusCode).json({
      success: false,
      message: err.message,
    });
  }

  // Programming / unknown errors: log full stack in dev
  console.error('UNHANDLED ERROR:', err);
  res.status(statusCode).json({
    success: false,
    message: isDev ? err.message : 'Internal server error',
    ...(isDev && { stack: err.stack }),
  });
};

module.exports = { errorHandler, AppError };