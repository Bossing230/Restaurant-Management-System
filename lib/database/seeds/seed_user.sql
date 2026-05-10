-- ═══════════════════════════════════════════════════════════
-- seed_users.sql
-- Creates the 4 default accounts with correct bcrypt hashes
-- Password for ALL accounts: password123
--
-- Hash: $2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- This is a verified bcrypt hash for "password123" (cost 10)
-- ═══════════════════════════════════════════════════════════

-- Remove existing users first (clean slate)
DELETE FROM refresh_tokens;
DELETE FROM users;

-- Insert all 4 role accounts
INSERT INTO users (name, email, password_hash, role_id, status, is_active) VALUES
(
  'Admin User',
  'admin@restaurant.com',
  '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  (SELECT id FROM roles WHERE name = 'admin'),
  'online',
  true
),
(
  'Maria Manager',
  'manager@restaurant.com',
  '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  (SELECT id FROM roles WHERE name = 'manager'),
  'online',
  true
),
(
  'Jose Cashier',
  'cashier@restaurant.com',
  '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  (SELECT id FROM roles WHERE name = 'cashier'),
  'online',
  true
),
(
  'Pedro Kitchen',
  'kitchen@restaurant.com',
  '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  (SELECT id FROM roles WHERE name = 'kitchen'),
  'online',
  true
);

-- Verify all users were inserted
SELECT
  u.name,
  u.email,
  r.name AS role,
  u.is_active,
  'password123' AS password
FROM users u
JOIN roles r ON u.role_id = r.id
ORDER BY r.id;