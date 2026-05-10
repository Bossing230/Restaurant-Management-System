
// ════════════════════════════════════════════════════════════
// src/routes/dashboard.js
// ════════════════════════════════════════════════════════════
const express = require('express');
const { query } = require('../config/database');
const dashRouter = express.Router();
const { cached, invalidatePattern } = require('../config/redis');


dashRouter.get('/summary', async (req, res, next) => {
  try {
    const { role, id } = req.user;
    const roleFilter = role === 'cashier' ? `AND o.created_by = '${id}'` : '';
    const data = await cached(`dashboard:summary:${role}:${id}`, 60, async () => {
      const [salesRow, ordersRow, tablesRow, stockRow] = await Promise.all([
        query(`SELECT COALESCE(SUM(CASE WHEN DATE(o.created_at)=CURRENT_DATE THEN o.total END),0) AS today_sales,
                      COALESCE(SUM(CASE WHEN DATE(o.created_at)=CURRENT_DATE-1 THEN o.total END),0) AS yesterday_sales
               FROM orders o WHERE o.status != 'Cancelled' ${roleFilter}`),
        query(`SELECT COUNT(*) FILTER (WHERE DATE(created_at)=CURRENT_DATE) AS total_orders,
                      COUNT(*) FILTER (WHERE status IN ('Pending','Preparing') AND DATE(created_at)=CURRENT_DATE) AS pending_orders
               FROM orders WHERE 1=1 ${roleFilter}`),
        query(`SELECT COUNT(*) FILTER (WHERE status='available') AS available_tables,
                      COUNT(*) FILTER (WHERE status='occupied')  AS occupied_tables
               FROM restaurant_tables`),
        query(`SELECT COUNT(*) AS low_stock FROM inventory WHERE stock < (max_stock * 0.3)`),
      ]);
      const today     = parseFloat(salesRow.rows[0].today_sales);
      const yesterday = parseFloat(salesRow.rows[0].yesterday_sales);
      const pct = yesterday > 0 ? ((today - yesterday) / yesterday * 100) : 0;
      return {
        total_sales:          today,
        sales_change_percent: Math.round(pct * 10) / 10,
        total_orders:         parseInt(ordersRow.rows[0].total_orders),
        pending_orders:       parseInt(ordersRow.rows[0].pending_orders),
        available_tables:     parseInt(tablesRow.rows[0].available_tables),
        occupied_tables:      parseInt(tablesRow.rows[0].occupied_tables),
        low_stock_items:      parseInt(stockRow.rows[0].low_stock),
      };
    });
    res.json({ success: true, data });
  } catch (err) { next(err); }
});

dashRouter.get('/sales', async (req, res, next) => {
  try {
    const { range = 'weekly' } = req.query;
    const data = await cached(`dashboard:sales:${range}`, 120, async () => {
      const sqls = {
        daily:   `SELECT TO_CHAR(created_at,'HH24:00') AS label, COALESCE(SUM(total),0) AS amount, COUNT(*) AS order_count FROM orders WHERE DATE(created_at)=CURRENT_DATE AND status!='Cancelled' GROUP BY 1 ORDER BY 1`,
        weekly:  `SELECT TO_CHAR(created_at,'Dy') AS label, COALESCE(SUM(total),0) AS amount, COUNT(*) AS order_count FROM orders WHERE created_at >= CURRENT_DATE-6 AND status!='Cancelled' GROUP BY DATE(created_at),1 ORDER BY DATE(created_at)`,
        monthly: `SELECT TO_CHAR(created_at,'Mon DD') AS label, COALESCE(SUM(total),0) AS amount, COUNT(*) AS order_count FROM orders WHERE created_at >= CURRENT_DATE-29 AND status!='Cancelled' GROUP BY DATE(created_at),1 ORDER BY DATE(created_at)`,
      };
      const sql = sqls[range];
      if (!sql) return [];
      const { rows } = await query(sql);
      return rows.map(r => ({ label: r.label, amount: parseFloat(r.amount), order_count: parseInt(r.order_count) }));
    });
    res.json({ success: true, data });
  } catch (err) { next(err); }
});

dashRouter.get('/top-items', async (req, res, next) => {
  try {
    const data = await cached('dashboard:top-items', 300, async () => {
      const { rows } = await query(`
        SELECT m.name, SUM(oi.quantity) AS quantity_sold, SUM(oi.quantity * oi.unit_price) AS revenue
        FROM order_items oi
        JOIN menu_items m ON oi.menu_item_id = m.id
        JOIN orders     o ON oi.order_id     = o.id
        WHERE o.created_at >= CURRENT_DATE-6 AND o.status != 'Cancelled'
        GROUP BY m.id, m.name ORDER BY quantity_sold DESC LIMIT 10`);
      return rows.map(r => ({ name: r.name, quantity_sold: parseInt(r.quantity_sold), revenue: parseFloat(r.revenue) }));
    });
    res.json({ success: true, data });
  } catch (err) { next(err); }
});

dashRouter.get('/alerts', async (req, res, next) => {
  try {
    const data = await cached('dashboard:alerts', 30, async () => {
      const [stockRes, staleRes] = await Promise.all([
        query(`SELECT name, stock, max_stock, unit FROM inventory WHERE stock < (max_stock * 0.3) ORDER BY (stock::float/max_stock) LIMIT 5`),
        query(`SELECT COUNT(*) AS cnt FROM orders WHERE status='Pending' AND created_at < NOW()-INTERVAL '15 minutes'`),
      ]);
      const alerts = [];
      stockRes.rows.forEach(i => {
        const pct = Math.round((i.stock / i.max_stock) * 100);
        alerts.push({ type: pct < 15 ? 'high' : 'medium', title: `Low stock: ${i.name}`, description: `${i.stock} ${i.unit} remaining (${pct}%)` });
      });
      const stale = parseInt(staleRes.rows[0].cnt);
      if (stale > 0) alerts.push({ type: 'medium', title: 'Stale pending orders', description: `${stale} order${stale > 1 ? 's' : ''} waiting over 15 minutes` });
      return alerts;
    });
    res.json({ success: true, data });
  } catch (err) { next(err); }
});
module.exports = dashRouter;

