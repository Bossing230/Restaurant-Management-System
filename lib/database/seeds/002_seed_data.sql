-- ═══════════════════════════════════════════════════════════
-- RestaurantOS v2 — Sample Seed Data
-- Run AFTER 001_schema.sql
-- ═══════════════════════════════════════════════════════════

-- ── Extra menu items ──────────────────────────────────────────
INSERT INTO menu_items (name, category_id, price, description, available) VALUES
  ('Crispy Pata',        1, 385.00, 'Deep-fried pork knuckle',           true),
  ('Sinigang sa Miso',   1, 195.00, 'Miso-based sour soup with pork',    true),
  ('Bicol Express',      1, 165.00, 'Spicy pork with coconut milk',       true),
  ('Lomi',               2, 135.00, 'Thick egg noodle soup',             true),
  ('Sinigang na Hipon',  3, 215.00, 'Sour shrimp soup',                  true),
  ('Bulalo',             3, 295.00, 'Bone marrow beef soup',             true),
  ('Ube Halaya',         4,  85.00, 'Purple yam dessert',                true),
  ('Maja Blanca',        4,  70.00, 'Coconut milk pudding with corn',    true),
  ('Buko Juice',         5,  75.00, 'Fresh young coconut water',         true),
  ('Mango Shake',        5,  95.00, 'Fresh mango blended shake',         true),
  ('Tokwa''t Baboy',     6, 145.00, 'Tofu and pork with vinegar dip',    true),
  ('Chicharon Bulaklak', 6, 165.00, 'Crispy fried pork mesentery',       true)
ON CONFLICT DO NOTHING;

-- ── Sample customers ──────────────────────────────────────────
INSERT INTO customers (id, name, email, phone, loyalty_points) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Maria Santos',   'maria@email.com',  '+63 917 123 4567', 467),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Jose Reyes',     'jose@email.com',   '+63 918 987 6543', 234),
  ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'Ana Cruz',       'ana@email.com',    '+63 919 555 0001', 385),
  ('d4e5f6a7-b8c9-0123-defa-234567890123', 'Pedro Bautista', 'pedro@email.com',  '+63 920 444 0002', 118),
  ('e5f6a7b8-c9d0-1234-efab-345678901234', 'Liza Garcia',    'liza@email.com',   '+63 921 333 0003',  92)
ON CONFLICT DO NOTHING;

-- ── Sample orders ─────────────────────────────────────────────
DO $$
DECLARE
  admin_id   UUID;
  cashier_id UUID;
  c1         UUID := 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  c2         UUID := 'b2c3d4e5-f6a7-8901-bcde-f12345678901';
  oid        INT;
BEGIN
  SELECT id INTO admin_id   FROM users WHERE email = 'admin@restaurant.com';
  SELECT id INTO cashier_id FROM users WHERE email = 'cashier@restaurant.com';

  -- Today's completed orders
  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,table_number,customer_id,created_by)
  VALUES ('Completed','Dine-in','Cash',350,42,392,'T3',c1,admin_id) RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,1,1,185),(oid,5,1,145),(oid,10,1,55);

  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,table_number,customer_id,created_by)
  VALUES ('Completed','Dine-in','Card',440,52.8,492.8,'T7',c2,cashier_id) RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,2,2,165),(oid,7,1,95);

  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,created_by)
  VALUES ('Completed','Takeout','E-wallet',280,33.6,313.6,cashier_id) RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,3,1,175),(oid,8,1,75),(oid,11,1,65);

  -- Active orders (for KDS demo)
  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,table_number,created_by)
  VALUES ('Pending','Dine-in','Cash',475,57,532,'T5',cashier_id) RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,1,1,185),(oid,5,2,145),(oid,10,1,55);

  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,table_number,created_by)
  VALUES ('Preparing','Dine-in','Card',370,44.4,414.4,'T2',cashier_id) RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,4,1,220),(oid,8,2,75);

  -- Yesterday's orders (for reports comparison)
  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,table_number,created_by,created_at)
  VALUES ('Completed','Dine-in','Cash',550,66,616,'T2',admin_id, NOW()-INTERVAL '1 day') RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,4,1,220),(oid,1,1,185),(oid,11,1,65);

  INSERT INTO orders (status,order_type,payment_method,subtotal,tax,total,created_by,created_at)
  VALUES ('Completed','Delivery','Card',330,39.6,369.6,cashier_id, NOW()-INTERVAL '1 day') RETURNING id INTO oid;
  INSERT INTO order_items (order_id,menu_item_id,quantity,unit_price)
  VALUES (oid,2,2,165);

  RAISE NOTICE 'Orders seeded successfully';
END $$;

-- ── Sample reservations ───────────────────────────────────────
DO $$
DECLARE
  admin_id UUID;
BEGIN
  SELECT id INTO admin_id FROM users WHERE email = 'admin@restaurant.com';

  INSERT INTO reservations (customer_id, table_id, reserved_at, party_size, status, notes, created_by)
  SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
         (SELECT id FROM restaurant_tables WHERE number='T3'),
         NOW()+INTERVAL '2 hours', 4, 'confirmed',
         'Birthday celebration — please prepare dessert', admin_id;

  INSERT INTO reservations (customer_id, table_id, reserved_at, party_size, status, created_by)
  SELECT 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
         (SELECT id FROM restaurant_tables WHERE number='T2'),
         NOW()+INTERVAL '4 hours', 2, 'confirmed', admin_id;

  INSERT INTO reservations (customer_id, table_id, reserved_at, party_size, status, notes, created_by)
  SELECT 'd4e5f6a7-b8c9-0123-defa-234567890123',
         (SELECT id FROM restaurant_tables WHERE number='T8'),
         NOW()+INTERVAL '6 hours', 8, 'confirmed',
         'Anniversary dinner — window table preferred', admin_id;

  RAISE NOTICE 'Reservations seeded successfully';
END $$;

-- Update occupied tables for active orders
UPDATE restaurant_tables SET status = 'occupied'
WHERE number IN ('T2','T5');

UPDATE restaurant_tables SET status = 'reserved'
WHERE number IN ('T3','T8');