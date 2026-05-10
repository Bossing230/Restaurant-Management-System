require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432'),
  database: 'postgres', // Connect to default postgres db first
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

async function init() {
  const client = await pool.connect();
  try {
    // 1. Create database if not exists
    console.log('Creating database...');
    await client.query(`
      SELECT 'CREATE DATABASE restaurant_os' 
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'restaurant_os')
    `);
    
    // Release connection to postgres db
    client.release();
    await pool.end();

    // 2. Connect to restaurant_os database
    const appPool = new Pool({
      host:     process.env.DB_HOST     || 'localhost',
      port:     parseInt(process.env.DB_PORT || '5432'),
      database: 'restaurant_os',
      user:     process.env.DB_USER     || 'postgres',
      password: process.env.DB_PASSWORD || 'password',
    });

    const appClient = await appPool.connect();

    // 3. Run schema
    console.log('Running schema...');
    const schemaPath = path.join(__dirname, '..', 'database', 'migration', '001_schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await appClient.query(schema);

    // 4. Insert users with hashed passwords
    console.log('Setting up users...');
    const users = [
      { name: 'Admin User',    email: 'admin@restaurant.com',   password: 'password123', role: 'admin' },
      { name: 'Maria Manager', email: 'manager@restaurant.com', password: 'password123', role: 'manager' },
      { name: 'Jose Cashier',  email: 'cashier@restaurant.com', password: 'password123', role: 'cashier' },
      { name: 'Pedro Kitchen', email: 'kitchen@restaurant.com', password: 'password123', role: 'kitchen' },
    ];

    for (const u of users) {
      const hash = await bcrypt.hash(u.password, 10);
      const roleRes = await appClient.query('SELECT id FROM roles WHERE name = $1', [u.role]);
      const roleId = roleRes.rows[0].id;

      await appClient.query(
        `INSERT INTO users (name, email, password_hash, role_id, status, is_active)
         VALUES ($1, $2, $3, $4, 'online', true)
         ON CONFLICT (email)
         DO UPDATE SET name = EXCLUDED.name, password_hash = EXCLUDED.password_hash, role_id = EXCLUDED.role_id, updated_at = NOW()`,
        [u.name, u.email, hash, roleId]
      );
      console.log(`  ✅ ${u.email}`);
    }

    console.log('\n🎉 Database initialized successfully!');
    console.log('   All passwords: password123');

  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  } finally {
    client?.release();
    await pool.end();
  }
}

init();