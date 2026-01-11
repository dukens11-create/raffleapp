/**
 * Script to create test tickets for demonstrating the "last 100K available tickets" feature
 * This creates:
 * - 250 tickets per category (ABC, EFG, JKL, XYZ)
 * - Last 150 tickets of each category marked as available_online = 1
 * - First 100 tickets marked as sold
 * - Middle tickets left as AVAILABLE but not available_online
 */

const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./raffle.db');

async function query(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

async function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

async function createTestTickets() {
  try {
    console.log('🎫 Creating test tickets for demonstration...\n');
    
    // Get the raffle and categories
    const raffle = await query('SELECT id FROM raffles WHERE status = ? LIMIT 1', ['active']);
    if (!raffle || raffle.length === 0) {
      console.error('❌ No active raffle found');
      return;
    }
    const raffleId = raffle[0].id;
    console.log(`✅ Using raffle ID: ${raffleId}`);
    
    const categories = await query('SELECT * FROM ticket_categories WHERE raffle_id = ?', [raffleId]);
    console.log(`✅ Found ${categories.length} categories\n`);
    
    const TICKETS_PER_CATEGORY = 250;
    const SOLD_COUNT = 100;
    const ONLINE_AVAILABLE_START = 100; // Tickets 100-250 will be available online (last 150)
    
    for (const cat of categories) {
      console.log(`\n📊 Creating tickets for ${cat.category_name} (${cat.category_code})...`);
      
      for (let i = 1; i <= TICKETS_PER_CATEGORY; i++) {
        const ticketNumber = `${cat.category_code}-${String(i).padStart(6, '0')}`;
        const status = i <= SOLD_COUNT ? 'SOLD' : 'AVAILABLE';
        const availableOnline = i > ONLINE_AVAILABLE_START ? 1 : 0;
        const createdAt = new Date(Date.now() - (TICKETS_PER_CATEGORY - i) * 60000).toISOString(); // Stagger creation times
        
        await run(`
          INSERT OR IGNORE INTO tickets (
            raffle_id, category_id, ticket_number, category, price, 
            status, available_online, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `, [
          raffleId, cat.id, ticketNumber, cat.category_code, cat.price,
          status, availableOnline, createdAt
        ]);
      }
      
      console.log(`   ✅ Created ${TICKETS_PER_CATEGORY} tickets`);
      console.log(`      - ${SOLD_COUNT} SOLD`);
      console.log(`      - ${TICKETS_PER_CATEGORY - SOLD_COUNT} AVAILABLE`);
      console.log(`      - ${TICKETS_PER_CATEGORY - ONLINE_AVAILABLE_START} marked as available_online (last 150)`);
    }
    
    // Display summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 TICKET SUMMARY');
    console.log('='.repeat(60));
    
    const summary = await query(`
      SELECT 
        category,
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'SOLD' THEN 1 END) as sold,
        COUNT(CASE WHEN status = 'AVAILABLE' THEN 1 END) as available,
        COUNT(CASE WHEN available_online = 1 THEN 1 END) as online_available
      FROM tickets
      WHERE raffle_id = ?
      GROUP BY category
      ORDER BY category
    `, [raffleId]);
    
    console.table(summary);
    
    console.log('\n✅ Test tickets created successfully!');
    console.log('\nYou can now test the endpoint:');
    console.log('  curl http://localhost:10000/api/public/available-tickets?groupByCategory=true');
    console.log('  curl http://localhost:10000/api/public/available-tickets?category=ABC&limit=20');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    db.close();
  }
}

createTestTickets();
