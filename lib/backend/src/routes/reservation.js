const express = require('express');
const { query } = require('../config/database');
const { AppError } = require('../middleware/auth');

const reservationsRouter = express.Router();

reservationsRouter.get('/', async (req, res, next) => {
  try {
    const { date, status } = req.query;
    let sql = `SELECT r.*, c.name AS customer_name, c.phone AS customer_phone, t.number AS table_number
               FROM reservations r
               LEFT JOIN customers         c ON r.customer_id = c.id
               LEFT JOIN restaurant_tables t ON r.table_id    = t.id
               WHERE 1=1`;
    const params = [];
    if (date)   { params.push(date);   sql += ` AND DATE(r.reserved_at) = $${params.length}`; }
    if (status) { params.push(status); sql += ` AND r.status = $${params.length}`; }
    sql += ' ORDER BY r.reserved_at ASC';
    const { rows } = await query(sql, params);
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

reservationsRouter.post('/', async (req, res, next) => {
  try {
    const { customer_id, table_id, reserved_at, party_size, notes } = req.body;
    const { rows } = await query(
      `INSERT INTO reservations (customer_id, table_id, reserved_at, party_size, notes, created_by)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [customer_id||null, table_id||null, reserved_at, party_size||2, notes||null, req.user.id]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

reservationsRouter.put('/:id/status', async (req, res, next) => {
  try {
    const { status } = req.body;
    const { rows } = await query(
      `UPDATE reservations SET status=$1, updated_at=NOW() WHERE id=$2 RETURNING *`,
      [status, req.params.id]
    );
    if (!rows[0]) return next(new AppError('Reservation not found', 404));
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

module.exports = reservationsRouter;
