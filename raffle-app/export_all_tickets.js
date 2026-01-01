/**
 * Export All Tickets Script
 * 
 * This script exports all ticket data from the database to a tab-separated values (TSV) file
 * that can be easily opened in Excel or other spreadsheet applications.
 * 
 * HOW TO RUN:
 *   node export_all_tickets.js
 * 
 * OUTPUT:
 *   Creates a file at: ticket_exports/all_tickets.tsv
 *   Format: category<TAB>ticket_number<TAB>barcode
 * 
 * The script queries all tickets from the database, ordered by category and ticket_number,
 * and exports them to a TSV file for easy viewing in spreadsheet applications.
 */

const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

// ============================================================================
// DATABASE CONFIGURATION
// ============================================================================
// Change this path if your database is located elsewhere
const DB_PATH = './raffle.db';

// Output directory and file configuration
const OUTPUT_DIR = 'ticket_exports';
const OUTPUT_FILE = 'all_tickets.tsv';

// ============================================================================
// MAIN EXPORT FUNCTION
// ============================================================================

async function exportAllTickets() {
  console.log('🎟️  Starting ticket export...');
  console.log(`📂 Database: ${DB_PATH}`);
  
  // Check if database file exists
  if (!fs.existsSync(DB_PATH)) {
    console.error(`❌ Error: Database file not found at ${DB_PATH}`);
    console.error('   Please ensure the database file exists or update DB_PATH in this script.');
    process.exit(1);
  }
  
  // Open database connection
  const db = new sqlite3.Database(DB_PATH, sqlite3.OPEN_READONLY, (err) => {
    if (err) {
      console.error('❌ Error opening database:', err.message);
      process.exit(1);
    }
  });
  
  try {
    // Create output directory if it doesn't exist
    if (!fs.existsSync(OUTPUT_DIR)) {
      fs.mkdirSync(OUTPUT_DIR, { recursive: true });
      console.log(`✅ Created directory: ${OUTPUT_DIR}`);
    }
    
    // Query all tickets ordered by category and ticket_number
    const query = `
      SELECT category, ticket_number, barcode
      FROM tickets
      ORDER BY category ASC, ticket_number ASC
    `;
    
    console.log('🔍 Querying database...');
    
    const tickets = await new Promise((resolve, reject) => {
      db.all(query, [], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
    
    console.log(`📊 Found ${tickets.length} tickets`);
    
    if (tickets.length === 0) {
      console.log('⚠️  No tickets found in database. Export file will be created with headers only.');
    }
    
    // Create TSV content
    const outputPath = path.join(OUTPUT_DIR, OUTPUT_FILE);
    const header = 'category\tticket_number\tbarcode\n';
    
    // Build TSV content
    let tsvContent = header;
    for (const ticket of tickets) {
      const category = ticket.category || '';
      const ticketNumber = ticket.ticket_number || '';
      const barcode = ticket.barcode || '';
      tsvContent += `${category}\t${ticketNumber}\t${barcode}\n`;
    }
    
    // Write to file
    fs.writeFileSync(outputPath, tsvContent, 'utf8');
    
    console.log('✅ Export completed successfully!');
    console.log(`📄 Output file: ${outputPath}`);
    console.log(`📈 Total tickets exported: ${tickets.length}`);
    
    // Show category breakdown
    if (tickets.length > 0) {
      const categoryBreakdown = {};
      tickets.forEach(ticket => {
        const cat = ticket.category || 'NULL';
        categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + 1;
      });
      
      console.log('\n📊 Category Breakdown:');
      Object.entries(categoryBreakdown).sort().forEach(([category, count]) => {
        console.log(`   ${category}: ${count} tickets`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error during export:', error.message);
    process.exit(1);
  } finally {
    // Close database connection
    db.close((err) => {
      if (err) {
        console.error('Error closing database:', err.message);
      }
    });
  }
}

// ============================================================================
// RUN THE EXPORT
// ============================================================================

exportAllTickets().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
