/**
 * Migration: Add all 6 ticket categories to the raffle system
 * Creates raffle if missing and ensures all 6 categories exist with correct values
 */

const db = require('../db');

async function addAll6Categories() {
  console.log('🔄 Starting ticket categories migration...');
  
  try {
    // Check if raffle with id=1 exists
    const existingRaffle = await db.get('SELECT id, name FROM raffles WHERE id = 1');
    
    if (!existingRaffle) {
      console.log('📝 Raffle with id=1 does not exist, creating it...');
      await db.run(
        `INSERT INTO raffles (id, name, status, description, total_tickets) 
         VALUES (?, ?, ?, ?, ?)`,
        [1, 'GRATE GENYEN', 'active', 'Official Grate Genyen raffle for ticket sales', 2000000]
      );
      console.log('✅ Created raffle with id=1: GRATE GENYEN');
    } else {
      console.log(`✅ Raffle with id=1 already exists: ${existingRaffle.name}`);
    }
    
    // Define all 6 ticket categories with correct values
    const categories = [
      { code: 'BAS', name: 'Basic', price: 50, total: 400000, color: '#10b981' },
      { code: 'PRM', name: 'Premium', price: 100, total: 400000, color: '#7c3aed' },
      { code: 'BRZ', name: 'Bronze', price: 250, total: 350000, color: '#ea580c' },
      { code: 'SLV', name: 'Silver', price: 500, total: 300000, color: '#94a3b8' },
      { code: 'GLD', name: 'Gold', price: 1000, total: 300000, color: '#fbbf24' },
      { code: 'DIA', name: 'Diamond', price: 5000, total: 250000, color: '#22d3ee' }
    ];
    
    console.log('\n📋 Processing ticket categories...');
    let insertedCount = 0;
    let updatedCount = 0;
    let unchangedCount = 0;
    
    for (const cat of categories) {
      // Check if category already exists
      const existing = await db.get(
        'SELECT * FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
        [1, cat.code]
      );
      
      if (!existing) {
        // Insert new category
        await db.run(
          `INSERT INTO ticket_categories 
           (raffle_id, category_code, category_name, price, total_tickets, color) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [1, cat.code, cat.name, cat.price, cat.total, cat.color]
        );
        console.log(`  ✅ Inserted ${cat.code} (${cat.name}): ${cat.price} HTG - ${cat.total.toLocaleString()} tickets - ${cat.color}`);
        insertedCount++;
      } else {
        // Check if values need updating
        const needsUpdate = 
          existing.category_name !== cat.name ||
          parseFloat(existing.price) !== cat.price ||
          existing.total_tickets !== cat.total ||
          existing.color !== cat.color;
        
        if (needsUpdate) {
          // Update existing category with correct values
          await db.run(
            `UPDATE ticket_categories 
             SET category_name = ?, price = ?, total_tickets = ?, color = ?
             WHERE raffle_id = ? AND category_code = ?`,
            [cat.name, cat.price, cat.total, cat.color, 1, cat.code]
          );
          console.log(`  🔄 Updated ${cat.code} (${cat.name}): ${cat.price} HTG - ${cat.total.toLocaleString()} tickets - ${cat.color}`);
          updatedCount++;
        } else {
          console.log(`  ✓ ${cat.code} (${cat.name}): already correct`);
          unchangedCount++;
        }
      }
    }
    
    // Verify final state
    const allCategories = await db.all(
      'SELECT category_code, category_name, price, total_tickets, color FROM ticket_categories WHERE raffle_id = 1 ORDER BY category_code'
    );
    
    console.log('\n📊 Migration Summary:');
    console.log(`  - Inserted: ${insertedCount} categories`);
    console.log(`  - Updated: ${updatedCount} categories`);
    console.log(`  - Unchanged: ${unchangedCount} categories`);
    console.log(`  - Total categories in database: ${allCategories.length}`);
    
    console.log('\n✅ Final ticket categories for raffle id=1:');
    allCategories.forEach(cat => {
      console.log(`   - ${cat.category_code} (${cat.category_name}): ${cat.price} HTG - ${cat.total_tickets.toLocaleString()} tickets - ${cat.color}`);
    });
    
    console.log('\n✅ Migration completed successfully');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration if executed directly
if (require.main === module) {
  // Initialize database first to ensure tables exist
  db.initializeSchema()
    .then(() => addAll6Categories())
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

module.exports = addAll6Categories;
