

// ════════════════════════════════════════════════════════════
// src/routes/orders.js
// ════════════════════════════════════════════════════════════
const express = require('express');
const { query, withTransaction } = require('../config/database');
const { authorize } = require('../middleware/auth');
const { orderRules, validate } = require('../middleware/validation');
const { AppError } = require('../middleware/auth');
const TAX = 0.12;

const ordersRouter = express.Router();

ordersRouter.get('/', async (req, res, next) => {
  try {
    const { status, limit = 50, offset = 0, date, table_number } = req.query;
    const { role, id } = req.user;
    let sql = `
      SELECT o.id, o.status, o.order_type, o.payment_method, o.subtotal, o.tax, o.total,
             o.table_number, o.notes, o.created_at, o.updated_at, u.name AS created_by_name,
             COUNT(oi.id) AS item_count,
             JSON_AGG(JSON_BUILD_OBJECT('name',m.name,'qty',oi.quantity,'unit_price',oi.unit_price) ORDER BY oi.id) AS items
      FROM orders o
      LEFT JOIN users      u  ON o.created_by      = u.id
      LEFT JOIN order_items oi ON o.id             = oi.order_id
      LEFT JOIN menu_items m  ON oi.menu_item_id   = m.id
      WHERE 1=1`;
    const params = [];
    if (status && status !== 'active') { params.push(status); sql += ` AND o.status = $${params.length}`; }
    if (status === 'active')            sql += ` AND o.status IN ('Pending','Preparing','Ready','Served')`;
    if (date)         { params.push(date);         sql += ` AND DATE(o.created_at) = $${params.length}`; }
    if (table_number) { params.push(table_number); sql += ` AND o.table_number = $${params.length}`; }
    if (role === 'cashier') { params.push(id); sql += ` AND o.created_by = $${params.length}`; }
    sql += ` GROUP BY o.id, u.name ORDER BY o.created_at DESC LIMIT $${params.length+1} OFFSET $${params.length+2}`;
    params.push(parseInt(limit), parseInt(offset));
    const { rows } = await query(sql, params);
    res.json({ success: true, data: rows, meta: { limit, offset } });
  } catch (err) { next(err); }
});

ordersRouter.post('/', orderRules, validate, async (req, res, next) => {
  try {
    const { items, order_type, payment_method, table_number, customer_id, notes } = req.body;
    const { rows: menuItems } = await query(
      `SELECT id, price FROM menu_items WHERE id = ANY($1) AND available = true`,
      [items.map(i => i.menu_item_id)]
    );
    if (menuItems.length !== [...new Set(items.map(i => i.menu_item_id))].length) {
      return next(new AppError('One or more items unavailable', 400));
    }
    const priceMap = Object.fromEntries(menuItems.map(m => [m.id, parseFloat(m.price)]));
    const subtotal = items.reduce((s, i) => s + priceMap[i.menu_item_id] * i.quantity, 0);
    const tax      = subtotal * TAX;
    const total    = subtotal + tax;
    const order = await withTransaction(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO orders (status, order_type, payment_method, subtotal, tax, total, table_number, customer_id, created_by, notes)
         VALUES ('Pending',$1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
        [order_type, payment_method, subtotal, tax, total, table_number||null, customer_id||null, req.user.id, notes||null]
      );
      const order = rows[0];
      for (const item of items) {
        await client.query(
          `INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price) VALUES ($1,$2,$3,$4)`,
          [order.id, item.menu_item_id, item.quantity, priceMap[item.menu_item_id]]
        );
        await client.query(
          `UPDATE inventory SET stock = GREATEST(0, stock - (ir.quantity_needed * $2))
           FROM inventory_requirements ir
           WHERE inventory.id = ir.inventory_id AND ir.menu_item_id = $1`,
          [item.menu_item_id, item.quantity]
        );
        await client.query(
          `INSERT INTO inventory_transactions (inventory_id, type, quantity, reference_id, created_by)
           SELECT ir.inventory_id, 'deduct', ir.quantity_needed * $2, $3, $4
           FROM inventory_requirements ir WHERE ir.menu_item_id = $1`,
          [item.menu_item_id, item.quantity, order.id, req.user.id]
        );
      }
      if (table_number) {
        await client.query(`UPDATE restaurant_tables SET status='occupied' WHERE number=$1`, [table_number]);
      }
      return order;
    });
    await invalidatePattern('dashboard:summary:*');
    await invalidatePattern('dashboard:alerts');
    res.status(201).json({ success: true, data: order, message: 'Order created' });
  } catch (err) { next(err); }
});

ordersRouter.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT o.*, u.name AS created_by_name,
              JSON_AGG(JSON_BUILD_OBJECT('name',m.name,'qty',oi.quantity,'unit_price',oi.unit_price)) AS items
       FROM orders o
       LEFT JOIN users       u  ON o.created_by    = u.id
       LEFT JOIN order_items oi ON o.id            = oi.order_id
       LEFT JOIN menu_items  m  ON oi.menu_item_id = m.id
       WHERE o.id = $1 GROUP BY o.id, u.name`,
      [req.params.id]
    );
    if (!rows[0]) return next(new AppError('Order not found', 404));
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

ordersRouter.put('/:id/status', async (req, res, next) => {
  try {
    const { status } = req.body;
    const valid = ['Pending','Preparing','Ready','Served','Completed','Cancelled'];
    if (!valid.includes(status)) return next(new AppError('Invalid status', 400));
    const { rows } = await query(
      `UPDATE orders SET status=$1, updated_at=NOW() WHERE id=$2 RETURNING *`,
      [status, req.params.id]
    );
    if (!rows[0]) return next(new AppError('Order not found', 404));
    if (status === 'Completed' && rows[0].table_number) {
      const { rows: remaining } = await query(
        `SELECT COUNT(*) FROM orders WHERE table_number=$1 AND status IN ('Pending','Preparing','Ready','Served')`,
        [rows[0].table_number]
      );
      if (parseInt(remaining[0].count) === 0) {
        await query(`UPDATE restaurant_tables SET status='available' WHERE number=$1`, [rows[0].table_number]);
      }
    }
    await invalidatePattern('dashboard:summary:*');
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

ordersRouter.delete('/:id', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { rows } = await query(
      `UPDATE orders SET status='Cancelled', updated_at=NOW() WHERE id=$1 AND status='Pending' RETURNING *`,
      [req.params.id]
    );
    if (!rows[0]) return next(new AppError('Order not found or not cancellable', 400));
    res.json({ success: true, message: 'Order cancelled' });
  } catch (err) { next(err); }
});

module.exports = ordersRouter;
