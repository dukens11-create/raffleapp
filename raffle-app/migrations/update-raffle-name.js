/**
 * Migration: Update raffle name to GRATE GENYEN
 * Updates all raffles with old names to the new branding
 */

const db = require('../db');

async function updateRaffleName() {
  console.log('🔄 Starting raffle name migration...');
  
  try {
    // Update all raffles that have old names
    await db.run(`
      UPDATE raffles 
      SET name = 'GRATE GENYEN',
          description = 'Official Grate Genyen raffle for ticket sales'
      WHERE name IN ('Grand Raffle 2026', 'Default Raffle', 'Grate Genyen Raffle')
    `);
    
    console.log('✅ Raffle names updated');
    
    // Verify the update
    const raffles = await db.all('SELECT id, name, description FROM raffles');
    console.log('Current raffles:');
    raffles.forEach(raffle => {
      console.log(`  - ID ${raffle.id}: ${raffle.name}`);
    });
    
    console.log('✅ Migration completed successfully');
    
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
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Migration error:', error);
      process.exit(1);
    });
}

module.exports = updateRaffleName;
