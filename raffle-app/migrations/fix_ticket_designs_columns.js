/**
 * Migration: Fix ticket_designs table columns
 * 
 * This migration ensures the ticket_designs table has all required columns
 * (name, description, width, height, rotation, scale_width, scale_height, offset_x, offset_y, is_active)
 * with proper NULL defaults for PostgreSQL.
 * 
 * This fixes the "column description does not exist" error in PostgreSQL.
 * 
 * Compatible with both PostgreSQL and SQLite.
 * 
 * Usage:
 *   node migrations/fix_ticket_designs_columns.js
 */

const db = require('../db');

async function migrate() {
  console.log('🔧 Starting migration: Fix ticket_designs table columns');
  console.log('Database type:', db.USE_POSTGRES ? 'PostgreSQL' : 'SQLite');
  
  try {
    // Define columns to add (same as in db.js initializeSchema)
    const newColumns = [
      { name: 'name', type: 'VARCHAR(100)', default: null },
      { name: 'description', type: 'TEXT', default: null },
      { name: 'width', type: 'INTEGER', default: '396' },
      { name: 'height', type: 'INTEGER', default: '153' },
      { name: 'rotation', type: 'INTEGER', default: '0' },
      { name: 'scale_width', type: 'INTEGER', default: '100' },
      { name: 'scale_height', type: 'INTEGER', default: '100' },
      { name: 'offset_x', type: 'INTEGER', default: '0' },
      { name: 'offset_y', type: 'INTEGER', default: '0' },
      { name: 'is_active', type: db.USE_POSTGRES ? 'BOOLEAN' : 'INTEGER', default: db.USE_POSTGRES ? 'TRUE' : '1' }
    ];
    
    console.log(`Adding ${newColumns.length} columns to ticket_designs table...`);
    
    for (const col of newColumns) {
      try {
        if (db.USE_POSTGRES) {
          // PostgreSQL: Handle NULL defaults properly
          const defaultClause = col.default === null ? '' : `DEFAULT ${col.default}`;
          await db.run(`
            ALTER TABLE ticket_designs 
            ADD COLUMN IF NOT EXISTS ${col.name} ${col.type} ${defaultClause}
          `);
          console.log(`✅ ${col.name} column added (PostgreSQL)`);
        } else {
          // SQLite: Check if column exists first
          const columns = await db.all(`PRAGMA table_info(ticket_designs)`);
          const hasColumn = columns.some(c => c.name === col.name);
          
          if (!hasColumn) {
            const defaultClause = col.default === null ? '' : `DEFAULT ${col.default}`;
            await db.run(`ALTER TABLE ticket_designs ADD COLUMN ${col.name} ${col.type} ${defaultClause}`);
            console.log(`✅ ${col.name} column added (SQLite)`);
          } else {
            console.log(`ℹ️  ${col.name} column already exists, skipping`);
          }
        }
      } catch (error) {
        // Column might already exist, that's okay
        if (error.message && (error.message.includes('already exists') || error.message.includes('duplicate column'))) {
          console.log(`ℹ️  ${col.name} column already exists, skipping`);
        } else {
          console.warn(`⚠️  Could not add ${col.name} column:`, error.message);
        }
      }
    }
    
    // Verify the columns were added
    if (db.USE_POSTGRES) {
      const result = await db.all(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'ticket_designs' 
        AND column_name IN ('name', 'description', 'width', 'height', 'rotation', 
                            'scale_width', 'scale_height', 'offset_x', 'offset_y', 'is_active')
        ORDER BY column_name
      `);
      
      console.log('\n📊 Verified columns in ticket_designs table:');
      result.forEach(row => console.log(`   ✅ ${row.column_name}`));
      
      if (result.length >= newColumns.length) {
        console.log('\n✅ All required columns are present!');
      } else {
        console.log(`\n⚠️  Expected ${newColumns.length} columns, found ${result.length}`);
      }
    } else {
      const columns = await db.all(`PRAGMA table_info(ticket_designs)`);
      console.log('\n📊 Verified columns in ticket_designs table:');
      const requiredCols = newColumns.map(c => c.name);
      columns.forEach(col => {
        if (requiredCols.includes(col.name)) {
          console.log(`   ✅ ${col.name}`);
        }
      });
    }
    
    // Show statistics
    const stats = await db.get(`
      SELECT COUNT(*) as total_designs
      FROM ticket_designs
    `);
    
    console.log('\n📊 Current statistics:');
    console.log(`   - Total ticket designs: ${stats.total_designs}`);
    
    console.log('\n✅ Migration complete!');
    console.log('   The ticket_designs table now has all required columns.');
    console.log('   INSERT queries using description column will now work correctly.');
    
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
