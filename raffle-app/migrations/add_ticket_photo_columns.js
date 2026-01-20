/**
 * Migration: Add ticket photo columns to tickets table
 * 
 * This migration adds support for storing ticket photo paths and timestamps
 * to enable admin verification of physical tickets after they've been sold.
 * 
 * Compatible with both PostgreSQL and SQLite.
 * 
 * Usage:
 *   node migrations/add_ticket_photo_columns.js
 */

const db = require('../db');

async function migrate() {
  console.log('🔧 Starting migration: Add ticket photo columns');
  console.log('Database type:', db.USE_POSTGRES ? 'PostgreSQL' : 'SQLite');
  
  try {
    // Migrate tickets table
    if (db.USE_POSTGRES) {
      // PostgreSQL: Use ALTER TABLE with IF NOT EXISTS
      console.log('Adding ticket_photo_path column to tickets table (PostgreSQL)...');
      await db.run(`
        ALTER TABLE tickets 
        ADD COLUMN IF NOT EXISTS ticket_photo_path TEXT
      `);
      console.log('✅ ticket_photo_path column added successfully');
      
      console.log('Adding ticket_photo_uploaded_at column to tickets table (PostgreSQL)...');
      await db.run(`
        ALTER TABLE tickets 
        ADD COLUMN IF NOT EXISTS ticket_photo_uploaded_at TIMESTAMP
      `);
      console.log('✅ ticket_photo_uploaded_at column added successfully');
      
      // Create index for query optimization
      console.log('Creating index on ticket_photo_path...');
      await db.run(`
        CREATE INDEX IF NOT EXISTS idx_tickets_photo_path 
        ON tickets(ticket_photo_path)
      `);
      console.log('✅ Index created successfully');
      
    } else {
      // SQLite: Try to add columns directly (they'll fail silently if they exist)
      console.log('Adding ticket_photo_path column to tickets table (SQLite)...');
      try {
        await db.run(`ALTER TABLE tickets ADD COLUMN ticket_photo_path TEXT`);
        console.log('✅ ticket_photo_path column added successfully');
      } catch (error) {
        if (error.message && error.message.includes('duplicate column')) {
          console.log('ℹ️  ticket_photo_path column already exists, skipping');
        } else {
          throw error;
        }
      }
      
      console.log('Adding ticket_photo_uploaded_at column to tickets table (SQLite)...');
      try {
        await db.run(`ALTER TABLE tickets ADD COLUMN ticket_photo_uploaded_at DATETIME`);
        console.log('✅ ticket_photo_uploaded_at column added successfully');
      } catch (error) {
        if (error.message && error.message.includes('duplicate column')) {
          console.log('ℹ️  ticket_photo_uploaded_at column already exists, skipping');
        } else {
          throw error;
        }
      }
      
      // Create index for query optimization
      console.log('Creating index on ticket_photo_path...');
      await db.run(`
        CREATE INDEX IF NOT EXISTS idx_tickets_photo_path 
        ON tickets(ticket_photo_path)
      `);
      console.log('✅ Index created successfully');
    }
    
    // Verify the columns were added
    if (db.USE_POSTGRES) {
      const photoPathResult = await db.get(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'ticket_photo_path'
      `);
      
      const photoUploadedAtResult = await db.get(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'ticket_photo_uploaded_at'
      `);
      
      if (photoPathResult && photoUploadedAtResult) {
        console.log('✅ Migration completed successfully!');
        console.log('   - Column 1: ticket_photo_path (TEXT)');
        console.log('   - Column 2: ticket_photo_uploaded_at (TIMESTAMP)');
        console.log('   - Index: idx_tickets_photo_path');
      } else {
        throw new Error('Column verification failed');
      }
    } else {
      // For SQLite, we'll assume success since we handled errors above
      console.log('✅ Migration completed successfully!');
      console.log('   - Column 1: ticket_photo_path (TEXT)');
      console.log('   - Column 2: ticket_photo_uploaded_at (DATETIME)');
      console.log('   - Index: idx_tickets_photo_path');
    }
    
    // Show statistics
    const stats = await db.get(`
      SELECT 
        COUNT(*) as total_tickets,
        COUNT(ticket_photo_path) as tickets_with_photo
      FROM tickets
    `);
    
    console.log('\n📊 Current statistics:');
    console.log(`   - Total tickets: ${stats.total_tickets}`);
    console.log(`   - Tickets with photo: ${stats.tickets_with_photo}`);
    console.log(`   - Tickets without photo: ${stats.total_tickets - stats.tickets_with_photo}`);
    
    if (stats.tickets_with_photo === 0 && stats.total_tickets > 0) {
      console.log('\nℹ️  Note: Existing tickets do not have photo information.');
      console.log('   This is expected. New tickets will include photo data.');
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
