const express = require('express');
const { query } = require('../config/database');
const { AppError } = require('../middleware/auth');

const tablesRouter = express.Router();

tablesRouter.get('/', async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT t.*, o.id AS current_order_id, u.name AS waiter_name
      FROM restaurant_tables t
      LEFT JOIN orders o ON o.table_number = t.number
        AND o.status IN ('Pending','Preparing','Ready','Served')
      LEFT JOIN users u ON o.created_by = u.id
      ORDER BY t.number`);
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

tablesRouter.put('/:id/status', async (req, res, next) => {
  try {
    const { status } = req.body;
    const valid = ['available','occupied','reserved','cleaning'];
    if (!valid.includes(status)) return next(new AppError('Invalid status', 400));
    const { rows } = await query(
      `UPDATE restaurant_tables SET status=$1 WHERE id=$2 RETURNING *`,
      [status, req.params.id]
    );
    if (!rows[0]) return next(new AppError('Table not found', 404));
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

module.exports = tablesRouter;
