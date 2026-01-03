/**
 * Bulk Ticket Service - Mass operations for ticket regeneration and export
 * Handles bulk export, barcode validation, and legacy ticket management
 */

const db = require('../db');
const barcodeService = require('./barcodeService');
const barcodeGenerator = require('./barcodeGenerator');
const ticketService = require('./ticketService');
const importExportService = require('./importExportService');
const printService = require('./printService');

/**
 * Validate if a barcode follows the new 8-digit format
 * 
 * @param {string} barcode - Barcode to validate
 * @returns {boolean} - True if valid 8-digit format
 */
function isValid8DigitBarcode(barcode) {
  return barcodeService.validateBarcodeNumber(barcode);
}

/**
 * Detect legacy/invalid barcodes in the system
 * 
 * @returns {Promise<Array>} - Array of tickets with invalid barcodes
 */
async function detectLegacyBarcodes() {
  try {
    const allTickets = await db.all(
      'SELECT id, ticket_number, barcode, category FROM tickets ORDER BY ticket_number ASC'
    );
    
    const legacyTickets = [];
    
    for (const ticket of allTickets) {
      if (!ticket.barcode) {
        legacyTickets.push({
          ...ticket,
          issue: 'MISSING_BARCODE'
        });
      } else if (!isValid8DigitBarcode(ticket.barcode)) {
        legacyTickets.push({
          ...ticket,
          issue: 'INVALID_FORMAT'
        });
      }
    }
    
    return legacyTickets;
  } catch (error) {
    console.error('Error detecting legacy barcodes:', error);
    throw error;
  }
}

/**
 * Regenerate barcodes for all tickets or by filter
 * 
 * @param {Object} options - Regeneration options
 * @param {string} options.category - Filter by category (optional)
 * @param {boolean} options.legacyOnly - Only regenerate legacy/invalid barcodes
 * @returns {Promise<Object>} - Regeneration results
 */
async function regenerateAllBarcodes(options = {}) {
  const { category, legacyOnly = false } = options;
  
  try {
    console.log('🔄 Starting barcode regeneration...');
    console.log('   Options:', options);
    
    let query = 'SELECT id, ticket_number, barcode, category FROM tickets';
    const params = [];
    const conditions = [];
    
    if (category) {
      conditions.push('category = ?');
      params.push(category);
    }
    
    if (legacyOnly) {
      // Only tickets with missing or invalid barcodes
      conditions.push('(barcode IS NULL OR LENGTH(barcode) != 8 OR barcode NOT GLOB "[1-4][0-9][0-9][0-9][0-9][0-9][0-9][0-9]")');
    }
    
    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY ticket_number ASC';
    
    const tickets = await db.all(query, params);
    
    console.log(`📊 Found ${tickets.length} tickets to process`);
    
    const results = {
      total: tickets.length,
      regenerated: 0,
      skipped: 0,
      errors: []
    };
    
    for (const ticket of tickets) {
      try {
        // Generate new 8-digit barcode
        const newBarcode = barcodeService.generateBarcodeNumber(ticket.ticket_number);
        
        // Validate the generated barcode
        if (!isValid8DigitBarcode(newBarcode)) {
          results.errors.push(`Ticket ${ticket.ticket_number}: Generated invalid barcode ${newBarcode}`);
          results.skipped++;
          continue;
        }
        
        // Update in database
        await db.run(
          'UPDATE tickets SET barcode = ? WHERE id = ?',
          [newBarcode, ticket.id]
        );
        
        results.regenerated++;
        
        if (results.regenerated % 1000 === 0) {
          console.log(`   Progress: ${results.regenerated} / ${results.total} tickets`);
        }
      } catch (error) {
        console.error(`Error regenerating barcode for ticket ${ticket.ticket_number}:`, error);
        results.errors.push(`Ticket ${ticket.ticket_number}: ${error.message}`);
        results.skipped++;
      }
    }
    
    console.log('✅ Barcode regeneration complete');
    console.log(`   Regenerated: ${results.regenerated}`);
    console.log(`   Skipped: ${results.skipped}`);
    console.log(`   Errors: ${results.errors.length}`);
    
    return results;
  } catch (error) {
    console.error('Error in regenerateAllBarcodes:', error);
    throw error;
  }
}

/**
 * Flag legacy tickets as invalid/replaced in database
 * 
 * @param {Array<number>} ticketIds - Array of ticket IDs to flag
 * @returns {Promise<number>} - Number of tickets flagged
 */
async function flagLegacyTickets(ticketIds) {
  try {
    if (!ticketIds || ticketIds.length === 0) {
      return 0;
    }
    
    const placeholders = ticketIds.map(() => '?').join(',');
    
    await db.run(
      `UPDATE tickets 
       SET status = 'INVALID',
           notes = 'Legacy barcode - replaced with new 8-digit format'
       WHERE id IN (${placeholders})`,
      ticketIds
    );
    
    return ticketIds.length;
  } catch (error) {
    console.error('Error flagging legacy tickets:', error);
    throw error;
  }
}

/**
 * Export all tickets with new 8-digit barcodes (PDF format)
 * 
 * @param {Object} options - Export options
 * @param {string} options.category - Filter by category (optional)
 * @param {string} options.startTicket - Start ticket number (optional)
 * @param {string} options.endTicket - End ticket number (optional)
 * @param {string} options.paperType - Paper type for PDF (default: AVERY_16145)
 * @returns {Promise<PDFDocument>} - PDF document stream
 */
async function exportAllTicketsPDF(options = {}) {
  const { category, startTicket, endTicket, paperType = 'AVERY_16145' } = options;
  
  try {
    console.log('📄 Generating PDF export...');
    console.log('   Options:', options);
    
    let query = 'SELECT * FROM tickets WHERE barcode IS NOT NULL';
    const params = [];
    
    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }
    
    if (startTicket && endTicket) {
      query += ' AND ticket_number >= ? AND ticket_number <= ?';
      params.push(startTicket, endTicket);
    }
    
    query += ' ORDER BY ticket_number ASC';
    
    const tickets = await db.all(query, params);
    
    console.log(`📊 Found ${tickets.length} tickets for PDF export`);
    
    if (tickets.length === 0) {
      throw new Error('No tickets found matching the criteria');
    }
    
    // Create a print job for tracking
    const printJob = await printService.createPrintJob({
      admin_id: 1, // System admin
      raffle_id: 1,
      category: category || 'ALL',
      ticket_range_start: tickets[0].ticket_number,
      ticket_range_end: tickets[tickets.length - 1].ticket_number,
      total_tickets: tickets.length,
      paper_type: paperType
    });
    
    // Generate PDF
    const pdfDoc = await printService.generatePrintPDF(
      tickets,
      paperType,
      printJob
    );
    
    console.log('✅ PDF export complete');
    
    return pdfDoc;
  } catch (error) {
    console.error('Error exporting tickets to PDF:', error);
    throw error;
  }
}

/**
 * Get statistics about barcode status in the system
 * 
 * @returns {Promise<Object>} - Statistics object
 */
async function getBarcodeStatistics() {
  try {
    const stats = await db.get(`
      SELECT 
        COUNT(*) as total_tickets,
        COUNT(CASE WHEN barcode IS NULL THEN 1 END) as missing_barcode,
        COUNT(CASE WHEN barcode IS NOT NULL AND LENGTH(barcode) = 8 THEN 1 END) as valid_8digit,
        COUNT(CASE WHEN barcode IS NOT NULL AND LENGTH(barcode) != 8 THEN 1 END) as invalid_format,
        COUNT(CASE WHEN status = 'INVALID' THEN 1 END) as flagged_invalid
      FROM tickets
    `);
    
    // Get category breakdown
    const categoryStats = await db.all(`
      SELECT 
        category,
        COUNT(*) as total,
        COUNT(CASE WHEN barcode IS NULL THEN 1 END) as missing,
        COUNT(CASE WHEN barcode IS NOT NULL AND LENGTH(barcode) = 8 THEN 1 END) as valid
      FROM tickets
      GROUP BY category
      ORDER BY category
    `);
    
    return {
      ...stats,
      by_category: categoryStats
    };
  } catch (error) {
    console.error('Error getting barcode statistics:', error);
    throw error;
  }
}

/**
 * Validate ticket barcode during scan/sale
 * Rejects legacy barcodes and only accepts new 8-digit format
 * 
 * @param {string} barcode - Barcode to validate
 * @returns {Promise<Object>} - Validation result
 */
async function validateTicketForSale(barcode) {
  try {
    // Step 1: Validate format
    if (!isValid8DigitBarcode(barcode)) {
      return {
        valid: false,
        error: 'INVALID_FORMAT',
        message: 'This barcode format is not valid. Please use a ticket with the new 8-digit barcode format.'
      };
    }
    
    // Step 2: Find ticket in database
    const ticket = await ticketService.getTicketByBarcode(barcode);
    
    if (!ticket) {
      return {
        valid: false,
        error: 'NOT_FOUND',
        message: 'Ticket not found. Please verify the barcode is correct.'
      };
    }
    
    // Step 3: Check if ticket is flagged as invalid
    if (ticket.status === 'INVALID') {
      return {
        valid: false,
        error: 'LEGACY_TICKET',
        message: 'This ticket has been replaced with a new barcode. Please obtain the updated ticket.',
        ticket: ticket
      };
    }
    
    // Step 4: Check if already sold
    if (ticket.status === 'SOLD') {
      return {
        valid: false,
        error: 'ALREADY_SOLD',
        message: 'This ticket has already been sold.',
        ticket: ticket
      };
    }
    
    // Step 5: Valid ticket
    return {
      valid: true,
      ticket: ticket
    };
  } catch (error) {
    console.error('Error validating ticket:', error);
    return {
      valid: false,
      error: 'SYSTEM_ERROR',
      message: 'System error during validation. Please try again.'
    };
  }
}

module.exports = {
  isValid8DigitBarcode,
  detectLegacyBarcodes,
  regenerateAllBarcodes,
  flagLegacyTickets,
  exportAllTicketsPDF,
  getBarcodeStatistics,
  validateTicketForSale
};
