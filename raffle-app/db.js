const sqlite3 = require('sqlite3').verbose();
const { Pool } = require('pg');

// Determine which database to use
const USE_POSTGRES = process.env.DATABASE_URL ? true : false;

let db;
let pgPool;

if (USE_POSTGRES) {
  console.log('🐘 Using PostgreSQL database');
  
  // Parse DATABASE_URL from Render
  pgPool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
  });
  
  // Enhanced PostgreSQL connection validation
  console.log('🐘 PostgreSQL Configuration:');
  console.log('   - Connection String:', process.env.DATABASE_URL ? '✅ Set' : '❌ Not Set');
  console.log('   - SSL Mode:', process.env.NODE_ENV === 'production' ? 'Enabled' : 'Disabled');
  
  pgPool.query('SELECT NOW() as current_time, version() as pg_version', (err, res) => {
    if (err) {
      console.error('❌ PostgreSQL connection FAILED:');
      console.error('   Error:', err.message);
      console.error('   Code:', err.code);
      console.error('');
      console.error('🔧 TROUBLESHOOTING:');
      console.error('   1. Check DATABASE_URL is set in Render environment variables');
      console.error('   2. Use INTERNAL Database URL (not External)');
      console.error('   3. Verify database and web service are in same region');
      console.error('   4. Check database is running in Render dashboard');
      console.error('');
      console.error('📚 Setup Guide: See raffle-app/MIGRATION.md');
    } else {
      console.log('✅ PostgreSQL connected successfully');
      console.log('   - Server Time:', res.rows[0].current_time);
      console.log('   - Version:', res.rows[0].pg_version.split(',')[0]);
      console.log('   - Ready for production! 🚀');
    }
  });
} else {
  console.log('⚠️  WARNING: Using SQLite database');
  console.log('   - NOT suitable for production on Render');
  console.log('   - Data will be LOST on every restart');
  console.log('   - Add DATABASE_URL environment variable to switch to PostgreSQL');
  console.log('');
  console.log('📚 Migration Guide: See raffle-app/MIGRATION.md');
  db = new sqlite3.Database('./raffle.db');
}

/**
 * Universal query function - works with both SQLite and PostgreSQL
 */
function query(sql, params = []) {
  return new Promise((resolve, reject) => {
    if (USE_POSTGRES) {
      // Convert SQLite placeholders (?) to PostgreSQL placeholders ($1, $2, etc.)
      let pgSql = sql;
      let paramIndex = 1;
      pgSql = pgSql.replace(/\?/g, () => `$${paramIndex++}`);
      
      pgPool.query(pgSql, params, (err, result) => {
        if (err) {
          console.error('PostgreSQL query error:', err);
          reject(err);
        } else {
          resolve(result.rows);
        }
      });
    } else {
      // SQLite
      if (sql.trim().toUpperCase().startsWith('SELECT')) {
        db.all(sql, params, (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        });
      } else {
        db.run(sql, params, function(err) {
          if (err) reject(err);
          else resolve({ lastID: this.lastID, changes: this.changes });
        });
      }
    }
  });
}

/**
 * Get a single row
 */
function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    if (USE_POSTGRES) {
      let pgSql = sql;
      let paramIndex = 1;
      pgSql = pgSql.replace(/\?/g, () => `$${paramIndex++}`);
      
      pgPool.query(pgSql, params, (err, result) => {
        if (err) reject(err);
        else resolve(result.rows[0] || null);
      });
    } else {
      db.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row || null);
      });
    }
  });
}

/**
 * Run a query (INSERT, UPDATE, DELETE)
 */
function run(sql, params = []) {
  return query(sql, params);
}

/**
 * Get all rows
 */
function all(sql, params = []) {
  return query(sql, params);
}

/**
 * Initialize database schema
 */
async function initializeSchema() {
  console.log('🔧 Initializing database schema...');
  
  try {
    // Users table
    await run(`
      CREATE TABLE IF NOT EXISTS users (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        email TEXT,
        registered_via TEXT DEFAULT 'manual',
        approved_by TEXT,
        approved_date ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'}
      )
    `);
    
    // Tickets table
    await run(`
      CREATE TABLE IF NOT EXISTS tickets (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        ticket_number TEXT UNIQUE NOT NULL,
        buyer_name TEXT NOT NULL,
        buyer_phone TEXT NOT NULL,
        seller_name TEXT NOT NULL,
        seller_phone TEXT NOT NULL,
        amount ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'} NOT NULL,
        status TEXT DEFAULT 'active',
        barcode TEXT,
        category TEXT,
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Draws table
    await run(`
      CREATE TABLE IF NOT EXISTS draws (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        draw_number INTEGER NOT NULL,
        ticket_number INTEGER NOT NULL,
        prize_name TEXT NOT NULL,
        winner_name TEXT NOT NULL,
        winner_phone TEXT NOT NULL,
        drawn_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Seller requests table
    await run(`
      CREATE TABLE IF NOT EXISTS seller_requests (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        experience TEXT,
        status TEXT DEFAULT 'pending',
        request_date ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        reviewed_by TEXT,
        reviewed_date ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        approval_notes TEXT
      )
    `);
    
    // Seller concerns table
    await run(`
      CREATE TABLE IF NOT EXISTS seller_concerns (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        seller_id INTEGER NOT NULL,
        seller_name TEXT NOT NULL,
        seller_phone TEXT NOT NULL,
        issue_type TEXT NOT NULL,
        ticket_number TEXT,
        description TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        resolved_by TEXT,
        resolved_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        admin_notes TEXT
      )
    `);
    
    console.log('✅ Database schema initialized successfully');
    
    // Check if admin exists, create if not
    const admin = await get("SELECT * FROM users WHERE phone = ?", ['1234567890']);
    if (!admin) {
      const bcrypt = require('bcrypt');
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await run(
        'INSERT INTO users (name, phone, password, role) VALUES (?, ?, ?, ?)',
        ['Admin', '1234567890', hashedPassword, 'admin']
      );
      console.log('👤 Default admin account created - Phone: 1234567890, Password: admin123');
    }
    
  } catch (error) {
    console.error('❌ Database initialization error:', error);
    throw error;
  }
}

/**
 * Close database connection
 */
function close() {
  if (USE_POSTGRES) {
    pgPool.end();
  } else {
    db.close();
  }
}

/**
 * Serialize function for SQLite compatibility
 * PostgreSQL doesn't need serialization, but we provide this for compatibility
 */
function serialize(callback) {
  if (USE_POSTGRES) {
    // PostgreSQL doesn't need serialization, just execute the callback
    callback();
  } else {
    db.serialize(callback);
  }
}

/**
 * Get current timestamp expression for SQL queries
 */
function getCurrentTimestamp() {
  return USE_POSTGRES ? 'CURRENT_TIMESTAMP' : "datetime('now')";
}

/**
 * Check if error is a unique constraint violation
 * Works for both SQLite and PostgreSQL
 */
function isUniqueConstraintError(error) {
  if (!error || !error.message) return false;
  const message = error.message.toLowerCase();
  // SQLite: "UNIQUE constraint failed"
  // PostgreSQL: "duplicate key value violates unique constraint"
  return message.includes('unique constraint') || 
         message.includes('duplicate key');
}

module.exports = {
  query,
  get,
  run,
  all,
  initializeSchema,
  close,
  serialize,
  USE_POSTGRES,
  getCurrentTimestamp,
  isUniqueConstraintError
};
