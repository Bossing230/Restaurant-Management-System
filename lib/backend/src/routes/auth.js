const express  = require('express');
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { AppError } = require('../middleware/auth');
const { authenticate } = require('../middleware/auth');
const { loginRules, validate } = require('../middleware/validation');

const authRouter = express.Router();

const JWT_SECRET         = process.env.JWT_SECRET         || 'dev_secret_change_in_production_min32chars';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret_change_in_production';
const JWT_EXPIRES        = process.env.JWT_EXPIRES_IN     || '15m';

const signAccess  = p => jwt.sign(p, JWT_SECRET,         { expiresIn: JWT_EXPIRES });
const signRefresh = p => jwt.sign(p, JWT_REFRESH_SECRET, { expiresIn: '7d' });

// POST /auth/login
authRouter.post('/login', loginRules, validate, async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { rows } = await query(
      `SELECT u.*, r.name AS role_name
       FROM users u JOIN roles r ON u.role_id = r.id
       WHERE u.email = $1 AND u.is_active = true`,
      [email.toLowerCase()]
    );
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return next(new AppError('Invalid credentials', 401));
    }
    const payload      = { id: user.id, email: user.email, role: user.role_name, name: user.name };
    const token        = signAccess(payload);
    const refreshToken = signRefresh({ id: user.id });
    await query(
      `INSERT INTO refresh_tokens (id, user_id, token, expires_at)
       VALUES ($1,$2,$3, NOW() + INTERVAL '7 days')`,
      [uuidv4(), user.id, refreshToken]
    );
    await query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);
    res.json({
      success: true,
      data: {
        token, refresh_token: refreshToken,
        user: { id: user.id, name: user.name, email: user.email,
                role: user.role_name, avatar_url: user.avatar_url },
      },
    });
  } catch (err) { next(err); }
});

// POST /auth/refresh
authRouter.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return next(new AppError('Refresh token required', 400));
    jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    const { rows } = await query(
      `SELECT rt.*, u.email, u.name, r.name AS role
       FROM refresh_tokens rt
       JOIN users u ON rt.user_id = u.id
       JOIN roles  r ON u.role_id  = r.id
       WHERE rt.token = $1 AND rt.expires_at > NOW() AND rt.revoked = false`,
      [refreshToken]
    );
    if (!rows[0]) return next(new AppError('Invalid or expired refresh token', 401));
    const { user_id, email, name, role } = rows[0];
    const newToken = signAccess({ id: user_id, email, name, role });
    res.json({ success: true, data: { token: newToken } });
  } catch { next(new AppError('Invalid refresh token', 401)); }
});

// POST /auth/logout
authRouter.post('/logout', authenticate, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await query(
        'UPDATE refresh_tokens SET revoked = true WHERE token = $1 AND user_id = $2',
        [refreshToken, req.user.id]
      );
    }
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) { next(err); }
});

// GET /auth/me
authRouter.get('/me', authenticate, async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT u.id, u.name, u.email, u.avatar_url, u.status, u.created_at, r.name AS role
       FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = $1`,
      [req.user.id]
    );
    if (!rows[0]) return next(new AppError('User not found', 404));
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});
