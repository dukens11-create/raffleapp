const db = require('../db');

async function addAllCategories() {
  console.log('🎫 Adding all 6 ticket categories...');
  
  // Initialize schema if needed (creates tables if they don't exist)
  await db.initializeSchema();
  
  // Check if raffle exists
  const raffle = await db.get('SELECT id FROM raffles WHERE id = 1');
  if (!raffle) {
    console.log('❌ No raffle with id=1 found. Creating default raffle...');
    await db.run(
      `INSERT INTO raffles (id, name, status, description, total_tickets) 
       VALUES (?, ?, ?, ?, ?)`,
      [1, 'GRATE GENYEN', 'active', 'Official Grate Genyen raffle for ticket sales', 2000000]
    );
  }
  
  // Define all 6 categories
  const categories = [
    { code: 'BAS', name: 'Basic', price: 50, total: 400000, color: '#10b981' },
    { code: 'PRM', name: 'Premium', price: 100, total: 400000, color: '#7c3aed' },
    { code: 'BRZ', name: 'Bronze', price: 250, total: 350000, color: '#ea580c' },
    { code: 'SLV', name: 'Silver', price: 500, total: 300000, color: '#94a3b8' },
    { code: 'GLD', name: 'Gold', price: 1000, total: 300000, color: '#fbbf24' },
    { code: 'DIA', name: 'Diamond', price: 5000, total: 250000, color: '#22d3ee' }
  ];
  
  // Add each category
  for (const cat of categories) {
    // Check if category already exists
    const existing = await db.get(
      'SELECT id FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
      [1, cat.code]
    );
    
    if (existing) {
      // Check if update is needed
      const current = await db.get(
        'SELECT category_name, price, total_tickets, color FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
        [1, cat.code]
      );
      
      const needsUpdate = current.category_name !== cat.name ||
                          current.price !== cat.price ||
                          current.total_tickets !== cat.total ||
                          current.color !== cat.color;
      
      if (needsUpdate) {
        await db.run(
          `UPDATE ticket_categories 
           SET category_name = ?, price = ?, total_tickets = ?, color = ?
           WHERE raffle_id = ? AND category_code = ?`,
          [cat.name, cat.price, cat.total, cat.color, 1, cat.code]
        );
        console.log(`✅ Category ${cat.code} (${cat.name}) updated with latest values`);
      } else {
        console.log(`✅ Category ${cat.code} (${cat.name}) already exists with correct values`);
      }
    } else {
      // Insert new category
      await db.run(
        `INSERT INTO ticket_categories 
         (raffle_id, category_code, category_name, price, total_tickets, color) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [1, cat.code, cat.name, cat.price, cat.total, cat.color]
      );
      console.log(`✅ Added category ${cat.code} (${cat.name}) - ${cat.price} HTG`);
    }
  }
  
  // Verify all categories
  const allCategories = await db.all(
    'SELECT category_code, category_name, price FROM ticket_categories WHERE raffle_id = ? ORDER BY category_code',
    [1]
  );
  
  console.log('\n📋 All categories in database:');
  allCategories.forEach(cat => {
    console.log(`   ${cat.category_code} (${cat.category_name}) - ${cat.price} HTG`);
  });
  console.log(`\n✅ Total categories: ${allCategories.length}`);
  
  if (allCategories.length !== 6) {
    console.log(`❌ WARNING: Expected 6 categories but found ${allCategories.length}`);
    console.log('   This may cause issues with the ticket purchase form.');
    console.log('   Please review the migration output and ensure all categories were created successfully.');
    console.log('   You may need to manually check the ticket_categories table.');
  }
}

// Run migration
if (require.main === module) {
  addAllCategories()
    .then(() => {
      console.log('\n✅ Migration complete');
      db.close();
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Migration failed:', error);
      db.close();
      process.exit(1);
    });
} else {
  // When required as a module (e.g., from server.js), export without db.close()
  module.exports = addAllCategories;
}
