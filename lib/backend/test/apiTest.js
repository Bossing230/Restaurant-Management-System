const request = require('supertest');
const app     = require('../server');

const BASE = '/api/v1';
let token   = '';
let orderId = '';

// ── Health check ──────────────────────────────────────────────
describe('GET /health', () => {
  it('returns ok status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

// ── Auth ─────────────────────────────────────────────────────
describe('POST /auth/login', () => {
  it('returns 422 for missing body', async () => {
    const res = await request(app).post(`${BASE}/auth/login`).send({});
    expect(res.statusCode).toBe(422);
    expect(res.body.success).toBe(false);
  });

  it('returns 401 for wrong credentials', async () => {
    const res = await request(app).post(`${BASE}/auth/login`)
      .send({ email: 'wrong@email.com', password: 'wrongpass' });
    expect(res.statusCode).toBe(401);
  });

  it('returns 200 and token for valid admin credentials', async () => {
    const res = await request(app).post(`${BASE}/auth/login`)
      .send({ email: 'admin@restaurant.com', password: 'password123' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.role).toBe('admin');
    token = res.body.data.token;
  });
});

// ── Dashboard ─────────────────────────────────────────────────
describe('GET /dashboard/summary', () => {
  it('returns 401 without token', async () => {
    const res = await request(app).get(`${BASE}/dashboard/summary`);
    expect(res.statusCode).toBe(401);
  });

  it('returns summary metrics with valid token', async () => {
    const res = await request(app)
      .get(`${BASE}/dashboard/summary`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.total_orders).toBeDefined();
  });
});

// ── Menu ─────────────────────────────────────────────────────
describe('GET /menu', () => {
  it('returns menu items list', async () => {
    const res = await request(app)
      .get(`${BASE}/menu`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('filters by category', async () => {
    const res = await request(app)
      .get(`${BASE}/menu?category=Main Course`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
  });
});

// ── Orders ───────────────────────────────────────────────────
describe('POST /orders', () => {
  it('returns 422 for empty items array', async () => {
    const res = await request(app)
      .post(`${BASE}/orders`)
      .set('Authorization', `Bearer ${token}`)
      .send({ items: [], order_type: 'Dine-in', payment_method: 'Cash' });
    expect(res.statusCode).toBe(422);
  });

  it('creates an order successfully', async () => {
    const res = await request(app)
      .post(`${BASE}/orders`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        items: [{ menu_item_id: 1, quantity: 2 }],
        order_type: 'Dine-in',
        payment_method: 'Cash',
        table_number: 'T1',
      });
    expect(res.statusCode).toBe(201);
    expect(res.body.data.id).toBeDefined();
    orderId = res.body.data.id;
  });
});

describe('PUT /orders/:id/status', () => {
  it('updates order status', async () => {
    if (!orderId) return;
    const res = await request(app)
      .put(`${BASE}/orders/${orderId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'Preparing' });
    expect(res.statusCode).toBe(200);
    expect(res.body.data.status).toBe('Preparing');
  });
});

// ── Tables ───────────────────────────────────────────────────
describe('GET /tables', () => {
  it('returns all tables', async () => {
    const res = await request(app)
      .get(`${BASE}/tables`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });
});

// ── Inventory ─────────────────────────────────────────────────
describe('GET /inventory', () => {
  it('returns inventory list', async () => {
    const res = await request(app)
      .get(`${BASE}/inventory`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});

// ── Reports ───────────────────────────────────────────────────
describe('GET /reports/summary', () => {
  it('returns summary for admin', async () => {
    const res = await request(app)
      .get(`${BASE}/reports/summary`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data.total_revenue).toBeDefined();
  });
});