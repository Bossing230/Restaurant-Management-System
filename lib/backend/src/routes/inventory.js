const express = require('express');
const { query } = require('../config/database');
const { AppError, authorize } = require('../middleware/auth');
const { cached, invalidatePattern } = require('../config/redis');

const inventoryRouter = express.Router();

inventoryRouter.get('/', async (req, res, next) => {
  try {
    const { rows } = await query(`SELECT * FROM inventory ORDER BY category, name`);
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

inventoryRouter.put('/:id', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { stock, max_stock, min_stock, cost_per_unit, supplier } = req.body;
    const { rows } = await query(
      `UPDATE inventory SET
         stock          = COALESCE($1, stock),
         max_stock      = COALESCE($2, max_stock),
         min_stock      = COALESCE($3, min_stock),
         cost_per_unit  = COALESCE($4, cost_per_unit),
         supplier       = COALESCE($5, supplier),
         updated_at     = NOW()
       WHERE id = $6 RETURNING *`,
      [stock, max_stock, min_stock, cost_per_unit, supplier, req.params.id]
    );
    if (!rows[0]) return next(new AppError('Item not found', 404));
    if (stock !== undefined) {
      await query(
        `INSERT INTO inventory_transactions (inventory_id, type, quantity, note, created_by)
         VALUES ($1,'restock',$2,'Manual restock',$3)`,
        [req.params.id, stock, req.user.id]
      );
    }
    await invalidatePattern('dashboard:alerts');
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

inventoryRouter.get('/:id/transactions', async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT it.*, u.name AS user_name FROM inventory_transactions it
       LEFT JOIN users u ON it.created_by = u.id
       WHERE it.inventory_id = $1 ORDER BY it.created_at DESC LIMIT 50`,
      [req.params.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

module.exports = inventoryRouter;
