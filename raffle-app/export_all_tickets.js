/**
 * Export All Tickets Script (STREAMING VERSION)
 * 
 * This script exports all ticket data from the database to a tab-separated values (TSV) file
 * that can be easily opened in Excel or other spreadsheet applications.
 * Uses streaming to handle large datasets (1M+ tickets) without OOM crashes.
 * 
 * HOW TO RUN:
 *   node export_all_tickets.js
 * 
 * OUTPUT:
 *   Creates a file at: ticket_exports/all_tickets.tsv
 *   Format: category<TAB>ticket_number<TAB>barcode
 * 
 * The script streams tickets from the database row-by-row, writing directly to the file,
 * without loading the entire dataset into memory.
 */

const db = require('./db');
const fs = require('fs');
const path = require('path');

// ============================================================================
// OUTPUT CONFIGURATION
// ============================================================================
const OUTPUT_DIR = 'ticket_exports';
const OUTPUT_FILE = 'all_tickets.tsv';

// ============================================================================
// MAIN EXPORT FUNCTION (STREAMING)
// ============================================================================

async function exportAllTickets() {
  console.log('🎟️  Starting ticket export (STREAMING)...');
  
  // Wait for database connection to be ready
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  try {
    // Create output directory if it doesn't exist
    if (!fs.existsSync(OUTPUT_DIR)) {
      fs.mkdirSync(OUTPUT_DIR, { recursive: true });
      console.log(`✅ Created directory: ${OUTPUT_DIR}`);
    }
    
    // Create write stream for output file
    const outputPath = path.join(OUTPUT_DIR, OUTPUT_FILE);
    const writeStream = fs.createWriteStream(outputPath, { encoding: 'utf8' });
    
    // Write TSV header
    writeStream.write('category\tticket_number\tbarcode\n');
    
    console.log('🔍 Streaming tickets from database...');
    
    let totalProcessed = 0;
    const categoryBreakdown = {};
    
    // Stream tickets row-by-row without loading all into memory
    await db.streamRows(
      'SELECT category, ticket_number, barcode FROM tickets ORDER BY category ASC, ticket_number ASC',
      [],
      (ticket) => {
        const category = ticket.category || '';
        const ticketNumber = ticket.ticket_number || '';
        const barcode = ticket.barcode || '';
        
        writeStream.write(`${category}\t${ticketNumber}\t${barcode}\n`);
        
        // Track category breakdown
        categoryBreakdown[category] = (categoryBreakdown[category] || 0) + 1;
        totalProcessed++;
        
        // Log progress every 10,000 tickets
        if (totalProcessed % 10000 === 0) {
          console.log(`📊 Streamed ${totalProcessed.toLocaleString()} tickets...`);
        }
      },
      { batchSize: 1000 }
    );
    
    // Close write stream
    writeStream.end();
    
    console.log('✅ Export completed successfully!');
    console.log(`📄 Output file: ${outputPath}`);
    console.log(`📈 Total tickets exported: ${totalProcessed.toLocaleString()}`);
    
    // Show category breakdown
    if (totalProcessed > 0) {
      console.log('\n📊 Category Breakdown:');
      Object.entries(categoryBreakdown).sort().forEach(([category, count]) => {
        console.log(`   ${category || 'NULL'}: ${count.toLocaleString()} tickets`);
      });
    } else {
      console.log('⚠️  No tickets found in database. Export file created with headers only.');
    }
    
  } catch (error) {
    console.error('❌ Error during export:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  } finally {
    // Close database connection
    db.close();
  }
}

// ============================================================================
// RUN THE EXPORT
// ============================================================================

exportAllTickets().catch(error => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
