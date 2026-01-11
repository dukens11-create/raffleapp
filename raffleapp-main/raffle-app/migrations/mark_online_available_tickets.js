/**
 * Migration Script: Mark Last 100,000 Tickets Per Category as Available Online
 * 
 * This script identifies and marks the last 100,000 tickets from each category
 * (ABC, EFG, JKL, XYZ) as available for online purchase.
 * 
 * For categories with 375,000 tickets:
 * - ABC: tickets 275,001 to 375,000
 * - EFG: tickets 275,001 to 375,000
 * - JKL: tickets 275,001 to 375,000
 * - XYZ: tickets 275,001 to 375,000
 * 
 * Usage:
 *   node migrations/mark_online_available_tickets.js
 * 
 * Options:
 *   --dry-run    Show what would be updated without making changes
 *   --reset      Mark all tickets as NOT available online (reverses the migration)
 */

const db = require('../db');

const DRY_RUN = process.argv.includes('--dry-run');
const RESET = process.argv.includes('--reset');

// Configuration: Number of tickets to make available online per category
const ONLINE_TICKETS_PER_CATEGORY = 100000;

async function markOnlineAvailableTickets() {
  console.log('🎫 Migration: Mark Tickets Available Online');
  console.log('================================================');
  console.log('');
  
  if (DRY_RUN) {
    console.log('⚠️  DRY RUN MODE - No changes will be made');
    console.log('');
  }
  
  if (RESET) {
    console.log('🔄 RESET MODE - Marking all tickets as NOT available online');
    console.log('');
  }
  
  try {
    // Get all ticket categories
    const categories = await db.all(`
      SELECT DISTINCT category, COUNT(*) as total_tickets
      FROM tickets
      WHERE category IS NOT NULL
      GROUP BY category
      ORDER BY category
    `);
    
    if (categories.length === 0) {
      console.log('⚠️  No tickets found in database');
      console.log('   Run the ticket generation first');
      return;
    }
    
    console.log(`Found ${categories.length} categories:`);
    categories.forEach(cat => {
      console.log(`  - ${cat.category}: ${cat.total_tickets.toLocaleString()} tickets`);
    });
    console.log('');
    
    if (RESET) {
      // Reset all tickets to not available online
      if (!DRY_RUN) {
        const result = await db.run(`
          UPDATE tickets 
          SET available_online = ${db.USE_POSTGRES ? 'FALSE' : '0'}
          WHERE available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'}
        `);
        console.log(`✅ Reset complete: All tickets marked as NOT available online`);
      } else {
        const count = await db.get(`
          SELECT COUNT(*) as count 
          FROM tickets 
          WHERE available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'}
        `);
        console.log(`Would reset ${count.count} tickets to NOT available online`);
      }
      return;
    }
    
    // Process each category
    let totalMarked = 0;
    
    for (const cat of categories) {
      const category = cat.category;
      const totalTickets = cat.total_tickets;
      
      console.log(`\nProcessing category: ${category}`);
      console.log(`  Total tickets: ${totalTickets.toLocaleString()}`);
      
      // Calculate the starting ticket number for online availability
      // For example, if total is 375,000 and we want last 100,000:
      // Start at 275,001 (375,000 - 100,000 + 1)
      const startTicketNum = Math.max(1, totalTickets - ONLINE_TICKETS_PER_CATEGORY + 1);
      const ticketsToMark = Math.min(ONLINE_TICKETS_PER_CATEGORY, totalTickets);
      
      console.log(`  Online available: Last ${ticketsToMark.toLocaleString()} tickets`);
      console.log(`  Range: ${category}-${startTicketNum.toString().padStart(6, '0')} to ${category}-${totalTickets.toString().padStart(6, '0')}`);
      
      if (DRY_RUN) {
        // Just count how many would be updated
        const count = await db.get(`
          SELECT COUNT(*) as count
          FROM tickets
          WHERE category = ? 
            AND CAST(SUBSTR(ticket_number, LENGTH(?) + 2) AS INTEGER) >= ?
            AND available_online = ${db.USE_POSTGRES ? 'FALSE' : '0'}
        `, [category, category, startTicketNum]);
        
        console.log(`  Would mark: ${count.count} tickets as available online`);
        totalMarked += count.count;
      } else {
        // Actually update the tickets
        // Extract the numeric part of ticket_number and compare
        const result = await db.run(`
          UPDATE tickets
          SET available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'}
          WHERE category = ? 
            AND CAST(SUBSTR(ticket_number, LENGTH(?) + 2) AS INTEGER) >= ?
            AND available_online = ${db.USE_POSTGRES ? 'FALSE' : '0'}
        `, [category, category, startTicketNum]);
        
        const updated = result.changes || 0;
        console.log(`  ✅ Marked ${updated} tickets as available online`);
        totalMarked += updated;
      }
    }
    
    console.log('');
    console.log('================================================');
    if (DRY_RUN) {
      console.log(`✅ Dry run complete: Would mark ${totalMarked.toLocaleString()} tickets`);
      console.log('');
      console.log('Run without --dry-run to apply changes:');
      console.log('  node migrations/mark_online_available_tickets.js');
    } else {
      console.log(`✅ Migration complete: ${totalMarked.toLocaleString()} tickets marked as available online`);
      console.log('');
      
      // Show summary
      const summary = await db.all(`
        SELECT 
          category,
          COUNT(*) as total,
          SUM(CASE WHEN available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'} THEN 1 ELSE 0 END) as online_available,
          SUM(CASE WHEN status = 'AVAILABLE' AND available_online = ${db.USE_POSTGRES ? 'TRUE' : '1'} THEN 1 ELSE 0 END) as online_and_available
        FROM tickets
        WHERE category IS NOT NULL
        GROUP BY category
        ORDER BY category
      `);
      
      console.log('Summary by Category:');
      console.log('Category | Total Tickets | Online Available | Available for Purchase');
      console.log('---------|---------------|------------------|----------------------');
      summary.forEach(row => {
        console.log(
          `${row.category.padEnd(8)} | ` +
          `${row.total.toLocaleString().padStart(13)} | ` +
          `${row.online_available.toLocaleString().padStart(16)} | ` +
          `${row.online_and_available.toLocaleString().padStart(22)}`
        );
      });
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    db.close();
  }
}

// Run the migration
markOnlineAvailableTickets();
