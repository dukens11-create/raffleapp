/**
 * Migration: Update raffle name to GRATE GENYEN
 * Updates all raffles with old names to the new branding
 */

const db = require('../db');

async function updateRaffleName() {
  console.log('🔄 Starting raffle name migration...');
  
  try {
    // Check current state before migration
    const rafflesBefore = await db.all('SELECT id, name, description FROM raffles');
    console.log('\n📋 Current raffles before migration:');
    rafflesBefore.forEach(raffle => {
      console.log(`  - ID ${raffle.id}: ${raffle.name}`);
    });
    
    const toUpdate = rafflesBefore.filter(r => 
      ['Grand Raffle 2026', 'Default Raffle', 'Grate Genyen Raffle'].includes(r.name)
    );
    
    if (toUpdate.length === 0) {
      console.log('\n✅ No raffles need updating - all raffles already have the correct name');
      return;
    }
    
    console.log(`\n🔄 Updating ${toUpdate.length} raffle(s)...`);
    
    // Update all raffles that have old names
    await db.run(`
      UPDATE raffles 
      SET name = 'GRATE GENYEN',
          description = 'Official Grate Genyen raffle for ticket sales'
      WHERE name IN ('Grand Raffle 2026', 'Default Raffle', 'Grate Genyen Raffle')
    `);
    
    // Verify the update
    const rafflesAfter = await db.all('SELECT id, name, description FROM raffles');
    console.log('\n✅ Raffles after migration:');
    rafflesAfter.forEach(raffle => {
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
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Migration error:', error);
      process.exit(1);
    });
}

module.exports = updateRaffleName;
