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
      // SQLite - Use db.all for SELECT and PRAGMA statements
      const sqlUpper = sql.trim().toUpperCase();
      if (sqlUpper.startsWith('SELECT') || sqlUpper.startsWith('PRAGMA')) {
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
        raffle_id INTEGER NOT NULL ${USE_POSTGRES ? 'REFERENCES raffles(id) ON DELETE CASCADE' : ''},
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
        customer_department TEXT,
        available_online ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
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
    
    // Draw photos table - for draw event verification
    await run(`
      CREATE TABLE IF NOT EXISTS draw_photos (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        draw_id INTEGER ${USE_POSTGRES ? 'REFERENCES draws(id) ON DELETE CASCADE' : ''},
        seller_phone TEXT NOT NULL,
        seller_name TEXT NOT NULL,
        photo_path TEXT NOT NULL,
        uploaded_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        verified_by TEXT,
        verified_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        verification_status TEXT DEFAULT 'pending',
        admin_notes TEXT
      )
    `);
    
    // Create indexes for draw_photos table
    try {
      await run(`CREATE INDEX IF NOT EXISTS idx_draw_photos_draw_id ON draw_photos(draw_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_draw_photos_status ON draw_photos(verification_status)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_draw_photos_seller_phone ON draw_photos(seller_phone)`);
      console.log('✅ Created indexes on draw_photos table');
    } catch (error) {
      console.warn('⚠️  Could not create draw_photos indexes:', error.message);
    }
    
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
    
    // Ticket designs table - for category-specific custom designs
    await run(`
      CREATE TABLE IF NOT EXISTS ticket_designs (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        category TEXT NOT NULL UNIQUE,
        front_image_path TEXT,
        back_image_path TEXT,
        front_image_base64 TEXT,
        back_image_base64 TEXT,
        fit_mode TEXT DEFAULT 'contain',
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        updated_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Departments table - stores the 10 Haiti departments
    await run(`
      CREATE TABLE IF NOT EXISTS departments (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        name TEXT UNIQUE NOT NULL,
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    console.log('✅ Departments table created');
    
    // Payments table - for tracking all payment transactions
    await run(`
      CREATE TABLE IF NOT EXISTS payments (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        raffle_id INTEGER NOT NULL ${USE_POSTGRES ? 'REFERENCES raffles(id) ON DELETE CASCADE' : ''},
        payment_reference TEXT UNIQUE NOT NULL,
        payment_method TEXT NOT NULL,
        payment_type TEXT NOT NULL,
        amount ${USE_POSTGRES ? 'NUMERIC(10,2)' : 'REAL'} NOT NULL,
        buyer_name TEXT NOT NULL,
        buyer_email TEXT,
        buyer_phone TEXT NOT NULL,
        ticket_category TEXT,
        ticket_quantity INTEGER DEFAULT 1,
        payment_status TEXT DEFAULT 'pending',
        transaction_id TEXT,
        external_reference TEXT,
        payment_provider TEXT,
        payment_mode TEXT,
        verified_by INTEGER ${USE_POSTGRES ? 'REFERENCES users(id)' : ''},
        verified_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'},
        rejection_reason TEXT,
        ticket_numbers TEXT,
        notes TEXT,
        customer_department TEXT,
        created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        updated_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
      )
    `);
    
    // Create indexes for payments table
    try {
      await run(`CREATE INDEX IF NOT EXISTS idx_payments_reference ON payments(payment_reference)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(payment_status)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_payments_buyer_phone ON payments(buyer_phone)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_payments_buyer_email ON payments(buyer_email)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_payments_raffle_id ON payments(raffle_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id)`);
      console.log('✅ Created 6 indexes on payments table');
    } catch (error) {
      console.warn('⚠️  Could not create some payment indexes:', error.message);
    }
    
    // Transaction verification log table - for fraud detection and audit trail
    await run(`
      CREATE TABLE IF NOT EXISTS txn_verification_log (
        id ${USE_POSTGRES ? 'SERIAL PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'},
        txn_id TEXT NOT NULL,
        payment_reference TEXT NOT NULL,
        seller_phone TEXT NOT NULL,
        seller_name TEXT NOT NULL,
        verification_time ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'},
        tickets_remaining INTEGER,
        FOREIGN KEY (payment_reference) REFERENCES payments(payment_reference)
      )
    `);
    
    // Create index for fast fraud detection
    try {
      await run(`CREATE INDEX IF NOT EXISTS idx_txn_verification_txn_id ON txn_verification_log(txn_id)`);
      await run(`CREATE INDEX IF NOT EXISTS idx_txn_verification_payment_ref ON txn_verification_log(payment_reference)`);
      console.log('✅ Created txn_verification_log table with indexes');
    } catch (error) {
      console.warn('⚠️  Could not create txn verification log indexes:', error.message);
    }
    
    // Add payment_reference column to tickets table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE tickets 
          ADD COLUMN IF NOT EXISTS payment_reference TEXT
        `);
        await run(`CREATE INDEX IF NOT EXISTS idx_tickets_payment_reference ON tickets(payment_reference)`);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(tickets)`);
        const hasPaymentRef = columns.some(col => col.name === 'payment_reference');
        if (!hasPaymentRef) {
          await run(`ALTER TABLE tickets ADD COLUMN payment_reference TEXT`);
          await run(`CREATE INDEX IF NOT EXISTS idx_tickets_payment_reference ON tickets(payment_reference)`);
        }
      }
      console.log('✅ Added payment_reference column to tickets table');
    } catch (error) {
      console.log('Note: payment_reference column already exists or could not be added');
    }
    
    // Add seller_name column to payments table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE payments 
          ADD COLUMN IF NOT EXISTS seller_name TEXT
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(payments)`);
        const hasSellerName = columns.some(col => col.name === 'seller_name');
        if (!hasSellerName) {
          await run(`ALTER TABLE payments ADD COLUMN seller_name TEXT`);
        }
      }
      console.log('✅ Added seller_name column to payments table');
    } catch (error) {
      console.log('Note: seller_name column already exists or could not be added');
    }
    
    // Add customer_department column to tickets table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE tickets 
          ADD COLUMN IF NOT EXISTS customer_department TEXT
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(tickets)`);
        const hasCustomerDepartment = columns.some(col => col.name === 'customer_department');
        if (!hasCustomerDepartment) {
          await run(`ALTER TABLE tickets ADD COLUMN customer_department TEXT`);
        }
      }
      console.log('✅ Added customer_department column to tickets table');
    } catch (error) {
      console.log('Note: customer_department column already exists or could not be added');
    }
    
    // Add customer_department column to payments table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE payments 
          ADD COLUMN IF NOT EXISTS customer_department TEXT
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(payments)`);
        const hasCustomerDepartment = columns.some(col => col.name === 'customer_department');
        if (!hasCustomerDepartment) {
          await run(`ALTER TABLE payments ADD COLUMN customer_department TEXT`);
        }
      }
      console.log('✅ Added customer_department column to payments table');
    } catch (error) {
      console.log('Note: customer_department column already exists or could not be added');
    }
    
    // Add address column to seller_requests table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE seller_requests 
          ADD COLUMN IF NOT EXISTS address TEXT
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(seller_requests)`);
        const hasAddress = columns.some(col => col.name === 'address');
        if (!hasAddress) {
          await run(`ALTER TABLE seller_requests ADD COLUMN address TEXT`);
        }
      }
      console.log('✅ Added address column to seller_requests table');
    } catch (error) {
      console.log('Note: address column already exists or could not be added');
    }
    
    // Add id_picture_path column to seller_requests table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE seller_requests 
          ADD COLUMN IF NOT EXISTS id_picture_path TEXT
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(seller_requests)`);
        const hasIdPicture = columns.some(col => col.name === 'id_picture_path');
        if (!hasIdPicture) {
          await run(`ALTER TABLE seller_requests ADD COLUMN id_picture_path TEXT`);
        }
      }
      console.log('✅ Added id_picture_path column to seller_requests table');
    } catch (error) {
      console.log('Note: id_picture_path column already exists or could not be added');
    }
    
    // Add fit_mode column if it doesn't exist (for existing databases)
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE ticket_designs 
          ADD COLUMN IF NOT EXISTS fit_mode TEXT DEFAULT 'contain'
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(ticket_designs)`);
        const hasFitMode = columns.some(col => col.name === 'fit_mode');
        if (!hasFitMode) {
          await run(`ALTER TABLE ticket_designs ADD COLUMN fit_mode TEXT DEFAULT 'contain'`);
        }
      }
    } catch (error) {
      // Column might already exist, ignore error
      console.log('Note: fit_mode column already exists or could not be added');
    }
    
    // Add new columns for enhanced design system (name, description, dimensions, transformations)
    const newColumns = [
      { name: 'name', type: 'VARCHAR(100)', default: null },
      { name: 'description', type: 'TEXT', default: null },
      { name: 'width', type: 'INTEGER', default: 396 },
      { name: 'height', type: 'INTEGER', default: 153 },
      { name: 'rotation', type: 'INTEGER', default: 0 },
      { name: 'scale_width', type: 'INTEGER', default: 100 },
      { name: 'scale_height', type: 'INTEGER', default: 100 },
      { name: 'offset_x', type: 'INTEGER', default: 0 },
      { name: 'offset_y', type: 'INTEGER', default: 0 },
      { name: 'is_active', type: USE_POSTGRES ? 'BOOLEAN' : 'INTEGER', default: USE_POSTGRES ? 'TRUE' : '1' }
    ];
    
    for (const col of newColumns) {
      try {
        if (USE_POSTGRES) {
          // Handle NULL defaults properly for PostgreSQL
          const defaultClause = col.default === null ? '' : `DEFAULT ${col.default}`;
          await run(`
            ALTER TABLE ticket_designs 
            ADD COLUMN IF NOT EXISTS ${col.name} ${col.type} ${defaultClause}
          `);
        } else {
          // SQLite doesn't support IF NOT EXISTS for columns, so check first
          const columns = await all(`PRAGMA table_info(ticket_designs)`);
          const hasColumn = columns.some(c => c.name === col.name);
          if (!hasColumn) {
            const defaultClause = col.default === null ? '' : `DEFAULT ${col.default}`;
            await run(`ALTER TABLE ticket_designs ADD COLUMN ${col.name} ${col.type} ${defaultClause}`);
          }
        }
      } catch (error) {
        // Column might already exist, that's okay
        console.log(`Note: ${col.name} column already exists or could not be added`);
      }
    }
    
    // Add available_online column to tickets table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE tickets 
          ADD COLUMN IF NOT EXISTS available_online BOOLEAN DEFAULT FALSE
        `);
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(tickets)`);
        const hasAvailableOnline = columns.some(col => col.name === 'available_online');
        if (!hasAvailableOnline) {
          await run(`ALTER TABLE tickets ADD COLUMN available_online INTEGER DEFAULT 0`);
        }
      }
      console.log('✅ Added available_online column to tickets table');
    } catch (error) {
      console.log('Note: available_online column already exists or could not be added');
    }
    
    // Add ticket_photo_path column to tickets table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE tickets 
          ADD COLUMN IF NOT EXISTS ticket_photo_path TEXT
        `);
        console.log('✅ Added ticket_photo_path column to tickets table');
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(tickets)`);
        const hasTicketPhotoPath = columns.some(col => col.name === 'ticket_photo_path');
        if (!hasTicketPhotoPath) {
          await run(`ALTER TABLE tickets ADD COLUMN ticket_photo_path TEXT`);
          console.log('✅ Added ticket_photo_path column to tickets table');
        } else {
          console.log('Note: ticket_photo_path column already exists');
        }
      }
    } catch (error) {
      console.error('Error adding ticket_photo_path column:', error.message);
    }
    
    // Add ticket_photo_uploaded_at column to tickets table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE tickets 
          ADD COLUMN IF NOT EXISTS ticket_photo_uploaded_at ${USE_POSTGRES ? 'TIMESTAMP' : 'DATETIME'}
        `);
        console.log('✅ Added ticket_photo_uploaded_at column to tickets table');
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(tickets)`);
        const hasTicketPhotoUploadedAt = columns.some(col => col.name === 'ticket_photo_uploaded_at');
        if (!hasTicketPhotoUploadedAt) {
          await run(`ALTER TABLE tickets ADD COLUMN ticket_photo_uploaded_at DATETIME`);
          console.log('✅ Added ticket_photo_uploaded_at column to tickets table');
        } else {
          console.log('Note: ticket_photo_uploaded_at column already exists');
        }
      }
    } catch (error) {
      console.error('Error adding ticket_photo_uploaded_at column:', error.message);
    }
    
    // Add txn_number column to tickets table if it doesn't exist
    try {
      if (USE_POSTGRES) {
        await run(`
          ALTER TABLE tickets 
          ADD COLUMN IF NOT EXISTS txn_number TEXT
        `);
        console.log('✅ Added txn_number column to tickets table');
      } else {
        // SQLite doesn't support IF NOT EXISTS for columns, so check first
        const columns = await all(`PRAGMA table_info(tickets)`);
        const hasTxnNumber = columns.some(col => col.name === 'txn_number');
        if (!hasTxnNumber) {
          await run(`ALTER TABLE tickets ADD COLUMN txn_number TEXT`);
          console.log('✅ Added txn_number column to tickets table');
        } else {
          console.log('Note: txn_number column already exists');
        }
      }
    } catch (error) {
      console.error('Error adding txn_number column:', error.message);
    }
    
    // Add performance indexes
    console.log('📊 Creating performance indexes...');

    const indexes = [
      // Tickets table indexes
      'CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_seller_name ON tickets(seller_name)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_available_online ON tickets(available_online)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_ticket_photo_path ON tickets(ticket_photo_path)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_txn_number ON tickets(txn_number)',
      
      // Seller requests indexes
      'CREATE INDEX IF NOT EXISTS idx_seller_requests_status ON seller_requests(status)',
      
      // Draws indexes
      'CREATE INDEX IF NOT EXISTS idx_draws_date ON draws(drawn_at)'
    ];

    for (const indexQuery of indexes) {
      try {
        await run(indexQuery);
      } catch (error) {
        // Index might already exist, that's okay
        if (!error.message.includes('already exists')) {
          console.warn('Index creation warning:', error.message);
        }
      }
    }

    console.log('✅ Performance indexes created');
    
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
        ['GRATE GENYEN', 'active', 'Official Grate Genyen raffle for ticket sales', 2000000]
      );
      
      // Create 6 ticket categories with correct names and prices (in HTG)
      const categories = [
        { code: 'BAS', name: 'Basic', price: 50, total: 400000, color: '#10b981' },
        { code: 'PRM', name: 'Premium', price: 100, total: 400000, color: '#7c3aed' },
        { code: 'BRZ', name: 'Bronze', price: 250, total: 350000, color: '#ea580c' },
        { code: 'SLV', name: 'Silver', price: 500, total: 300000, color: '#94a3b8' },
        { code: 'GLD', name: 'Gold', price: 1000, total: 300000, color: '#fbbf24' },
        { code: 'DIA', name: 'Diamond', price: 5000, total: 250000, color: '#22d3ee' }
      ];
      
      for (const cat of categories) {
        await run(
          `INSERT INTO ticket_categories 
           (raffle_id, category_code, category_name, price, total_tickets, color) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [1, cat.code, cat.name, cat.price, cat.total, cat.color]
        );
      }
      
      console.log('✅ Default raffle created with 6 categories:');
      console.log('   - BAS (Basic): 50 HTG - 400,000 tickets');
      console.log('   - PRM (Premium): 100 HTG - 400,000 tickets');
      console.log('   - BRZ (Bronze): 250 HTG - 350,000 tickets');
      console.log('   - SLV (Silver): 500 HTG - 300,000 tickets');
      console.log('   - GLD (Gold): 1,000 HTG - 300,000 tickets');
      console.log('   - DIA (Diamond): 5,000 HTG - 250,000 tickets');
      console.log('   - Total capacity: 2,000,000 tickets');
      console.log('   - Potential revenue: 1,597,500,000 HTG');
    }
    
    // Initialize departments table with Haiti's 10 departments if empty
    const existingDepartments = await get("SELECT COUNT(*) as count FROM departments");
    if (!existingDepartments || existingDepartments.count === 0) {
      console.log('🗺️  Populating departments table with Haiti departments...');
      
      const haitiDepartments = [
        'Artibonite',
        'Centre',
        "Grand'Anse",
        'Nippes',
        'Nord',
        'Nord-Est',
        'Nord-Ouest',
        'Ouest',
        'Sud',
        'Sud-Est'
      ];
      
      for (const department of haitiDepartments) {
        await run(
          'INSERT INTO departments (name) VALUES (?)',
          [department]
        );
      }
      
      console.log('✅ Departments table populated with 10 Haiti departments');
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

/**
 * Stream rows from database without loading all into memory
 * Processes rows one at a time using a callback
 * 
 * @param {string} sql - SQL query
 * @param {Array} params - Query parameters
 * @param {Function} rowCallback - Callback function(row) called for each row
 * @param {Object} options - Options { batchSize: number }
 * @returns {Promise<number>} - Total rows processed
 */
async function streamRows(sql, params = [], rowCallback, options = {}) {
  const batchSize = options.batchSize || 1000;
  let totalProcessed = 0;
  
  if (USE_POSTGRES) {
    // PostgreSQL: Use LIMIT/OFFSET pagination to avoid loading all rows at once
    let offset = 0;
    let hasMore = true;
    
    // Convert SQLite placeholders (?) to PostgreSQL placeholders ($1, $2, etc.)
    let pgSql = sql;
    let paramIndex = 1;
    pgSql = pgSql.replace(/\?/g, () => `$${paramIndex++}`);
    
    // Add LIMIT and OFFSET if not present
    // Note: Simple check - assumes caller doesn't use LIMIT in string literals
    if (!pgSql.toUpperCase().includes('LIMIT')) {
      pgSql += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    }
    
    while (hasMore) {
      const batchParams = [...params, batchSize, offset];
      const result = await new Promise((resolve, reject) => {
        pgPool.query(pgSql, batchParams, (err, result) => {
          if (err) reject(err);
          else resolve(result.rows);
        });
      });
      
      if (result.length === 0) {
        hasMore = false;
      } else {
        for (const row of result) {
          await rowCallback(row);
          totalProcessed++;
        }
        offset += result.length;
        
        // Allow garbage collection between batches
        if (global.gc) {
          global.gc();
        }
      }
    }
  } else {
    // SQLite: Use db.each for row-by-row processing
    return new Promise((resolve, reject) => {
      db.each(
        sql,
        params,
        (err, row) => {
          if (err) {
            reject(err);
          } else {
            rowCallback(row);
            totalProcessed++;
          }
        },
        (err) => {
          if (err) reject(err);
          else resolve(totalProcessed);
        }
      );
    });
  }
  
  return totalProcessed;
}

/**
 * Process rows in batches without loading entire result set into memory
 * Calls batchCallback with array of rows for each batch
 * 
 * @param {string} sql - SQL query
 * @param {Array} params - Query parameters
 * @param {Function} batchCallback - Callback function(batch) called for each batch, returns true to stop
 * @param {Object} options - Options { batchSize: number }
 * @returns {Promise<number>} - Total rows processed
 */
async function processBatches(sql, params = [], batchCallback, options = {}) {
  const batchSize = options.batchSize || 1000;
  let totalProcessed = 0;
  let offset = 0;
  let hasMore = true;
  
  // Convert SQLite placeholders (?) to PostgreSQL placeholders ($1, $2, etc.) if needed
  let execSql = sql;
  
  if (USE_POSTGRES) {
    let paramIndex = 1;
    execSql = execSql.replace(/\?/g, () => `$${paramIndex++}`);
  }
  
  // Add LIMIT and OFFSET if not present
  // Note: Simple check - assumes caller doesn't use LIMIT in string literals
  if (!execSql.toUpperCase().includes('LIMIT')) {
    if (USE_POSTGRES) {
      execSql += ` LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    } else {
      execSql += ' LIMIT ? OFFSET ?';
    }
  }
  
  while (hasMore) {
    const batchParams = [...params, batchSize, offset];
    
    let batch;
    if (USE_POSTGRES) {
      batch = await new Promise((resolve, reject) => {
        pgPool.query(execSql, batchParams, (err, result) => {
          if (err) reject(err);
          else resolve(result.rows);
        });
      });
    } else {
      batch = await new Promise((resolve, reject) => {
        db.all(execSql, batchParams, (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        });
      });
    }
    
    if (batch.length === 0) {
      hasMore = false;
    } else {
      const shouldStop = await batchCallback(batch);
      totalProcessed += batch.length;
      offset += batch.length;
      
      // Stop if callback returns true
      if (shouldStop === true) {
        hasMore = false;
      }
      
      // Allow garbage collection between batches
      if (global.gc) {
        global.gc();
      }
    }
  }
  
  return totalProcessed;
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
  isUniqueConstraintError,
  streamRows,
  processBatches
};
