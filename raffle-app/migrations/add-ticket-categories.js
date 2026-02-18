/**
 * Migration: Add 6 ticket categories to raffle_id=1
 * Adds Basic, Premium, Bronze, Silver, Gold, and Diamond categories
 */

const db = require('../db');

async function addTicketCategories() {
  console.log('🔄 Starting ticket categories migration...');
  
  try {
    // Check if raffle_id=1 exists
    const raffle = await db.get('SELECT id, name FROM raffles WHERE id = ?', [1]);
    
    if (!raffle) {
      console.log('⚠️  Raffle with id=1 does not exist. Skipping migration.');
      return;
    }
    
    console.log(`\n📋 Found raffle: ${raffle.name} (ID: ${raffle.id})`);
    
    // Check existing categories for raffle_id=1
    const existingCategories = await db.all(
      'SELECT category_code, category_name, price FROM ticket_categories WHERE raffle_id = ?',
      [1]
    );
    
    console.log(`\n📊 Current categories for raffle ${raffle.id}:`);
    if (existingCategories.length === 0) {
      console.log('  - None found');
    } else {
      existingCategories.forEach(cat => {
        console.log(`  - ${cat.category_code} (${cat.category_name}): ${cat.price} HTG`);
      });
    }
    
    // Define the 6 categories to add
    const categories = [
      { code: 'BAS', name: 'Basic', price: 50, total: 400000, color: '#10b981' },
      { code: 'PRM', name: 'Premium', price: 100, total: 400000, color: '#7c3aed' },
      { code: 'BRZ', name: 'Bronze', price: 250, total: 350000, color: '#ea580c' },
      { code: 'SLV', name: 'Silver', price: 500, total: 300000, color: '#94a3b8' },
      { code: 'GLD', name: 'Gold', price: 1000, total: 300000, color: '#fbbf24' },
      { code: 'DIA', name: 'Diamond', price: 5000, total: 250000, color: '#22d3ee' }
    ];
    
    let addedCount = 0;
    let skippedCount = 0;
    
    console.log(`\n🔄 Processing ${categories.length} categories...`);
    
    for (const cat of categories) {
      // Check if this category already exists
      const existing = existingCategories.find(e => e.category_code === cat.code);
      
      if (existing) {
        console.log(`  ⏭️  ${cat.code} (${cat.name}) already exists - skipping`);
        skippedCount++;
        continue;
      }
      
      // Insert the category
      await db.run(
        `INSERT INTO ticket_categories 
         (raffle_id, category_code, category_name, price, total_tickets, color) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [1, cat.code, cat.name, cat.price, cat.total, cat.color]
      );
      
      console.log(`  ✅ Added ${cat.code} (${cat.name}): ${cat.price} HTG`);
      addedCount++;
    }
    
    // Show summary
    console.log('\n📊 Migration Summary:');
    console.log(`  - Added: ${addedCount} categories`);
    console.log(`  - Skipped: ${skippedCount} categories (already exist)`);
    
    // Verify the final state
    const finalCategories = await db.all(
      'SELECT category_code, category_name, price FROM ticket_categories WHERE raffle_id = ? ORDER BY price ASC',
      [1]
    );
    
    console.log('\n✅ Final categories for raffle 1:');
    finalCategories.forEach(cat => {
      console.log(`  - ${cat.category_code} (${cat.category_name}): ${cat.price} HTG`);
    });
    
    console.log('\n✅ Migration completed successfully');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration if executed directly
if (require.main === module) {
  addTicketCategories()
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

module.exports = addTicketCategories;
