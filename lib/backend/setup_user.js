// ══════════════════════════════════════════════════════════
// setup_users.js
// Run this AFTER running 001_schema.sql to insert users
// with correctly hashed passwords.
//
// Usage:  node setup_users.js
// ══════════════════════════════════════════════════════════

require('dotenv').config();
const { Pool } = require('pg');
const bcrypt   = require('bcryptjs');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME     || 'restaurant_os',
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

const USERS = [
  { name: 'Admin User',    email: 'admin@restaurant.com',   password: 'password123', role: 'admin'   },
  { name: 'Maria Manager', email: 'manager@restaurant.com', password: 'password123', role: 'manager' },
  { name: 'Jose Cashier',  email: 'cashier@restaurant.com', password: 'password123', role: 'cashier' },
  { name: 'Pedro Kitchen', email: 'kitchen@restaurant.com', password: 'password123', role: 'kitchen' },
];

async function main() {
  const client = await pool.connect();
  try {
    console.log('🔧 Setting up users with hashed passwords...\n');

    for (const u of USERS) {
      // Hash password with bcrypt cost factor 10
      const hash = await bcrypt.hash(u.password, 10);

      // Verify hash works before inserting
      const valid = await bcrypt.compare(u.password, hash);
      if (!valid) throw new Error(`Hash verification failed for ${u.email}`);

      // Get role id
      const roleRes = await client.query(
        'SELECT id FROM roles WHERE name = $1',
        [u.role]
      );
      if (!roleRes.rows[0]) throw new Error(`Role not found: ${u.role}`);
      const roleId = roleRes.rows[0].id;

      // Upsert user (insert or update if email already exists)
      await client.query(
        `INSERT INTO users (name, email, password_hash, role_id)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (email)
         DO UPDATE SET
           name          = EXCLUDED.name,
           password_hash = EXCLUDED.password_hash,
           role_id       = EXCLUDED.role_id,
           updated_at    = NOW()`,
        [u.name, u.email, hash, roleId]
      );

      console.log(`✅  ${u.role.padEnd(8)} → ${u.email}  (hash verified)`);
    }

    console.log('\n🎉 All users created successfully!');
    console.log('   Password for all accounts: password123\n');
    console.log('   Roles:');
    console.log('     Admin   → admin@restaurant.com');
    console.log('     Manager → manager@restaurant.com');
    console.log('     Cashier → cashier@restaurant.com');
    console.log('     Kitchen → kitchen@restaurant.com\n');

  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

main();