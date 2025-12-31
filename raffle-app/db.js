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
    // Helper function to safely create indexes
    const safeCreateIndex = async (indexSQL, indexName) => {
      try {
        await run(indexSQL);
        console.log(`✅ Created index: ${indexName}`);
      } catch (error) {
        console.warn(`⚠️  Could not create index ${indexName}:`, error.message);
        // Continue - indexes are not critical for basic operation
      }
    };
    
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
    
    // Raffles table - for raffle ticket system
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
    
    // Ticket categories table - for raffle ticket system
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
    
    // Create unique index for ticket_categories (with error handling)
    try {
      if (USE_POSTGRES) {
        // PostgreSQL: Verify table exists first
        const tableExists = await get(`
          SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = 'ticket_categories'
          ) as exists
        `);
        
        if (tableExists && tableExists.exists) {
          await run(`CREATE UNIQUE INDEX IF NOT EXISTS idx_ticket_categories_raffle_category 
                    ON ticket_categories(raffle_id, category_code)`);
          console.log('✅ Created unique index on ticket_categories');
        } else {
          console.warn('⚠️  Table ticket_categories does not exist, skipping index creation');
        }
      } else {
        // SQLite: Just try to create it
        await run(`CREATE UNIQUE INDEX IF NOT EXISTS idx_ticket_categories_raffle_category 
                  ON ticket_categories(raffle_id, category_code)`);
        console.log('✅ Created unique index on ticket_categories');
      }
    } catch (error) {
      console.warn('⚠️  Could not create ticket_categories index:', error.message);
      console.warn('   This is OK - indexes are performance optimization, not critical');
      // Don't throw - allow initialization to continue
    }
    
    // Tickets table (enhanced for raffle system)
    await run(`
      CREATE TABLE IF NOT EXISTS tickets (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        raffle_id INTEGER,
        category_id INTEGER,
        ticket_number TEXT UNIQUE NOT NULL,
        buyer_name TEXT,
        buyer_phone TEXT,
        seller_name TEXT,
        seller_phone TEXT,
        amount ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        price ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        status TEXT DEFAULT 'AVAILABLE',
        barcode TEXT,
        category TEXT,
        qr_code_data TEXT,
        printed ${USE_POSTGRES ? 'BOOLEAN DEFAULT FALSE' : 'INTEGER DEFAULT 0'},
        printed_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        print_count INTEGER DEFAULT 0,
        seller_id INTEGER,
        buyer_email TEXT,
        payment_method TEXT,
        payment_verified ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
        sold_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        actual_price_paid ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        seller_commission ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'},
        is_winner ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
        prize_level TEXT,
        won_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Create indexes for tickets table (with error handling)
    try {
      await run(`CREATE INDEX IF NOT EXISTS idx_tickets_barcode ON tickets(barcode)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_tickets_ticket_number ON tickets(ticket_number)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_tickets_raffle_id ON tickets(raffle_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_tickets_category ON tickets(category)`);
      console.log('✅ Created 4 indexes on tickets table');
    } catch (error) {
      console.warn('⚠️  Could not create some ticket indexes:', error.message);
      console.warn('   This is OK - indexes are performance optimization, not critical');
      // Don't throw - allow initialization to continue
    }
    
    // Print jobs table - for tracking ticket printing
    await run(`
      CREATE TABLE IF NOT EXISTS print_jobs (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        admin_id INTEGER,
        raffle_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        ticket_range_start TEXT NOT NULL,
        ticket_range_end TEXT NOT NULL,
        total_tickets INTEGER NOT NULL,
        total_pages INTEGER NOT NULL,
        paper_type TEXT NOT NULL,
        status TEXT DEFAULT 'scheduled',
        progress_percent INTEGER DEFAULT 0,
        started_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        completed_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'}
      )
    `);
    
    // Ticket scans table - for audit trail (future use)
    await run(`
      CREATE TABLE IF NOT EXISTS ticket_scans (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        ticket_id INTEGER NOT NULL,
        ticket_number TEXT NOT NULL,
        scanned_by TEXT,
        scan_type TEXT,
        scanned_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Winners table - for winner management (future use)
    await run(`
      CREATE TABLE IF NOT EXISTS winners (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        raffle_id INTEGER NOT NULL,
        ticket_id INTEGER NOT NULL,
        ticket_number TEXT NOT NULL,
        prize_name TEXT NOT NULL,
        winner_name TEXT NOT NULL,
        winner_phone TEXT NOT NULL,
        drawn_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        claimed ${USE_POSTGRES ? 'BOOLEAN DEFAULT FALSE' : 'INTEGER DEFAULT 0'},
        claimed_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'}
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
    
    // Ticket templates table - for custom ticket designs
    await run(`
      CREATE TABLE IF NOT EXISTS ticket_templates (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        name TEXT NOT NULL,
        front_image_path TEXT NOT NULL,
        back_image_path TEXT NOT NULL,
        fit_mode TEXT DEFAULT 'aspect',
        is_active ${USE_POSTGRES ? 'BOOLEAN DEFAULT FALSE' : 'INTEGER DEFAULT 0'},
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        updated_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
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
    
    // Initialize default raffle and categories if they don't exist
    const existingRaffle = await get("SELECT * FROM raffles WHERE id = 1");
    if (!existingRaffle) {
      console.log('🎟️  Creating default raffle and categories...');
      
      // Create default raffle
      await run(
        `INSERT INTO raffles (name, status, description, total_tickets) 
         VALUES (?, ?, ?, ?)`,
        ['Default Raffle 2024', 'active', 'Official raffle with 4 ticket categories', 1500000]
      );
      
      // Create 4 ticket categories
      const categories = [
        { code: 'ABC', name: 'Bronze', price: 50.00, total: 500000, color: '#CD7F32' },
        { code: 'EFG', name: 'Silver', price: 100.00, total: 500000, color: '#C0C0C0' },
        { code: 'JKL', name: 'Gold', price: 250.00, total: 250000, color: '#FFD700' },
        { code: 'XYZ', name: 'Platinum', price: 500.00, total: 250000, color: '#E5E4E2' }
      ];
      
      for (const cat of categories) {
        await run(
          `INSERT INTO ticket_categories 
           (raffle_id, category_code, category_name, price, total_tickets, color) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [1, cat.code, cat.name, cat.price, cat.total, cat.color]
        );
      }
      
      console.log('✅ Default raffle created with 4 categories:');
      console.log('   - ABC (Bronze): $50.00 - 500,000 tickets');
      console.log('   - EFG (Silver): $100.00 - 500,000 tickets');
      console.log('   - JKL (Gold): $250.00 - 250,000 tickets');
      console.log('   - XYZ (Platinum): $500.00 - 250,000 tickets');
      console.log('   - Total capacity: 1,500,000 tickets');
      console.log('   - Potential revenue: $262,500,000');
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
