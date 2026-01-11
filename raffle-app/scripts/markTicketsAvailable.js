/**
 * Script: Mark Last 100,000 Tickets Per Category as Available Online
 * 
 * USAGE:
 *   node scripts/markTicketsAvailable.js [options]
 * 
 * DESCRIPTION:
 *   This script makes tickets available for purchase in the buyer portal by:
 *   1. Finding all ticket categories in the database
 *   2. For each category, selecting the last 100,000 tickets (by created_at DESC)
 *   3. Updating those tickets to set:
 *      - available_online = true
 *      - status = 'AVAILABLE' (only if currently not 'SOLD')
 * 
 * CONFIGURATION:
 *   Database connection is configured via environment variables:
 *   - DATABASE_URL: PostgreSQL connection string (if using PostgreSQL)
 *   - If DATABASE_URL is not set, SQLite will be used (raffle.db)
 * 
 * OPTIONS:
 *   --dry-run    Show what would be updated without making changes
 *   --reset      Mark all tickets as NOT available online (reverses the operation)
 *   --limit=N    Override the default 100,000 ticket limit per category
 * 
 * EXAMPLES:
 *   # Preview changes without applying them
 *   node scripts/markTicketsAvailable.js --dry-run
 * 
 *   # Apply changes to make 100,000 tickets per category available online
 *   node scripts/markTicketsAvailable.js
 * 
 *   # Make only 50,000 tickets per category available online
 *   node scripts/markTicketsAvailable.js --limit=50000
 * 
 *   # Reset all tickets to not available online
 *   node scripts/markTicketsAvailable.js --reset
 * 
 * NOTES:
 *   - The script processes tickets in batches for memory efficiency
 *   - For each category, it selects the NEWEST tickets by created_at timestamp
 *   - Tickets that are already SOLD will have their status preserved
 *   - Progress is displayed for each category
 *   - A summary table is shown at the end
 */

const db = require('../db');

// Parse command line arguments
const DRY_RUN = process.argv.includes('--dry-run');
const RESET = process.argv.includes('--reset');

// Parse --limit parameter
let TICKETS_PER_CATEGORY = 100000;
const limitArg = process.argv.find(arg => arg.startsWith('--limit='));
if (limitArg) {
  const limitValue = parseInt(limitArg.split('=')[1]);
  if (limitValue && limitValue > 0) {
    TICKETS_PER_CATEGORY = limitValue;
  } else {
    console.error('❌ Invalid --limit value. Must be a positive number.');
    process.exit(1);
  }
}

/**
 * Get all distinct ticket categories from the database
 */
async function getCategories() {
  return await db.all(`
    SELECT DISTINCT category, COUNT(*) as total_tickets
    FROM tickets
    WHERE category IS NOT NULL AND category != ''
    GROUP BY category
    ORDER BY category
  `);
}

/**
 * Get ticket IDs for the last N tickets in a category (by created_at DESC)
 */
async function getLatestTicketIds(category, limit) {
  return await db.all(`
    SELECT id
    FROM tickets
    WHERE category = ?
    ORDER BY created_at DESC
    LIMIT ?
  `, [category, limit]);
}

/**
 * Update tickets to be available online
 */
async function markTicketsAvailable(ticketIds) {
  if (ticketIds.length === 0) return 0;
  
  // Build a list of placeholders for the IN clause
  const placeholders = ticketIds.map(() => '?').join(',');
  
  // Update tickets: set available_online=true and status='AVAILABLE' (unless already SOLD)
  const sql = `
    UPDATE tickets
    SET 
      available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'},
      status = CASE 
        WHEN status = 'SOLD' THEN status
        ELSE 'AVAILABLE'
      END
    WHERE id IN (${placeholders})
  `;
  
  const result = await db.run(sql, ticketIds);
  return result.changes || ticketIds.length;
}

/**
 * Count how many tickets would be updated (for dry-run)
 */
async function countTicketsToUpdate(ticketIds) {
  if (ticketIds.length === 0) return 0;
  
  const placeholders = ticketIds.map(() => '?').join(',');
  
  const result = await db.get(`
    SELECT COUNT(*) as count
    FROM tickets
    WHERE id IN (${placeholders})
      AND (available_online = ${db.USE_POSTGRES ? 'FALSE' : '0'} 
           OR status != 'AVAILABLE')
  `, ticketIds);
  
  return result.count || 0;
}

/**
 * Reset all tickets to not available online
 */
async function resetAllTickets() {
  const result = await db.run(`
    UPDATE tickets 
    SET available_online = ${db.USE_POSTGRES ? 'FALSE' : '0'}
    WHERE available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'}
  `);
  
  return result.changes || 0;
}

/**
 * Get count of tickets that would be reset
 */
async function countResetTickets() {
  const result = await db.get(`
    SELECT COUNT(*) as count 
    FROM tickets 
    WHERE available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'}
  `);
  
  return result.count || 0;
}

/**
 * Display summary statistics
 */
async function displaySummary() {
  const summary = await db.all(`
    SELECT 
      category,
      COUNT(*) as total,
      SUM(CASE WHEN available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'} THEN 1 ELSE 0 END) as online_available,
      SUM(CASE WHEN status = 'AVAILABLE' AND available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'} THEN 1 ELSE 0 END) as available_for_purchase,
      SUM(CASE WHEN status = 'SOLD' THEN 1 ELSE 0 END) as sold
    FROM tickets
    WHERE category IS NOT NULL AND category != ''
    GROUP BY category
    ORDER BY category
  `);
  
  console.log('\n📊 Summary by Category:');
  console.log('━'.repeat(85));
  console.log('Category | Total Tickets | Online Available | Available to Buy | Sold');
  console.log('━'.repeat(85));
  
  summary.forEach(row => {
    console.log(
      `${row.category.padEnd(8)} | ` +
      `${row.total.toLocaleString().padStart(13)} | ` +
      `${row.online_available.toLocaleString().padStart(16)} | ` +
      `${row.available_for_purchase.toLocaleString().padStart(16)} | ` +
      `${row.sold.toLocaleString().padStart(4)}`
    );
  });
  
  console.log('━'.repeat(85));
}

/**
 * Main execution function
 */
async function main() {
  console.log('🎫 Mark Tickets Available Online');
  console.log('═'.repeat(60));
  console.log('');
  
  // Display mode
  if (DRY_RUN) {
    console.log('⚠️  DRY RUN MODE - No changes will be made');
    console.log('');
  }
  
  if (RESET) {
    console.log('🔄 RESET MODE - Marking all tickets as NOT available online');
    console.log('');
  }
  
  // Display database type
  console.log(`📊 Database: ${db.USE_POSTGRES ? 'PostgreSQL' : 'SQLite'}`);
  
  if (!RESET) {
    console.log(`📦 Tickets per category: ${TICKETS_PER_CATEGORY.toLocaleString()}`);
  }
  
  console.log('');
  
  try {
    if (RESET) {
      // RESET mode: Mark all tickets as not available online
      if (DRY_RUN) {
        const count = await countResetTickets();
        console.log(`Would reset ${count.toLocaleString()} tickets to NOT available online`);
      } else {
        const count = await resetAllTickets();
        console.log(`✅ Reset complete: ${count.toLocaleString()} tickets marked as NOT available online`);
      }
    } else {
      // NORMAL mode: Mark last N tickets per category as available online
      const categories = await getCategories();
      
      if (categories.length === 0) {
        console.log('⚠️  No tickets found in database');
        console.log('   Create tickets first before running this script');
        return;
      }
      
      console.log(`Found ${categories.length} categories:`);
      categories.forEach(cat => {
        console.log(`  - ${cat.category}: ${cat.total_tickets.toLocaleString()} tickets`);
      });
      console.log('');
      
      // Process each category
      let totalMarked = 0;
      
      for (const cat of categories) {
        const category = cat.category;
        const totalTickets = cat.total_tickets;
        
        console.log(`Processing category: ${category}`);
        console.log(`  Total tickets in category: ${totalTickets.toLocaleString()}`);
        
        // Calculate how many tickets to mark (limit to available count)
        const ticketsToMark = Math.min(TICKETS_PER_CATEGORY, totalTickets);
        console.log(`  Tickets to mark: ${ticketsToMark.toLocaleString()}`);
        
        // Get the latest ticket IDs
        const ticketIds = await getLatestTicketIds(category, ticketsToMark);
        const actualTicketIds = ticketIds.map(row => row.id);
        
        console.log(`  Latest tickets retrieved: ${actualTicketIds.length.toLocaleString()}`);
        
        if (DRY_RUN) {
          // Count how many would be updated
          const count = await countTicketsToUpdate(actualTicketIds);
          console.log(`  Would update: ${count.toLocaleString()} tickets`);
          totalMarked += count;
        } else {
          // Actually update the tickets
          const updated = await markTicketsAvailable(actualTicketIds);
          console.log(`  ✅ Updated: ${updated.toLocaleString()} tickets`);
          totalMarked += updated;
        }
        
        console.log('');
      }
      
      console.log('═'.repeat(60));
      if (DRY_RUN) {
        console.log(`✅ Dry run complete: Would mark ${totalMarked.toLocaleString()} tickets`);
        console.log('');
        console.log('Run without --dry-run to apply changes:');
        console.log('  node scripts/markTicketsAvailable.js');
      } else {
        console.log(`✅ Update complete: ${totalMarked.toLocaleString()} tickets marked as available online`);
      }
    }
    
    // Display summary
    await displaySummary();
    
    console.log('');
    console.log('✨ Done!');
    
  } catch (error) {
    console.error('');
    console.error('❌ Script failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    db.close();
  }
}

// Run the script
main();
