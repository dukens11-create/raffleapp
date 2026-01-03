/**
 * Migration Script: Convert all barcodes to 8-digit format and nullify QR codes
 * 
 * This script:
 * 1. Converts all existing barcodes to 8-digit format (zero-padded)
 * 2. Nullifies all qr_code_data fields
 * 3. Ensures uniqueness of all barcodes
 * 
 * Run with: node migrations/migrate_to_8digit_barcodes.js
 */

const db = require('../db');

/**
 * Generate 8-digit barcode from ticket number
 * Format: Category prefix (1-4) + 7-digit sequential number
 * Examples:
 *   ABC-000001 -> 10000001 (ABC = 1)
 *   EFG-000001 -> 20000001 (EFG = 2)
 *   JKL-000001 -> 30000001 (JKL = 3)
 *   XYZ-000001 -> 40000001 (XYZ = 4)
 */
const CATEGORY_PREFIX_MAP = {
  'ABC': '1',
  'EFG': '2',
  'JKL': '3',
  'XYZ': '4'
};

function generate8DigitBarcode(ticketNumber) {
  if (!ticketNumber || typeof ticketNumber !== 'string') {
    throw new Error('Invalid ticket number');
  }

  const parts = ticketNumber.split('-');
  if (parts.length !== 2) {
    throw new Error(`Invalid ticket number format: ${ticketNumber}`);
  }

  const category = parts[0].toUpperCase();
  const sequence = parts[1];

  const prefix = CATEGORY_PREFIX_MAP[category];
  if (!prefix) {
    throw new Error(`Unknown category: ${category}`);
  }

  // Validate sequence length - should not exceed 7 digits
  const sequenceNum = parseInt(sequence, 10);
  if (isNaN(sequenceNum) || sequenceNum < 1 || sequenceNum > 9999999) {
    throw new Error(`Invalid sequence number: ${sequence}. Must be between 1 and 9999999`);
  }

  // Format: 1 digit prefix + 7 digit sequence = 8 digits total
  const barcode = prefix + sequence.padStart(7, '0');
  
  // Final validation - ensure result is exactly 8 digits
  if (barcode.length !== 8 || !/^\d{8}$/.test(barcode)) {
    throw new Error(`Generated barcode is invalid: ${barcode}`);
  }
  
  return barcode;
}

async function migrateDatabase() {
  console.log('🔄 Starting migration to 8-digit barcodes...');
  console.log('');

  try {
    // Step 1: Get all tickets
    console.log('📊 Step 1: Fetching all tickets...');
    const tickets = await db.all('SELECT id, ticket_number, barcode FROM tickets ORDER BY ticket_number');
    console.log(`   Found ${tickets.length} tickets to process`);
    console.log('');

    if (tickets.length === 0) {
      console.log('✅ No tickets to migrate. Database is empty.');
      return;
    }

    // Step 2: Convert barcodes and check for duplicates
    console.log('🔧 Step 2: Converting barcodes to 8-digit format...');
    const newBarcodes = new Map();
    const updates = [];
    let conversionErrors = 0;

    for (const ticket of tickets) {
      try {
        const newBarcode = generate8DigitBarcode(ticket.ticket_number);
        
        // Check for duplicates
        if (newBarcodes.has(newBarcode)) {
          console.error(`   ❌ ERROR: Duplicate barcode detected: ${newBarcode} for ticket ${ticket.ticket_number}`);
          conversionErrors++;
          continue;
        }
        
        newBarcodes.set(newBarcode, ticket.ticket_number);
        updates.push({
          id: ticket.id,
          ticket_number: ticket.ticket_number,
          old_barcode: ticket.barcode,
          new_barcode: newBarcode
        });
      } catch (error) {
        console.error(`   ❌ ERROR processing ticket ${ticket.ticket_number}: ${error.message}`);
        conversionErrors++;
      }
    }

    console.log(`   Converted ${updates.length} barcodes`);
    if (conversionErrors > 0) {
      console.log(`   ⚠️  ${conversionErrors} errors during conversion`);
    }
    console.log('');

    // Step 3: Show sample conversions
    console.log('📋 Sample barcode conversions:');
    updates.slice(0, 5).forEach(u => {
      console.log(`   ${u.ticket_number}: ${u.old_barcode || 'NULL'} -> ${u.new_barcode}`);
    });
    if (updates.length > 5) {
      console.log(`   ... and ${updates.length - 5} more`);
    }
    console.log('');

    // Step 4: Update database
    console.log('💾 Step 3: Updating database...');
    let updateCount = 0;
    const batchSize = 1000;

    for (let i = 0; i < updates.length; i += batchSize) {
      const batch = updates.slice(i, i + batchSize);
      
      for (const update of batch) {
        try {
          await db.run(
            'UPDATE tickets SET barcode = ?, qr_code_data = NULL WHERE id = ?',
            [update.new_barcode, update.id]
          );
          updateCount++;
        } catch (error) {
          console.error(`   ❌ ERROR updating ticket ${update.ticket_number}: ${error.message}`);
        }
      }
      
      console.log(`   Progress: ${updateCount} / ${updates.length} tickets updated`);
    }
    console.log('');

    // Step 5: Verify uniqueness
    console.log('🔍 Step 4: Verifying barcode uniqueness...');
    const duplicateCheck = await db.all(`
      SELECT barcode, COUNT(*) as count 
      FROM tickets 
      WHERE barcode IS NOT NULL
      GROUP BY barcode 
      HAVING COUNT(*) > 1
    `);

    if (duplicateCheck.length > 0) {
      console.log(`   ❌ ERROR: Found ${duplicateCheck.length} duplicate barcodes!`);
      duplicateCheck.forEach(dup => {
        console.log(`      Barcode ${dup.barcode}: ${dup.count} tickets`);
      });
    } else {
      console.log('   ✅ All barcodes are unique!');
    }
    console.log('');

    // Step 6: Summary
    console.log('📊 Migration Summary:');
    console.log(`   Total tickets: ${tickets.length}`);
    console.log(`   Successfully updated: ${updateCount}`);
    console.log(`   Errors: ${conversionErrors}`);
    console.log(`   All QR code data: NULLIFIED`);
    console.log('');

    console.log('✅ Migration completed successfully!');
    console.log('');
    console.log('Next steps:');
    console.log('  1. Test ticket creation with new 8-digit barcodes');
    console.log('  2. Test ticket printing to verify QR codes are removed');
    console.log('  3. Test export functionality (Excel/CSV)');
    console.log('');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration if executed directly
if (require.main === module) {
  migrateDatabase()
    .then(() => {
      console.log('Done!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Fatal error:', error);
      process.exit(1);
    });
}

module.exports = { migrateDatabase, generate8DigitBarcode };
