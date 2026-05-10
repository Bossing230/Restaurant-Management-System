const express = require('express');
const { query } = require('../config/database');
const { AppError, authorize } = require('../middleware/auth');

const settingsRouter = express.Router();

settingsRouter.get('/restaurant', async (req, res, next) => {
  try {
    const { rows } = await query('SELECT * FROM restaurant_settings LIMIT 1');
    res.json({ success: true, data: rows[0] || {} });
  } catch (err) { next(err); }
});

settingsRouter.put('/restaurant', authorize('admin'), async (req, res, next) => {
  try {
    const { name, address, phone, email, tax_rate } = req.body;
    const { rows } = await query(
      `INSERT INTO restaurant_settings (name, address, phone, email, tax_rate)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (id) DO UPDATE
       SET name=$1, address=$2, phone=$3, email=$4, tax_rate=$5, updated_at=NOW()
       RETURNING *`,
      [name, address, phone, email, tax_rate]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

module.exports = settingsRouter;