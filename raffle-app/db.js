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
    // Users table - Enhanced with seller stats
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
        approved_date ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        total_sales INTEGER DEFAULT 0,
        total_revenue ${USE_POSTGRES ? 'NUMERIC(15,2)' : 'REAL'} DEFAULT 0,
        total_commission ${USE_POSTGRES ? 'NUMERIC(15,2)' : 'REAL'} DEFAULT 0,
        active ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'TRUE' : '1'}
      )
    `);
    
    // Raffles table - NEW
    await run(`
      CREATE TABLE IF NOT EXISTS raffles (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        name TEXT NOT NULL,
        description TEXT,
        start_date ${USE_POSTGRES ? 'DATE' : 'TEXT'},
        draw_date ${USE_POSTGRES ? 'DATE' : 'TEXT'},
        status TEXT DEFAULT 'draft',
        total_tickets INTEGER DEFAULT 1500000,
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Ticket Categories table - NEW
    await run(`
      CREATE TABLE IF NOT EXISTS ticket_categories (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        raffle_id INTEGER NOT NULL,
        category_code TEXT NOT NULL,
        category_name TEXT,
        price ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'} NOT NULL,
        total_tickets INTEGER NOT NULL,
        sold_tickets INTEGER DEFAULT 0,
        total_revenue ${USE_POSTGRES ? 'NUMERIC(15,2)' : 'REAL'} DEFAULT 0,
        color TEXT,
        description TEXT,
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Create index for ticket_categories
    if (USE_POSTGRES) {
      await run(`CREATE UNIQUE INDEX IF NOT EXISTS idx_category_unique ON ticket_categories(raffle_id, category_code)`);
    }
    
    // Tickets table - Enhanced with pricing, barcode, QR, printing tracking
    await run(`
      CREATE TABLE IF NOT EXISTS tickets (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        raffle_id INTEGER,
        category_id INTEGER,
        category TEXT,
        ticket_number TEXT UNIQUE NOT NULL,
        barcode TEXT UNIQUE,
        qr_code_data TEXT,
        price ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        status TEXT DEFAULT 'AVAILABLE',
        printed ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
        printed_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        print_count INTEGER DEFAULT 0,
        seller_id INTEGER,
        buyer_name TEXT,
        buyer_phone TEXT,
        buyer_email TEXT,
        seller_name TEXT,
        seller_phone TEXT,
        payment_method TEXT,
        payment_verified ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
        sold_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        amount ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        actual_price_paid ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        seller_commission ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        is_winner ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
        prize_level TEXT,
        won_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Create indexes for tickets table - CRITICAL for performance
    if (USE_POSTGRES) {
      await run(`CREATE INDEX IF NOT EXISTS idx_ticket_number ON tickets(ticket_number)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_barcode ON tickets(barcode)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_qr_code ON tickets(qr_code_data)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_category ON tickets(category)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_status ON tickets(status)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_printed ON tickets(printed)`);
    } else {
      await run(`CREATE INDEX IF NOT EXISTS idx_ticket_number ON tickets(ticket_number)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_barcode ON tickets(barcode)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_category ON tickets(category)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_status ON tickets(status)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_printed ON tickets(printed)`);
    }
    
    // Print Jobs table - NEW
    await run(`
      CREATE TABLE IF NOT EXISTS print_jobs (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        admin_id INTEGER NOT NULL,
        raffle_id INTEGER,
        category TEXT,
        ticket_range_start TEXT,
        ticket_range_end TEXT,
        total_tickets INTEGER,
        total_pages INTEGER,
        paper_type TEXT NOT NULL,
        printer_name TEXT,
        double_sided ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'TRUE' : '1'},
        status TEXT DEFAULT 'scheduled',
        progress_percent INTEGER DEFAULT 0,
        print_type TEXT DEFAULT 'initial',
        started_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        completed_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        error_message TEXT
      )
    `);
    
    // Create index for print_jobs
    if (USE_POSTGRES) {
      await run(`CREATE INDEX IF NOT EXISTS idx_print_status ON print_jobs(status)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_print_admin ON print_jobs(admin_id)`);
    } else {
      await run(`CREATE INDEX IF NOT EXISTS idx_print_status ON print_jobs(status)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_print_admin ON print_jobs(admin_id)`);
    }
    
    // Ticket Scans table - NEW (Audit Trail)
    await run(`
      CREATE TABLE IF NOT EXISTS ticket_scans (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        ticket_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        user_role TEXT NOT NULL,
        scan_type TEXT NOT NULL,
        scan_method TEXT NOT NULL,
        scanned_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        notes TEXT
      )
    `);
    
    // Create indexes for ticket_scans
    if (USE_POSTGRES) {
      await run(`CREATE INDEX IF NOT EXISTS idx_scan_ticket ON ticket_scans(ticket_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_scan_user ON ticket_scans(user_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_scan_date ON ticket_scans(scanned_at)`);
    } else {
      await run(`CREATE INDEX IF NOT EXISTS idx_scan_ticket ON ticket_scans(ticket_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_scan_user ON ticket_scans(user_id)`);
    }
    
    // Winners table - NEW
    await run(`
      CREATE TABLE IF NOT EXISTS winners (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        raffle_id INTEGER NOT NULL,
        ticket_id INTEGER NOT NULL UNIQUE,
        prize_level TEXT NOT NULL,
        prize_description TEXT,
        prize_value ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        drawn_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        drawn_by_admin_id INTEGER NOT NULL,
        claimed ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
        claimed_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'}
      )
    `);
    
    // Ticket Designs table - NEW
    await run(`
      CREATE TABLE IF NOT EXISTS ticket_designs (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        size TEXT NOT NULL,
        side TEXT NOT NULL,
        file_path TEXT,
        uploaded_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        barcode_x INTEGER,
        barcode_y INTEGER,
        barcode_width INTEGER DEFAULT 200,
        barcode_height INTEGER DEFAULT 40,
        qr_x INTEGER,
        qr_y INTEGER,
        qr_size INTEGER DEFAULT 80,
        stub_qr_x INTEGER,
        stub_qr_y INTEGER,
        stub_qr_size INTEGER DEFAULT 30,
        is_active ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'TRUE' : '1'}
      )
    `);
    
    // Draws table (keep existing for backwards compatibility)
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
    
    // Seller requests table (keep existing)
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
    
    // Seller concerns table (keep existing)
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
    
    // Check if default raffle exists, create if not
    const defaultRaffle = await get("SELECT * FROM raffles WHERE id = ?", [1]);
    if (!defaultRaffle) {
      await run(
        `INSERT INTO raffles (name, description, status, total_tickets) VALUES (?, ?, ?, ?)`,
        ['Default Raffle 2024', 'Main raffle with 1.5M tickets across 4 categories', 'active', 1500000]
      );
      console.log('🎫 Default raffle created');
      
      // Create default ticket categories
      const categories = [
        { code: 'ABC', name: 'Bronze', price: 50.00, total: 500000, color: '#cd7f32' },
        { code: 'EFG', name: 'Silver', price: 100.00, total: 500000, color: '#c0c0c0' },
        { code: 'JKL', name: 'Gold', price: 250.00, total: 250000, color: '#ffd700' },
        { code: 'XYZ', name: 'Platinum', price: 500.00, total: 250000, color: '#e5e4e2' }
      ];
      
      for (const cat of categories) {
        await run(
          `INSERT INTO ticket_categories (raffle_id, category_code, category_name, price, total_tickets, color) VALUES (?, ?, ?, ?, ?, ?)`,
          [1, cat.code, cat.name, cat.price, cat.total, cat.color]
        );
      }
      console.log('📦 Default ticket categories created (ABC=$50, EFG=$100, JKL=$250, XYZ=$500)');
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
