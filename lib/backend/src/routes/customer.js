const customersRouter = express.Router();

customersRouter.get('/', async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT c.*, COUNT(o.id) AS total_orders,
             COALESCE(SUM(o.total),0) AS total_spent,
             MAX(o.created_at) AS last_visit
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'Completed'
      GROUP BY c.id ORDER BY total_spent DESC`);
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

customersRouter.post('/', async (req, res, next) => {
  try {
    const { name, email, phone } = req.body;
    const { rows } = await query(
      `INSERT INTO customers (name, email, phone) VALUES ($1,$2,$3) RETURNING *`,
      [name, email||null, phone||null]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

customersRouter.get('/:id/orders', async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT id, status, total, created_at, order_type
       FROM orders WHERE customer_id=$1 ORDER BY created_at DESC LIMIT 20`,
      [req.params.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

customersRouter.put('/:id/loyalty', async (req, res, next) => {
  try {
    const { points } = req.body;
    const { rows } = await query(
      `UPDATE customers SET loyalty_points = loyalty_points + $1, updated_at=NOW()
       WHERE id=$2 RETURNING *`,
      [points, req.params.id]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});