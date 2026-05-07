-- ═══════════════════════════════════════════════════════════
-- RestaurantOS v2 — PostgreSQL Schema (16 tables)
-- ═══════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── 1. Roles ──────────────────────────────────────────────────
CREATE TABLE roles (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
);
INSERT INTO roles (name) VALUES ('admin'),('manager'),('cashier'),('kitchen');

-- ── 2. Users ──────────────────────────────────────────────────
CREATE TABLE users (
  id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role_id       INT          NOT NULL REFERENCES roles(id),
  avatar_url    TEXT,
  status        VARCHAR(20)  DEFAULT 'online'
                  CHECK (status IN ('online','break','off')),
  is_active     BOOLEAN      DEFAULT true,
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  DEFAULT NOW()
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role  ON users(role_id);

-- ── 3. Refresh tokens ─────────────────────────────────────────
CREATE TABLE refresh_tokens (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      TEXT        NOT NULL UNIQUE,
  revoked    BOOLEAN     DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_rt_user  ON refresh_tokens(user_id);
CREATE INDEX idx_rt_token ON refresh_tokens(token);

-- ── 4. Categories ─────────────────────────────────────────────
CREATE TABLE categories (
  id         SERIAL      PRIMARY KEY,
  name       VARCHAR(80) NOT NULL UNIQUE,
  icon       VARCHAR(50),
  sort_order INT         DEFAULT 0
);
INSERT INTO categories (name, sort_order) VALUES
  ('Main Course',1),('Noodles',2),('Soups',3),
  ('Desserts',4),('Drinks',5),('Appetizers',6);

-- ── 5. Menu items ─────────────────────────────────────────────
CREATE TABLE menu_items (
  id          SERIAL         PRIMARY KEY,
  name        VARCHAR(150)   NOT NULL,
  description TEXT,
  category_id INT            NOT NULL REFERENCES categories(id),
  price       NUMERIC(10,2)  NOT NULL CHECK (price >= 0),
  image_url   TEXT,
  available   BOOLEAN        DEFAULT true,
  created_at  TIMESTAMPTZ    DEFAULT NOW(),
  updated_at  TIMESTAMPTZ    DEFAULT NOW()
);
CREATE INDEX idx_menu_cat       ON menu_items(category_id);
CREATE INDEX idx_menu_available ON menu_items(available);
CREATE INDEX idx_menu_name_trgm ON menu_items USING GIN (name gin_trgm_ops);

INSERT INTO menu_items (name, category_id, price, description) VALUES
  ('Beef Sinigang',    1, 185.00, 'Sour tamarind soup with beef'),
  ('Chicken Adobo',    1, 165.00, 'Classic braised chicken'),
  ('Pork Sisig',       1, 175.00, 'Sizzling chopped pork'),
  ('Kare-Kare',        1, 220.00, 'Oxtail in peanut sauce'),
  ('Pancit Canton',    2, 145.00, 'Stir-fried egg noodles'),
  ('Palabok',          2, 155.00, 'Rice noodles with shrimp sauce'),
  ('Halo-Halo',        4,  95.00, 'Mixed shaved ice dessert'),
  ('Leche Flan',       4,  75.00, 'Caramel egg custard'),
  ('Buko Pandan',      4,  85.00, 'Coconut pandan jelly dessert'),
  ('Sago Gulaman',     5,  55.00, 'Sweet tapioca drink'),
  ('Calamansi Juice',  5,  65.00, 'Fresh citrus juice'),
  ('Halo-Halo Shake',  5, 115.00, 'Blended halo-halo shake'),
  ('Lumpiang Shanghai',6, 120.00, 'Crispy pork spring rolls');

-- ── 6. Customers ──────────────────────────────────────────────
CREATE TABLE customers (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  name           VARCHAR(100) NOT NULL,
  email          VARCHAR(150) UNIQUE,
  phone          VARCHAR(20),
  loyalty_points INT         DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_cust_email ON customers(email);

-- ── 7. Restaurant tables ──────────────────────────────────────
CREATE TABLE restaurant_tables (
  id       SERIAL      PRIMARY KEY,
  number   VARCHAR(10) NOT NULL UNIQUE,
  capacity INT         DEFAULT 4,
  status   VARCHAR(20) DEFAULT 'available'
             CHECK (status IN ('available','occupied','reserved','cleaning')),
  section  VARCHAR(50)
);
INSERT INTO restaurant_tables (number, capacity, section) VALUES
  ('T1',4,'indoor'), ('T2',4,'indoor'), ('T3',6,'indoor'),
  ('T4',2,'indoor'), ('T5',4,'indoor'), ('T6',6,'outdoor'),
  ('T7',4,'outdoor'),('T8',8,'private'),('T9',2,'indoor'),
  ('T10',4,'outdoor');

-- ── 8. Reservations ───────────────────────────────────────────
CREATE TABLE reservations (
  id          SERIAL      PRIMARY KEY,
  customer_id UUID        REFERENCES customers(id),
  table_id    INT         REFERENCES restaurant_tables(id),
  reserved_at TIMESTAMPTZ NOT NULL,
  party_size  INT         DEFAULT 2,
  status      VARCHAR(20) DEFAULT 'confirmed'
                CHECK (status IN ('confirmed','seated','completed','cancelled','no-show')),
  notes       TEXT,
  created_by  UUID        REFERENCES users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_res_date   ON reservations(reserved_at);
CREATE INDEX idx_res_status ON reservations(status);

-- ── 9. Orders ─────────────────────────────────────────────────
CREATE TABLE orders (
  id             SERIAL        PRIMARY KEY,
  status         VARCHAR(20)   NOT NULL DEFAULT 'Pending'
                   CHECK (status IN ('Pending','Preparing','Ready','Served','Completed','Cancelled')),
  order_type     VARCHAR(20)   NOT NULL
                   CHECK (order_type IN ('Dine-in','Takeout','Delivery')),
  payment_method VARCHAR(20)   NOT NULL DEFAULT 'Cash'
                   CHECK (payment_method IN ('Cash','Card','E-wallet')),
  subtotal       NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax            NUMERIC(12,2) NOT NULL DEFAULT 0,
  total          NUMERIC(12,2) NOT NULL DEFAULT 0,
  table_number   VARCHAR(10),
  customer_id    UUID          REFERENCES customers(id),
  reservation_id INT           REFERENCES reservations(id),
  created_by     UUID          NOT NULL REFERENCES users(id),
  notes          TEXT,
  created_at     TIMESTAMPTZ   DEFAULT NOW(),
  updated_at     TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_created_by ON orders(created_by);
CREATE INDEX idx_orders_date       ON orders(created_at);

-- ── 10. Order items ───────────────────────────────────────────
CREATE TABLE order_items (
  id           SERIAL        PRIMARY KEY,
  order_id     INT           NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id INT           NOT NULL REFERENCES menu_items(id),
  quantity     INT           NOT NULL CHECK (quantity > 0),
  unit_price   NUMERIC(10,2) NOT NULL,
  notes        TEXT
);
CREATE INDEX idx_oi_order_id ON order_items(order_id);
CREATE INDEX idx_oi_item_id  ON order_items(menu_item_id);

-- ── 11. Payments ──────────────────────────────────────────────
CREATE TABLE payments (
  id              UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id        INT           NOT NULL UNIQUE REFERENCES orders(id),
  method          VARCHAR(20)   NOT NULL,
  amount          NUMERIC(12,2) NOT NULL,
  amount_tendered NUMERIC(12,2),
  change_amount   NUMERIC(12,2),
  reference_no    VARCHAR(100),
  status          VARCHAR(20)   DEFAULT 'completed',
  processed_by    UUID          REFERENCES users(id),
  processed_at    TIMESTAMPTZ   DEFAULT NOW()
);

-- ── 12. Inventory ─────────────────────────────────────────────
CREATE TABLE inventory (
  id            SERIAL         PRIMARY KEY,
  name          VARCHAR(100)   NOT NULL,
  category      VARCHAR(80)    NOT NULL,
  stock         NUMERIC(10,3)  NOT NULL DEFAULT 0,
  max_stock     NUMERIC(10,3)  NOT NULL DEFAULT 100,
  min_stock     NUMERIC(10,3)  NOT NULL DEFAULT 10,
  unit          VARCHAR(20)    NOT NULL DEFAULT 'kg',
  cost_per_unit NUMERIC(10,2)  DEFAULT 0,
  supplier      VARCHAR(150),
  updated_at    TIMESTAMPTZ    DEFAULT NOW()
);
INSERT INTO inventory (name, category, stock, max_stock, min_stock, unit, cost_per_unit) VALUES
  ('Beef',        'Meat',    12, 30, 5,  'kg',   450),
  ('Chicken',     'Meat',     8, 25, 5,  'kg',   220),
  ('Pork',        'Meat',     3, 20, 5,  'kg',   280),
  ('Rice',        'Grains',  45, 50, 10, 'kg',    55),
  ('Coconut Milk','Pantry',   2, 10, 3,  'cans',  65),
  ('Vegetables',  'Produce',  6, 15, 4,  'kg',    80),
  ('Soy Sauce',   'Pantry',   4,  8, 2,  'btl',   75),
  ('Sugar',       'Pantry',  18, 25, 5,  'kg',    65);

-- ── 13. Inventory requirements (recipes) ──────────────────────
CREATE TABLE inventory_requirements (
  id              SERIAL        PRIMARY KEY,
  menu_item_id    INT           NOT NULL REFERENCES menu_items(id),
  inventory_id    INT           NOT NULL REFERENCES inventory(id),
  quantity_needed NUMERIC(8,3)  NOT NULL,
  UNIQUE(menu_item_id, inventory_id)
);
INSERT INTO inventory_requirements (menu_item_id, inventory_id, quantity_needed) VALUES
  (1,1,0.25),(1,6,0.15),  -- Beef Sinigang: beef + vegetables
  (2,2,0.20),(2,7,0.05),  -- Chicken Adobo: chicken + soy sauce
  (3,3,0.25),             -- Pork Sisig:    pork
  (4,1,0.30),(4,6,0.20),(4,5,0.50), -- Kare-Kare
  (5,6,0.12),(5,7,0.04);  -- Pancit Canton: vegetables + soy sauce

-- ── 14. Inventory transactions ────────────────────────────────
CREATE TABLE inventory_transactions (
  id           SERIAL        PRIMARY KEY,
  inventory_id INT           NOT NULL REFERENCES inventory(id),
  type         VARCHAR(20)   NOT NULL
                 CHECK (type IN ('deduct','restock','adjustment','waste')),
  quantity     NUMERIC(10,3) NOT NULL,
  reference_id INT,
  note         TEXT,
  created_by   UUID          REFERENCES users(id),
  created_at   TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX idx_inv_tx_inv ON inventory_transactions(inventory_id);

-- ── 15. Restaurant settings (singleton) ───────────────────────
CREATE TABLE restaurant_settings (
  id       INT     PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  name     VARCHAR(150) DEFAULT 'My Restaurant',
  address  TEXT,
  phone    VARCHAR(30),
  email    VARCHAR(150),
  tax_rate NUMERIC(5,4) DEFAULT 0.12,
  currency VARCHAR(5)   DEFAULT '₱',
  logo_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO restaurant_settings (name, phone, tax_rate)
  VALUES ('RestaurantOS Demo', '+63-917-000-0000', 0.12);

-- ── 16. Role permissions ──────────────────────────────────────
CREATE TABLE role_permissions (
  id         SERIAL      PRIMARY KEY,
  role_id    INT         NOT NULL REFERENCES roles(id),
  permission VARCHAR(100) NOT NULL,
  UNIQUE(role_id, permission)
);
INSERT INTO role_permissions (role_id, permission) VALUES
  (1,'*'),
  (2,'view_dashboard'),(2,'manage_orders'),(2,'manage_inventory'),
  (2,'view_reports'),(2,'manage_reservations'),
  (3,'create_orders'),(3,'process_payments'),(3,'view_dashboard'),
  (4,'view_orders'),(4,'update_order_status');

-- ── Seed users (password: password123) ───────────────────────
-- Hash generated with bcrypt cost factor 10
INSERT INTO users (name, email, password_hash, role_id) VALUES
  ('Admin User',    'admin@restaurant.com',   '$2b$10$rOJYMTbF3y5lLfwJJn1PGOexFJMKbL/eqUWLqU7UZBU5kpY9hDpzS', 1),
  ('Maria Manager', 'manager@restaurant.com', '$2b$10$rOJYMTbF3y5lLfwJJn1PGOexFJMKbL/eqUWLqU7UZBU5kpY9hDpzS', 2),
  ('Jose Cashier',  'cashier@restaurant.com', '$2b$10$rOJYMTbF3y5lLfwJJn1PGOexFJMKbL/eqUWLqU7UZBU5kpY9hDpzS', 3),
  ('Pedro Kitchen', 'kitchen@restaurant.com', '$2b$10$rOJYMTbF3y5lLfwJJn1PGOexFJMKbL/eqUWLqU7UZBU5kpY9hDpzS', 4);

-- ── updated_at trigger ────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users        BEFORE UPDATE ON users           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_menu         BEFORE UPDATE ON menu_items      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_orders       BEFORE UPDATE ON orders          FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_customers    BEFORE UPDATE ON customers       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_inventory    BEFORE UPDATE ON inventory       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_reservations BEFORE UPDATE ON reservations    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_settings     BEFORE UPDATE ON restaurant_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();