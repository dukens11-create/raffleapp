/**
 * Migration: Update raffle name to GRATE GENYEN
 * Updates all raffles with old names to the new branding
 * 
 * Compatible with both PostgreSQL and SQLite.
 * 
 * Usage:
 *   node migrations/update-raffle-name.js
 */

const db = require('../db');

async function updateRaffleName() {
  console.log('🔄 Starting raffle name migration...');
  console.log('Database type:', db.USE_POSTGRES ? 'PostgreSQL' : 'SQLite');
  
  try {
    // Update all raffles that have old names
    const result = await db.run(`
      UPDATE raffles 
      SET name = 'GRATE GENYEN',
          description = 'Official Grate Genyen raffle for ticket sales'
      WHERE name IN ('Grand Raffle 2026', 'Default Raffle', 'Grate Genyen Raffle', 'Default Raffle 2024')
    `);
    
    const updatedCount = db.USE_POSTGRES ? result.rowCount : result.changes;
    console.log(`✅ Updated ${updatedCount || 0} raffle record(s)`);
    
    // Verify the update
    const raffles = await db.all('SELECT id, name, description FROM raffles');
    console.log('\n📋 Current raffles:');
    raffles.forEach(raffle => {
      console.log(`  - ID ${raffle.id}: ${raffle.name}`);
    });
    
    console.log('\n✅ Migration completed successfully');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    db.close();
  }
}

// Run migration if executed directly
if (require.main === module) {
  updateRaffleName()
    .then(() => {
      console.log('Migration finished successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration error:', error);
      process.exit(1);
    });
}

module.exports = updateRaffleName;
