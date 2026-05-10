const express = require('express');
const { query } = require('../config/database');
const { AppError, authorize } = require('../middleware/auth');

const reportsRouter = express.Router();

reportsRouter.get('/sales', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { range = 'weekly' } = req.query;
    const fmts = { daily:'HH24:00', weekly:'Dy', monthly:'Mon DD' };
    const ints = { daily:'1 day',  weekly:'6 days', monthly:'29 days' };
    const fmt  = fmts[range] || 'Dy';
    const interval = ints[range] || '6 days';
    const { rows } = await query(`
      SELECT TO_CHAR(created_at,'${fmt}') AS label,
             COALESCE(SUM(total),0) AS amount,
             COUNT(*) AS order_count
      FROM orders
      WHERE created_at >= NOW()-INTERVAL '${interval}' AND status!='Cancelled'
      GROUP BY DATE(created_at),1 ORDER BY DATE(created_at)`);
    res.json({ success: true, data: rows.map(r => ({ label: r.label, amount: parseFloat(r.amount), order_count: parseInt(r.order_count) })) });
  } catch (err) { next(err); }
});

reportsRouter.get('/top-items', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT m.name, SUM(oi.quantity) AS quantity_sold, SUM(oi.quantity * oi.unit_price) AS revenue
      FROM order_items oi
      JOIN menu_items m ON oi.menu_item_id = m.id
      JOIN orders     o ON oi.order_id     = o.id
      WHERE o.created_at >= NOW()-INTERVAL '30 days' AND o.status!='Cancelled'
      GROUP BY m.id, m.name ORDER BY quantity_sold DESC LIMIT 10`);
    res.json({ success: true, data: rows.map(r => ({ name: r.name, quantity_sold: parseInt(r.quantity_sold), revenue: parseFloat(r.revenue) })) });
  } catch (err) { next(err); }
});

reportsRouter.get('/summary', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT COALESCE(SUM(total),0)              AS total_revenue,
             COUNT(*)                             AS total_orders,
             ROUND(AVG(total)::numeric,2)         AS avg_order_value,
             COUNT(*) FILTER (WHERE DATE(created_at)=CURRENT_DATE) AS today_orders,
             COALESCE(SUM(total) FILTER (WHERE DATE(created_at)=CURRENT_DATE),0) AS today_revenue
      FROM orders WHERE status!='Cancelled'`);
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

module.exports = reportsRouter;
