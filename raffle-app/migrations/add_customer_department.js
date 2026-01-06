/**
 * Migration: Add customer_department column to tickets table
 * 
 * This migration adds support for tracking which Haiti department
 * customers are purchasing tickets from.
 * 
 * Compatible with both PostgreSQL and SQLite.
 * 
 * Usage:
 *   node migrations/add_customer_department.js
 */

const db = require('../db');

const HAITI_DEPARTMENTS = [
  'Ouest',
  'Sud',
  'Nord',
  'Artibonite',
  'Centre',
  "Grand'Anse",
  'Nippes',
  'Nord-Est',
  'Nord-Ouest',
  'Sud-Est'
];

async function migrate() {
  console.log('🔧 Starting migration: Add customer_department column');
  console.log('Database type:', db.USE_POSTGRES ? 'PostgreSQL' : 'SQLite');
  
  try {
    // Migrate tickets table
    if (db.USE_POSTGRES) {
      // PostgreSQL: Use ALTER TABLE with IF NOT EXISTS
      console.log('Adding customer_department column to tickets table (PostgreSQL)...');
      await db.run(`
        ALTER TABLE tickets 
        ADD COLUMN IF NOT EXISTS customer_department TEXT
      `);
      console.log('✅ Column added to tickets table successfully');
      
      console.log('Adding customer_department column to payments table (PostgreSQL)...');
      await db.run(`
        ALTER TABLE payments 
        ADD COLUMN IF NOT EXISTS customer_department TEXT
      `);
      console.log('✅ Column added to payments table successfully');
      
    } else {
      // SQLite: Check if column exists first
      console.log('Checking if customer_department column exists in tickets table (SQLite)...');
      const ticketsColumns = await db.all(`PRAGMA table_info(tickets)`);
      const hasTicketsColumn = ticketsColumns.some(col => col.name === 'customer_department');
      
      if (!hasTicketsColumn) {
        console.log('Adding customer_department column to tickets table...');
        await db.run(`ALTER TABLE tickets ADD COLUMN customer_department TEXT`);
        console.log('✅ Column added to tickets table successfully');
      } else {
        console.log('ℹ️  Column already exists in tickets table, skipping');
      }
      
      console.log('Checking if customer_department column exists in payments table (SQLite)...');
      const paymentsColumns = await db.all(`PRAGMA table_info(payments)`);
      const hasPaymentsColumn = paymentsColumns.some(col => col.name === 'customer_department');
      
      if (!hasPaymentsColumn) {
        console.log('Adding customer_department column to payments table...');
        await db.run(`ALTER TABLE payments ADD COLUMN customer_department TEXT`);
        console.log('✅ Column added to payments table successfully');
      } else {
        console.log('ℹ️  Column already exists in payments table, skipping');
      }
    }
    
    // Verify the columns were added
    if (db.USE_POSTGRES) {
      const ticketsResult = await db.get(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'customer_department'
      `);
      
      const paymentsResult = await db.get(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'payments' 
        AND column_name = 'customer_department'
      `);
      
      if (ticketsResult && paymentsResult) {
        console.log('✅ Migration completed successfully!');
        console.log('   - Column: customer_department');
        console.log('   - Type: TEXT');
        console.log('   - Tables: tickets, payments');
        console.log('   - Valid values:', HAITI_DEPARTMENTS.join(', '));
      } else {
        throw new Error('Column verification failed');
      }
    } else {
      const ticketsColumns = await db.all(`PRAGMA table_info(tickets)`);
      const ticketsColumn = ticketsColumns.find(col => col.name === 'customer_department');
      
      const paymentsColumns = await db.all(`PRAGMA table_info(payments)`);
      const paymentsColumn = paymentsColumns.find(col => col.name === 'customer_department');
      
      if (ticketsColumn && paymentsColumn) {
        console.log('✅ Migration completed successfully!');
        console.log('   - Column: customer_department');
        console.log('   - Type:', ticketsColumn.type);
        console.log('   - Tables: tickets, payments');
        console.log('   - Valid values:', HAITI_DEPARTMENTS.join(', '));
      } else {
        throw new Error('Column verification failed');
      }
    }
    
    // Show statistics
    const stats = await db.get(`
      SELECT 
        COUNT(*) as total_tickets,
        COUNT(customer_department) as tickets_with_department
      FROM tickets
    `);
    
    console.log('\n📊 Current statistics:');
    console.log(`   - Total tickets: ${stats.total_tickets}`);
    console.log(`   - Tickets with department: ${stats.tickets_with_department}`);
    console.log(`   - Tickets without department: ${stats.total_tickets - stats.tickets_with_department}`);
    
    if (stats.tickets_with_department === 0 && stats.total_tickets > 0) {
      console.log('\nℹ️  Note: Existing tickets do not have department information.');
      console.log('   This is expected. New tickets will include department data.');
    }
    
    console.log('\n✅ Migration complete!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    db.close();
  }
}

// Run migration if called directly
if (require.main === module) {
  migrate()
    .then(() => {
      console.log('Migration finished successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { migrate };
