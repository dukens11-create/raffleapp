/**
 * Migration: Add all 6 ticket categories
 * Ensures ticket_categories table has all required categories for the purchase form dropdown
 */

const db = require('../db');

async function addAllSixCategories() {
  console.log('🔄 Starting ticket categories migration...');
  
  try {
    // Initialize schema first to ensure tables exist
    await db.initializeSchema();
    
    // Check current categories
    const existingCategories = await db.all('SELECT id, category_code, category_name, price FROM ticket_categories WHERE raffle_id = 1');
    console.log('\n📋 Current categories before migration:');
    if (existingCategories.length === 0) {
      console.log('  - No categories found');
    } else {
      existingCategories.forEach(cat => {
        console.log(`  - ${cat.category_code} (${cat.category_name}): ${cat.price} HTG`);
      });
    }
    
    // Define all 6 required categories
    const categories = [
      { code: 'BAS', name: 'Basic', price: 50, total: 400000, color: '#10b981' },
      { code: 'PRM', name: 'Premium', price: 100, total: 400000, color: '#7c3aed' },
      { code: 'BRZ', name: 'Bronze', price: 250, total: 350000, color: '#ea580c' },
      { code: 'SLV', name: 'Silver', price: 500, total: 300000, color: '#94a3b8' },
      { code: 'GLD', name: 'Gold', price: 1000, total: 300000, color: '#fbbf24' },
      { code: 'DIA', name: 'Diamond', price: 5000, total: 250000, color: '#22d3ee' }
    ];
    
    console.log('\n🔄 Adding missing categories...');
    let addedCount = 0;
    
    for (const cat of categories) {
      // Check if category already exists
      const existing = await db.get(
        'SELECT id FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
        [1, cat.code]
      );
      
      if (existing) {
        console.log(`  ⏭️  ${cat.code} (${cat.name}) already exists - skipping`);
      } else {
        // Add the category
        await db.run(
          `INSERT INTO ticket_categories 
           (raffle_id, category_code, category_name, price, total_tickets, color) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [1, cat.code, cat.name, cat.price, cat.total, cat.color]
        );
        console.log(`  ✅ Added ${cat.code} (${cat.name}): ${cat.price} HTG`);
        addedCount++;
      }
    }
    
    // Verify final state
    const finalCategories = await db.all('SELECT id, category_code, category_name, price FROM ticket_categories WHERE raffle_id = 1');
    console.log('\n✅ Categories after migration:');
    finalCategories.forEach(cat => {
      console.log(`  - ${cat.category_code} (${cat.category_name}): ${cat.price} HTG`);
    });
    
    console.log(`\n✅ Migration completed successfully! Added ${addedCount} new categor${addedCount === 1 ? 'y' : 'ies'}.`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration if executed directly
if (require.main === module) {
  addAllSixCategories()
    .then(() => {
      db.close();
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration error:', error);
      db.close();
      process.exit(1);
    });
}

module.exports = addAllSixCategories;
