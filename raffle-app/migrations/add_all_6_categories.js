/**
 * Migration: Add All 6 Ticket Categories
 * Ensures all 6 ticket categories exist in the database:
 * BAS, PRM, BRZ, SLV, GLD, DIA
 */

const db = require('../db');

async function addAll6Categories() {
  console.log('🎟️  Starting 6 categories migration...');
  
  try {
    // Step 0: Initialize database schema if needed
    console.log('📋 Initializing database schema...');
    await db.initializeSchema();
    
    // Step 1: Check if default raffle exists
    const existingRaffle = await db.get('SELECT * FROM raffles WHERE id = 1');
    
    if (!existingRaffle) {
      console.log('📋 Default raffle (id=1) does not exist. Creating it...');
      await db.run(
        `INSERT INTO raffles (name, status, description, total_tickets) 
         VALUES (?, ?, ?, ?)`,
        ['GRATE GENYEN', 'active', 'Official Grate Genyen raffle for ticket sales', 2000000]
      );
      console.log('✅ Default raffle created');
    } else {
      console.log(`📋 Default raffle found: "${existingRaffle.name}" (id=${existingRaffle.id})`);
    }
    
    // Step 2: Define all 6 required categories
    const categories = [
      { code: 'BAS', name: 'Basic', price: 50, total: 400000, color: '#10b981' },
      { code: 'PRM', name: 'Premium', price: 100, total: 400000, color: '#7c3aed' },
      { code: 'BRZ', name: 'Bronze', price: 250, total: 350000, color: '#ea580c' },
      { code: 'SLV', name: 'Silver', price: 500, total: 300000, color: '#94a3b8' },
      { code: 'GLD', name: 'Gold', price: 1000, total: 300000, color: '#fbbf24' },
      { code: 'DIA', name: 'Diamond', price: 5000, total: 250000, color: '#22d3ee' }
    ];
    
    console.log('\n🔄 Processing categories (upsert logic)...');
    
    let addedCount = 0;
    let updatedCount = 0;
    
    // Step 3: Upsert each category
    for (const cat of categories) {
      // Check if category already exists
      const existing = await db.get(
        'SELECT * FROM ticket_categories WHERE raffle_id = 1 AND category_code = ?',
        [cat.code]
      );
      
      if (existing) {
        // Update existing category
        await db.run(
          `UPDATE ticket_categories 
           SET category_name = ?,
               price = ?,
               total_tickets = ?,
               color = ?
           WHERE raffle_id = 1 AND category_code = ?`,
          [cat.name, cat.price, cat.total, cat.color, cat.code]
        );
        console.log(`  ✏️  Updated: ${cat.code} (${cat.name}) - ${cat.price} HTG`);
        updatedCount++;
      } else {
        // Insert new category
        await db.run(
          `INSERT INTO ticket_categories 
           (raffle_id, category_code, category_name, price, total_tickets, color) 
           VALUES (?, ?, ?, ?, ?, ?)`,
          [1, cat.code, cat.name, cat.price, cat.total, cat.color]
        );
        console.log(`  ➕ Added: ${cat.code} (${cat.name}) - ${cat.price} HTG`);
        addedCount++;
      }
    }
    
    // Step 4: Verify all 6 categories exist
    console.log('\n🔍 Verifying categories...');
    const allCategories = await db.all(
      'SELECT category_code, category_name, price, total_tickets, color FROM ticket_categories WHERE raffle_id = 1 ORDER BY category_code'
    );
    
    console.log(`\n✅ Total categories in database: ${allCategories.length}`);
    
    if (allCategories.length === 6) {
      console.log('✅ SUCCESS: All 6 categories are present!\n');
      console.log('📊 Category Summary:');
      allCategories.forEach(cat => {
        console.log(`   - ${cat.category_code} (${cat.category_name}): ${cat.price} HTG - ${cat.total_tickets.toLocaleString()} tickets - ${cat.color}`);
      });
      
      // Calculate totals
      const totalTickets = allCategories.reduce((sum, cat) => sum + cat.total_tickets, 0);
      const totalRevenue = allCategories.reduce((sum, cat) => sum + (cat.price * cat.total_tickets), 0);
      console.log(`\n💰 Total capacity: ${totalTickets.toLocaleString()} tickets`);
      console.log(`💰 Potential revenue: ${totalRevenue.toLocaleString()} HTG`);
    } else {
      console.warn(`⚠️  WARNING: Expected 6 categories but found ${allCategories.length}`);
      console.log('Categories found:');
      allCategories.forEach(cat => {
        console.log(`   - ${cat.category_code} (${cat.category_name})`);
      });
    }
    
    console.log('\n📈 Migration Summary:');
    console.log(`   - Categories added: ${addedCount}`);
    console.log(`   - Categories updated: ${updatedCount}`);
    console.log('   - Total categories: 6');
    console.log('\n✅ Migration completed successfully!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration if executed directly
if (require.main === module) {
  addAll6Categories()
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
