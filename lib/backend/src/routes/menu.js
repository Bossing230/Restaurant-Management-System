// ════════════════════════════════════════════════════════════
// src/routes/menu.js
// ════════════════════════════════════════════════════════════
const menuRouter = express.Router();
const { menuRules } = require('../middleware/validation');

menuRouter.get('/', async (req, res, next) => {
  try {
    const { category } = req.query;
    const { cached: c } = require('../config/redis');
    const data = await c(`menu:all:${category||'all'}`, 300, async () => {
      let sql = `SELECT m.*, c.name AS category FROM menu_items m JOIN categories c ON m.category_id = c.id WHERE 1=1`;
      const params = [];
      if (category) { params.push(category); sql += ` AND c.name = $1`; }
      sql += ' ORDER BY c.sort_order, m.name';
      const { rows } = await query(sql, params);
      return rows;
    });
    res.json({ success: true, data });
  } catch (err) { next(err); }
});

menuRouter.get('/categories', async (req, res, next) => {
  try {
    const { rows } = await query('SELECT * FROM categories ORDER BY sort_order, name');
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

menuRouter.post('/', authorize('admin','manager'), menuRules, validate, async (req, res, next) => {
  try {
    const { name, category_id, price, description, available = true } = req.body;
    const { rows } = await query(
      `INSERT INTO menu_items (name, category_id, price, description, available)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [name, category_id, price, description, available]
    );
    await invalidatePattern('menu:all:*');
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

menuRouter.put('/:id', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { name, category_id, price, description, available } = req.body;
    const { rows } = await query(
      `UPDATE menu_items SET name=COALESCE($1,name), category_id=COALESCE($2,category_id),
       price=COALESCE($3,price), description=COALESCE($4,description),
       available=COALESCE($5,available), updated_at=NOW() WHERE id=$6 RETURNING *`,
      [name, category_id, price, description, available, req.params.id]
    );
    if (!rows[0]) return next(new AppError('Item not found', 404));
    await invalidatePattern('menu:all:*');
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

menuRouter.delete('/:id', authorize('admin'), async (req, res, next) => {
  try {
    const { rows } = await query(
      `UPDATE menu_items SET available=false, updated_at=NOW() WHERE id=$1 RETURNING id`,
      [req.params.id]
    );
    if (!rows[0]) return next(new AppError('Item not found', 404));
    await invalidatePattern('menu:all:*');
    res.json({ success: true, message: 'Item deactivated' });
  } catch (err) { next(err); }
});