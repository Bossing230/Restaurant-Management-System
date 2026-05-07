const express     = require('express');
const cors        = require('cors');
const helmet      = require('helmet');
const morgan      = require('morgan');
const rateLimit   = require('express-rate-limit');
require('dotenv').config();

const app = express();

// ── Middleware ────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

// Global rate limit
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 500 }));

// Stricter limit on auth routes
app.use('/api/v1/auth', rateLimit({ windowMs: 15 * 60 * 1000, max: 20 }));

// ── Routes ────────────────────────────────────────────────────
const { authenticate } = require('./src/middleware/auth');
const API = '/api/v1';

app.use(`${API}/auth`,         require('./src/routes/auth'));
app.use(`${API}/dashboard`,    authenticate, require('./src/routes/dashboard'));
app.use(`${API}/menu`,         authenticate, require('./src/routes/menu'));
app.use(`${API}/orders`,       authenticate, require('./src/routes/orders'));
app.use(`${API}/tables`,       authenticate, require('./src/routes/tables'));
app.use(`${API}/inventory`,    authenticate, require('./src/routes/inventory'));
app.use(`${API}/customers`,    authenticate, require('./src/routes/customers'));
app.use(`${API}/reservations`, authenticate, require('./src/routes/reservations'));
app.use(`${API}/reports`,      authenticate, require('./src/routes/reports'));
app.use(`${API}/staff`,        authenticate, require('./src/routes/staff'));
app.use(`${API}/settings`,     authenticate, require('./src/routes/settings'));

// ── Health check ──────────────────────────────────────────────
app.get('/health', (_, res) =>
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
);

// ── 404 ───────────────────────────────────────────────────────
app.use('*', (_, res) =>
  res.status(404).json({ success: false, message: 'Route not found' })
);

// ── Error handler ─────────────────────────────────────────────
app.use(require('./src/middleware/errorHandler').errorHandler);

// ── Start ─────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`🍽  RestaurantOS API v2 → http://localhost:${PORT}`)
);

module.exports = app;