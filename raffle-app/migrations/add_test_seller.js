/**
 * Script: Add test/dummy seller record
 * 
 * This script adds a test seller to the database to ensure the seller UI
 * and API endpoints can display at least one seller.
 * 
 * Usage:
 *   node migrations/add_test_seller.js
 */

const db = require('../db');
const bcrypt = require('bcrypt');

async function addTestSeller() {
  console.log('🔧 Adding test seller to database');
  console.log('Database type:', db.USE_POSTGRES ? 'PostgreSQL' : 'SQLite');
  
  try {
    // Check if test seller already exists
    const existingSeller = await db.get(
      "SELECT id, name, phone FROM users WHERE phone = ?",
      ['5551234567']
    );
    
    if (existingSeller) {
      console.log('ℹ️  Test seller already exists:');
      console.log(`   - ID: ${existingSeller.id}`);
      console.log(`   - Name: ${existingSeller.name}`);
      console.log(`   - Phone: ${existingSeller.phone}`);
      console.log('\n✅ No action needed.');
      return;
    }
    
    // Hash the password
    const password = 'seller123';
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Insert test seller
    await db.run(
      `INSERT INTO users (name, phone, password, role, registered_via) 
       VALUES (?, ?, ?, ?, ?)`,
      ['Test Seller', '5551234567', hashedPassword, 'seller', 'manual']
    );
    
    console.log('✅ Test seller added successfully!');
    console.log('\n📋 Test Seller Details:');
    console.log('   - Name: Test Seller');
    console.log('   - Phone: 5551234567');
    console.log('   - Password: seller123');
    console.log('   - Role: seller');
    
    // Verify the seller was added
    const seller = await db.get(
      "SELECT id, name, phone, role, created_at FROM users WHERE phone = ?",
      ['5551234567']
    );
    
    if (seller) {
      console.log('\n✅ Verification successful:');
      console.log(`   - Seller ID: ${seller.id}`);
      console.log(`   - Created at: ${seller.created_at}`);
    }
    
    // Show total seller count
    const sellerCount = await db.get(
      "SELECT COUNT(*) as count FROM users WHERE role = 'seller'"
    );
    
    console.log(`\n📊 Total sellers in database: ${sellerCount.count}`);
    
  } catch (error) {
    console.error('❌ Failed to add test seller:', error);
    throw error;
  } finally {
    db.close();
  }
}

// Run if called directly
if (require.main === module) {
  addTestSeller()
    .then(() => {
      console.log('\n✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Script failed:', error);
      process.exit(1);
    });
}

module.exports = { addTestSeller };
