const { body, validationResult } = require('express-validator');

// ── Run validation and return errors ──────────────────────────
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(e => ({
        field:   e.path,
        message: e.msg,
      })),
    });
  }
  next();
};

// ── Rule sets ─────────────────────────────────────────────────
const loginRules = [
  body('email')
    .isEmail().withMessage('Valid email required')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

const orderRules = [
  body('items')
    .isArray({ min: 1 }).withMessage('At least one item required'),
  body('items.*.menu_item_id')
    .isInt({ min: 1 }).withMessage('Valid menu item ID required'),
  body('items.*.quantity')
    .isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
  body('order_type')
    .isIn(['Dine-in', 'Takeout', 'Delivery']).withMessage('Invalid order type'),
  body('payment_method')
    .isIn(['Cash', 'Card', 'E-wallet']).withMessage('Invalid payment method'),
];

const menuRules = [
  body('name')
    .notEmpty().withMessage('Name is required')
    .isLength({ max: 150 }).withMessage('Name too long'),
  body('category_id')
    .isInt({ min: 1 }).withMessage('Valid category required'),
  body('price')
    .isFloat({ min: 0 }).withMessage('Price must be a positive number'),
];

const reservationRules = [
  body('reserved_at')
    .isISO8601().withMessage('Valid datetime required'),
  body('party_size')
    .isInt({ min: 1 }).withMessage('Party size must be at least 1'),
];

const inventoryRules = [
  body('stock')
    .optional()
    .isFloat({ min: 0 }).withMessage('Stock must be a positive number'),
  body('max_stock')
    .optional()
    .isFloat({ min: 1 }).withMessage('Max stock must be greater than 0'),
];

module.exports = {
  validate,
  loginRules,
  orderRules,
  menuRules,
  reservationRules,
  inventoryRules,
};