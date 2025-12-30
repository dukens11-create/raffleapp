/**
 * Ticket Management Service
 * Handles ticket generation, barcode/QR creation, and ticket operations
 */

const db = require('../db');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');

/**
 * Generate barcode and QR code for a ticket
 * Saves them to the database
 * 
 * @param {number} ticketId - Ticket ID
 * @param {string} ticketNumber - Ticket number (e.g., "ABC-000001")
 * @returns {Promise<object>} - Generated codes
 */
async function generateCodesForTicket(ticketId, ticketNumber) {
  try {
    // Generate barcode number
    const barcodeNumber = barcodeService.generateBarcodeNumber(ticketNumber);
    
    // Generate QR code data (verification URL)
    const qrCodeData = qrcodeService.generateVerificationURL(ticketNumber);
    
    // Update ticket in database
    await db.run(
      `UPDATE tickets SET barcode = ?, qr_code_data = ? WHERE id = ?`,
      [barcodeNumber, qrCodeData, ticketId]
    );
    
    console.log(`✅ Generated codes for ticket ${ticketNumber}: barcode=${barcodeNumber}`);
    
    return {
      barcodeNumber,
      qrCodeData,
      ticketNumber
    };
  } catch (error) {
    console.error(`Error generating codes for ticket ${ticketNumber}:`, error);
    throw error;
  }
}

/**
 * Generate codes for multiple tickets in batch
 * 
 * @param {Array} tickets - Array of ticket objects with id and ticket_number
 * @returns {Promise<Array>} - Array of generated codes
 */
async function generateCodesForTickets(tickets) {
  const results = [];
  
  for (const ticket of tickets) {
    try {
      const codes = await generateCodesForTicket(ticket.id, ticket.ticket_number);
      results.push({
        success: true,
        ticketId: ticket.id,
        ticketNumber: ticket.ticket_number,
        ...codes
      });
    } catch (error) {
      results.push({
        success: false,
        ticketId: ticket.id,
        ticketNumber: ticket.ticket_number,
        error: error.message
      });
    }
  }
  
  return results;
}

/**
 * Create tickets for a category
 * 
 * @param {number} raffleId - Raffle ID
 * @param {number} categoryId - Category ID
 * @param {string} categoryCode - Category code (ABC, EFG, JKL, XYZ)
 * @param {number} price - Ticket price
 * @param {number} startNum - Starting ticket number
 * @param {number} endNum - Ending ticket number
 * @returns {Promise<Array>} - Array of created ticket IDs
 */
async function createTicketsForCategory(raffleId, categoryId, categoryCode, price, startNum, endNum) {
  const ticketIds = [];
  
  console.log(`Creating tickets ${categoryCode}-${startNum} to ${categoryCode}-${endNum}...`);
  
  for (let num = startNum; num <= endNum; num++) {
    const ticketNumber = `${categoryCode}-${num.toString().padStart(6, '0')}`;
    
    try {
      const result = await db.run(
        `INSERT INTO tickets (raffle_id, category_id, category, ticket_number, price, status) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [raffleId, categoryId, categoryCode, ticketNumber, price, 'AVAILABLE']
      );
      
      ticketIds.push(result.lastID || num); // PostgreSQL won't have lastID directly
    } catch (error) {
      // Skip if ticket already exists (unique constraint)
      if (!db.isUniqueConstraintError(error)) {
        console.error(`Error creating ticket ${ticketNumber}:`, error);
      }
    }
  }
  
  console.log(`✅ Created ${ticketIds.length} tickets for ${categoryCode}`);
  return ticketIds;
}

/**
 * Mark ticket as printed
 * 
 * @param {number} ticketId - Ticket ID
 * @returns {Promise<void>}
 */
async function markTicketAsPrinted(ticketId) {
  const timestamp = db.USE_POSTGRES ? 'CURRENT_TIMESTAMP' : "datetime('now')";
  
  await db.run(
    `UPDATE tickets 
     SET printed = ${db.USE_POSTGRES ? 'TRUE' : '1'}, 
         printed_at = ${timestamp},
         print_count = print_count + 1
     WHERE id = ?`,
    [ticketId]
  );
}

/**
 * Mark multiple tickets as printed
 * 
 * @param {Array<number>} ticketIds - Array of ticket IDs
 * @returns {Promise<void>}
 */
async function markTicketsAsPrinted(ticketIds) {
  const timestamp = db.USE_POSTGRES ? 'CURRENT_TIMESTAMP' : "datetime('now')";
  
  for (const ticketId of ticketIds) {
    await markTicketAsPrinted(ticketId);
  }
  
  console.log(`✅ Marked ${ticketIds.length} tickets as printed`);
}

/**
 * Get ticket by barcode
 * 
 * @param {string} barcode - Barcode number
 * @returns {Promise<object|null>} - Ticket object or null
 */
async function getTicketByBarcode(barcode) {
  const ticket = await db.get(
    `SELECT t.*, c.category_name, c.color as category_color
     FROM tickets t
     LEFT JOIN ticket_categories c ON t.category_id = c.id
     WHERE t.barcode = ?`,
    [barcode]
  );
  
  return ticket;
}

/**
 * Get ticket by ticket number
 * 
 * @param {string} ticketNumber - Ticket number
 * @returns {Promise<object|null>} - Ticket object or null
 */
async function getTicketByNumber(ticketNumber) {
  const ticket = await db.get(
    `SELECT t.*, c.category_name, c.color as category_color
     FROM tickets t
     LEFT JOIN ticket_categories c ON t.category_id = c.id
     WHERE t.ticket_number = ?`,
    [ticketNumber]
  );
  
  return ticket;
}

/**
 * Get tickets by range
 * 
 * @param {string} startTicket - Start ticket number (e.g., "ABC-000001")
 * @param {string} endTicket - End ticket number (e.g., "ABC-001000")
 * @returns {Promise<Array>} - Array of tickets
 */
async function getTicketsByRange(startTicket, endTicket) {
  // Extract category from start ticket
  const category = startTicket.split('-')[0];
  
  // Parse numbers
  const startNum = parseInt(startTicket.split('-')[1], 10);
  const endNum = parseInt(endTicket.split('-')[1], 10);
  
  const tickets = await db.all(
    `SELECT t.*, c.category_name, c.color as category_color
     FROM tickets t
     LEFT JOIN ticket_categories c ON t.category_id = c.id
     WHERE t.category = ? 
       AND CAST(SUBSTR(t.ticket_number, INSTR(t.ticket_number, '-') + 1) AS INTEGER) >= ?
       AND CAST(SUBSTR(t.ticket_number, INSTR(t.ticket_number, '-') + 1) AS INTEGER) <= ?
     ORDER BY t.ticket_number`,
    [category, startNum, endNum]
  );
  
  return tickets;
}

/**
 * Sell a ticket
 * 
 * @param {number} ticketId - Ticket ID
 * @param {object} saleData - Sale information
 * @returns {Promise<object>} - Updated ticket
 */
async function sellTicket(ticketId, saleData) {
  const {
    sellerId,
    buyerName,
    buyerPhone,
    buyerEmail,
    paymentMethod,
    paymentVerified,
    actualPricePaid
  } = saleData;
  
  // Get ticket to calculate commission
  const ticket = await db.get('SELECT * FROM tickets WHERE id = ?', [ticketId]);
  if (!ticket) {
    throw new Error('Ticket not found');
  }
  
  if (ticket.status !== 'AVAILABLE') {
    throw new Error('Ticket is not available for sale');
  }
  
  const price = actualPricePaid || ticket.price;
  const commission = price * 0.10; // 10% commission
  
  const timestamp = db.USE_POSTGRES ? 'CURRENT_TIMESTAMP' : "datetime('now')";
  
  // Update ticket
  await db.run(
    `UPDATE tickets 
     SET status = 'SOLD',
         seller_id = ?,
         buyer_name = ?,
         buyer_phone = ?,
         buyer_email = ?,
         payment_method = ?,
         payment_verified = ?,
         sold_at = ${timestamp},
         actual_price_paid = ?,
         seller_commission = ?
     WHERE id = ?`,
    [
      sellerId,
      buyerName,
      buyerPhone,
      buyerEmail || null,
      paymentMethod,
      paymentVerified ? (db.USE_POSTGRES ? true : 1) : (db.USE_POSTGRES ? false : 0),
      price,
      commission,
      ticketId
    ]
  );
  
  // Update seller stats
  await db.run(
    `UPDATE users 
     SET total_sales = total_sales + 1,
         total_revenue = total_revenue + ?,
         total_commission = total_commission + ?
     WHERE id = ?`,
    [price, commission, sellerId]
  );
  
  // Update category stats
  if (ticket.category_id) {
    await db.run(
      `UPDATE ticket_categories 
       SET sold_tickets = sold_tickets + 1,
           total_revenue = total_revenue + ?
       WHERE id = ?`,
      [price, ticket.category_id]
    );
  }
  
  console.log(`✅ Ticket ${ticket.ticket_number} sold to ${buyerName} for $${price}`);
  
  return await db.get('SELECT * FROM tickets WHERE id = ?', [ticketId]);
}

/**
 * Log ticket scan
 * 
 * @param {number} ticketId - Ticket ID
 * @param {number} userId - User ID who scanned
 * @param {string} userRole - User role (admin/seller)
 * @param {string} scanType - Type of scan (verification, sale, audit, winner_draw, check)
 * @param {string} scanMethod - Method used (barcode, qr_code, manual)
 * @param {string} notes - Optional notes
 * @returns {Promise<void>}
 */
async function logTicketScan(ticketId, userId, userRole, scanType, scanMethod, notes = null) {
  await db.run(
    `INSERT INTO ticket_scans (ticket_id, user_id, user_role, scan_type, scan_method, notes)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [ticketId, userId, userRole, scanType, scanMethod, notes]
  );
}

module.exports = {
  generateCodesForTicket,
  generateCodesForTickets,
  createTicketsForCategory,
  markTicketAsPrinted,
  markTicketsAsPrinted,
  getTicketByBarcode,
  getTicketByNumber,
  getTicketsByRange,
  sellTicket,
  logTicketScan
};
