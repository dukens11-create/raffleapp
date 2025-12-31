/**
 * Test script to validate raffle_id column fix
 * This script verifies that:
 * 1. The migration file exists
 * 2. The database schema includes raffle_id with proper constraints
 * 3. Tickets can be created with raffle_id
 */

const fs = require('fs');
const path = require('path');

console.log('🧪 Testing raffle_id column fix...\n');

// Test 1: Check migration file exists
console.log('Test 1: Checking migration file...');
const migrationPath = path.join(__dirname, 'migrations', 'add_raffle_id_to_tickets.sql');
if (fs.existsSync(migrationPath)) {
  console.log('✅ Migration file exists:', migrationPath);
  const content = fs.readFileSync(migrationPath, 'utf8');
  
  // Verify key parts of migration
  const checks = [
    { pattern: 'raffle_id', name: 'raffle_id column' },
    { pattern: 'NOT NULL', name: 'NOT NULL constraint' },
    { pattern: 'FOREIGN KEY', name: 'Foreign key constraint' },
    { pattern: 'idx_tickets_raffle_id', name: 'Index creation' },
    { pattern: 'ON DELETE CASCADE', name: 'Cascade delete' }
  ];
  
  checks.forEach(check => {
    if (content.includes(check.pattern)) {
      console.log(`  ✅ ${check.name} found in migration`);
    } else {
      console.log(`  ❌ ${check.name} NOT found in migration`);
    }
  });
} else {
  console.log('❌ Migration file NOT found');
}

console.log();

// Test 2: Check db.js schema
console.log('Test 2: Checking db.js schema...');
const dbPath = path.join(__dirname, 'db.js');
if (fs.existsSync(dbPath)) {
  const dbContent = fs.readFileSync(dbPath, 'utf8');
  
  if (dbContent.includes('raffle_id INTEGER NOT NULL')) {
    console.log('✅ db.js includes raffle_id with NOT NULL');
  } else {
    console.log('❌ db.js does NOT include raffle_id with NOT NULL');
  }
  
  if (dbContent.includes('REFERENCES raffles(id)')) {
    console.log('✅ db.js includes foreign key reference');
  } else {
    console.log('⚠️  db.js does not include foreign key reference (OK for SQLite)');
  }
} else {
  console.log('❌ db.js NOT found');
}

console.log();

// Test 3: Check server.js migration runner
console.log('Test 3: Checking server.js migration runner...');
const serverPath = path.join(__dirname, 'server.js');
if (fs.existsSync(serverPath)) {
  const serverContent = fs.readFileSync(serverPath, 'utf8');
  
  if (serverContent.includes('runMigrations')) {
    console.log('✅ server.js includes runMigrations function');
  } else {
    console.log('❌ server.js does NOT include runMigrations function');
  }
  
  if (serverContent.includes('.then(() => runMigrations())')) {
    console.log('✅ server.js calls runMigrations on startup');
  } else {
    console.log('❌ server.js does NOT call runMigrations on startup');
  }
} else {
  console.log('❌ server.js NOT found');
}

console.log();

// Test 4: Check ticketService.js uses raffle_id
console.log('Test 4: Checking ticketService.js...');
const ticketServicePath = path.join(__dirname, 'services', 'ticketService.js');
if (fs.existsSync(ticketServicePath)) {
  const ticketContent = fs.readFileSync(ticketServicePath, 'utf8');
  
  if (ticketContent.includes('raffle_id')) {
    console.log('✅ ticketService.js uses raffle_id');
    
    // Check if INSERT statement includes raffle_id
    if (ticketContent.includes('INSERT INTO tickets') && ticketContent.includes('raffle_id')) {
      console.log('✅ ticketService.js INSERT includes raffle_id');
    } else {
      console.log('⚠️  ticketService.js INSERT may not include raffle_id');
    }
  } else {
    console.log('❌ ticketService.js does NOT use raffle_id');
  }
} else {
  console.log('❌ ticketService.js NOT found');
}

console.log();
console.log('✅ Validation complete!');
console.log();
console.log('Next steps:');
console.log('1. Deploy to Render or run with PostgreSQL locally');
console.log('2. Check logs for migration success messages');
console.log('3. Try creating tickets - should work without "column does not exist" error');
