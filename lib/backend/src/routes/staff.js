// ════════════════════════════════════════════════════════════
// src/routes/staff.js
// ════════════════════════════════════════════════════════════
const staffRouter = express.Router();

staffRouter.get('/', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT u.id, u.name, u.email, u.avatar_url, u.status, u.is_active,
             r.name AS role,
             COUNT(o.id)              AS orders_handled,
             COALESCE(SUM(o.total),0) AS sales_amount,
             u.last_login
      FROM users u
      JOIN roles r ON u.role_id = r.id
      LEFT JOIN orders o ON o.created_by = u.id AND DATE(o.created_at)=CURRENT_DATE
      WHERE u.is_active = true
      GROUP BY u.id, u.name, u.email, u.avatar_url, u.status, u.is_active, r.name, u.last_login
      ORDER BY u.name`);
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
});

staffRouter.put('/:id/status', authorize('admin','manager'), async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!['online','break','off'].includes(status)) {
      return next(new AppError('Invalid status', 400));
    }
    const { rows } = await query(
      `UPDATE users SET status=$1, updated_at=NOW() WHERE id=$2 RETURNING id, name, status`,
      [status, req.params.id]
    );
    if (!rows[0]) return next(new AppError('User not found', 404));
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
});

staffRouter.put('/:id/deactivate', authorize('admin'), async (req, res, next) => {
  try {
    if (req.params.id === req.user.id) {
      return next(new AppError('Cannot deactivate yourself', 400));
    }
    const { rows } = await query(
      `UPDATE users SET is_active=false, updated_at=NOW() WHERE id=$1 RETURNING id, name`,
      [req.params.id]
    );
    if (!rows[0]) return next(new AppError('User not found', 404));
    res.json({ success: true, message: `${rows[0].name} deactivated` });
  } catch (err) { next(err); }
});