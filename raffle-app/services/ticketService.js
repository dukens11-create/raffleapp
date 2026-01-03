/**
 * Ticket Service - Manage raffle tickets
 * Handles ticket creation, retrieval, barcode/QR generation, and printing
 */

const db = require('../db');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');
const barcodeGenerator = require('./barcodeGenerator');

/**
 * Create a single ticket with auto-generated barcode (QR codes disabled)
 * 
 * @param {Object} ticketData - Ticket information
 * @param {number} ticketData.raffle_id - Raffle ID
 * @param {number} ticketData.category_id - Category ID
 * @param {string} ticketData.category - Category code (ABC, EFG, JKL, XYZ)
 * @param {string} ticketData.ticket_number - Ticket number (e.g., "ABC-000001")
 * @param {number} ticketData.price - Ticket price
 * @returns {Promise<Object>} - Created ticket
 */
async function createTicket(ticketData) {
  const {
    raffle_id,
    category_id,
    category,
    ticket_number,
    price
  } = ticketData;

  try {
    // Extract sequence number from ticket_number (e.g., "ABC-000001" -> 1)
    const parts = ticket_number.split('-');
    const sequenceNum = parseInt(parts[1], 10);
    
    // Generate 8-digit barcode
    const barcode = barcodeGenerator.generateBarcode(category, sequenceNum);

    const result = await db.run(
      `INSERT INTO tickets (raffle_id, category_id, category, ticket_number, barcode, qr_code_data, price, status, created_at)
       VALUES (?, ?, ?, ?, ?, NULL, ?, 'AVAILABLE', ${db.getCurrentTimestamp()})`,
      [raffle_id, category_id, category, ticket_number, barcode, price]
    );

    return {
      id: result.lastID,
      ...ticketData,
      barcode,
      qr_code_data: null,
      status: 'AVAILABLE',
      printed: false
    };
  } catch (error) {
    console.error('Error creating ticket:', error);
    throw error;
  }
}

/**
 * Create tickets in bulk
 * 
 * @param {Array<Object>} tickets - Array of ticket data
 * @returns {Promise<number>} - Number of tickets created
 */
async function createTicketsBulk(tickets) {
  if (!tickets || tickets.length === 0) {
    return 0;
  }

  let created = 0;
  const batchSize = 1000;

  for (let i = 0; i < tickets.length; i += batchSize) {
    const batch = tickets.slice(i, i + batchSize);
    
    // Use transaction for better performance
    for (const ticket of batch) {
      try {
        await createTicket(ticket);
        created++;
      } catch (error) {
        if (db.isUniqueConstraintError(error)) {
          // Ticket already exists, skip
          continue;
        }
        throw error;
      }
    }
  }

  return created;
}

/**
 * Generate and save barcode for a ticket (QR codes disabled)
 * This is called during the print process
 * 
 * @param {string} ticketNumber - Ticket number
 * @returns {Promise<Object>} - { barcode, qrCodeData }
 */
async function generateAndSaveCodes(ticketNumber) {
  try {
    // Generate barcode number
    const barcodeNumber = barcodeService.generateBarcodeNumber(ticketNumber);

    // Save to database (qr_code_data is set to NULL)
    await db.run(
      `UPDATE tickets 
       SET barcode = ?, qr_code_data = NULL
       WHERE ticket_number = ?`,
      [barcodeNumber, ticketNumber]
    );

    return {
      barcode: barcodeNumber,
      qrCodeData: null
    };
  } catch (error) {
    console.error(`Error generating codes for ticket ${ticketNumber}:`, error);
    throw error;
  }
}

/**
 * Mark ticket as printed
 * 
 * @param {string} ticketNumber - Ticket number
 * @returns {Promise<void>}
 */
async function markAsPrinted(ticketNumber) {
  try {
    await db.run(
      `UPDATE tickets 
       SET printed = ${db.USE_POSTGRES ? 'TRUE' : '1'}, 
           printed_at = ${db.getCurrentTimestamp()},
           print_count = print_count + 1
       WHERE ticket_number = ?`,
      [ticketNumber]
    );
  } catch (error) {
    console.error(`Error marking ticket ${ticketNumber} as printed:`, error);
    throw error;
  }
}

/**
 * Get ticket by ticket number
 * 
 * @param {string} ticketNumber - Ticket number
 * @returns {Promise<Object|null>} - Ticket or null if not found
 */
async function getTicketByNumber(ticketNumber) {
  try {
    const ticket = await db.get(
      'SELECT * FROM tickets WHERE ticket_number = ?',
      [ticketNumber]
    );
    return ticket || null;
  } catch (error) {
    console.error('Error getting ticket by number:', error);
    throw error;
  }
}

/**
 * Get ticket by barcode
 * 
 * @param {string} barcode - Barcode number
 * @returns {Promise<Object|null>} - Ticket or null if not found
 */
async function getTicketByBarcode(barcode) {
  try {
    const ticket = await db.get(
      'SELECT * FROM tickets WHERE barcode = ?',
      [barcode]
    );
    return ticket || null;
  } catch (error) {
    console.error('Error getting ticket by barcode:', error);
    throw error;
  }
}

/**
 * Get tickets by range
 * 
 * @param {string} startTicket - Start ticket number (e.g., "ABC-000001")
 * @param {string} endTicket - End ticket number (e.g., "ABC-001000")
 * @returns {Promise<Array>} - Array of tickets
 */
async function getTicketsByRange(startTicket, endTicket) {
  try {
    const tickets = await db.all(
      `SELECT * FROM tickets 
       WHERE ticket_number >= ? AND ticket_number <= ?
       ORDER BY ticket_number ASC`,
      [startTicket, endTicket]
    );
    return tickets;
  } catch (error) {
    console.error('Error getting tickets by range:', error);
    throw error;
  }
}

/**
 * Generate ticket numbers for a range
 * 
 * @param {string} category - Category code (ABC, EFG, JKL, XYZ)
 * @param {number} startNum - Start sequence number
 * @param {number} endNum - End sequence number
 * @returns {Array<string>} - Array of ticket numbers
 */
function generateTicketNumbers(category, startNum, endNum) {
  const tickets = [];
  for (let i = startNum; i <= endNum; i++) {
    const paddedNum = String(i).padStart(6, '0');
    tickets.push(`${category}-${paddedNum}`);
  }
  return tickets;
}

/**
 * Create tickets for a range if they don't exist
 * 
 * @param {Object} params - Parameters
 * @param {number} params.raffle_id - Raffle ID
 * @param {number} params.category_id - Category ID
 * @param {string} params.category - Category code
 * @param {number} params.price - Ticket price
 * @param {number} params.startNum - Start sequence number
 * @param {number} params.endNum - End sequence number
 * @returns {Promise<Object>} - { created, existing, total }
 */
async function createTicketsForRange(params) {
  const { raffle_id, category_id, category, price, startNum, endNum } = params;
  
  const ticketNumbers = generateTicketNumbers(category, startNum, endNum);
  const tickets = ticketNumbers.map(ticket_number => ({
    raffle_id,
    category_id,
    category,
    ticket_number,
    price
  }));

  const created = await createTicketsBulk(tickets);
  const existing = tickets.length - created;

  return {
    created,
    existing,
    total: tickets.length
  };
}

/**
 * Generate tickets with barcodes in bulk (optimized for large-scale generation)
 * QR codes disabled - only barcodes are generated
 * 
 * @param {Object} params - Parameters
 * @param {number} params.raffle_id - Raffle ID
 * @param {number} params.category_id - Category ID
 * @param {string} params.category - Category code (ABC, EFG, JKL, XYZ)
 * @param {number} params.startNum - Start sequence number (e.g., 1)
 * @param {number} params.endNum - End sequence number (e.g., 375000)
 * @param {number} params.price - Ticket price
 * @param {Function} params.progressCallback - Optional callback for progress updates
 * @returns {Promise<Object>} - { created, total }
 */
async function generateTickets(params) {
  const { raffle_id, category_id, category, startNum, endNum, price, progressCallback } = params;
  
  console.log(`🎫 Generating tickets for ${category}: ${startNum} to ${endNum}`);
  
  const batchSize = 1000;
  const totalTickets = endNum - startNum + 1;
  let created = 0;
  
  for (let i = startNum; i <= endNum; i += batchSize) {
    const batchEnd = Math.min(i + batchSize - 1, endNum);
    const tickets = [];
    
    // Generate batch of tickets with barcodes (no QR codes)
    for (let ticketNum = i; ticketNum <= batchEnd; ticketNum++) {
      const paddedNum = String(ticketNum).padStart(6, '0');
      const ticket_number = `${category}-${paddedNum}`;
      
      // Generate 8-digit barcode
      const barcode = barcodeGenerator.generateBarcode(category, ticketNum);
      
      tickets.push({
        raffle_id,
        category_id,
        category,
        ticket_number,
        barcode,
        qr_code_data: null,
        price
      });
    }
    
    // Batch insert
    await batchInsertTickets(tickets);
    created += tickets.length;
    
    // Report progress
    if (progressCallback) {
      progressCallback({
        category,
        created,
        total: totalTickets,
        percent: ((created / totalTickets) * 100).toFixed(1)
      });
    }
    
    console.log(`✅ ${category}: ${created.toLocaleString()} / ${totalTickets.toLocaleString()} tickets`);
  }
  
  return {
    created,
    total: totalTickets
  };
}

/**
 * Batch insert tickets into database (optimized for performance)
 * 
 * @param {Array<Object>} tickets - Array of ticket objects
 * @returns {Promise<void>}
 */
async function batchInsertTickets(tickets) {
  if (!tickets || tickets.length === 0) {
    return;
  }
  
  const placeholders = tickets.map(() => '(?, ?, ?, ?, ?, ?, ?, ?, ${db.getCurrentTimestamp()})').join(',');
  const values = tickets.flatMap(t => [
    t.raffle_id,
    t.category_id,
    t.category,
    t.ticket_number,
    t.barcode,
    t.qr_code_data,
    t.price,
    'AVAILABLE'
  ]);
  
  const sql = `
    INSERT INTO tickets (
      raffle_id, category_id, category, ticket_number, 
      barcode, qr_code_data, price, status, created_at
    ) VALUES ${placeholders}
  `.replace(/\$\{db\.getCurrentTimestamp\(\)\}/g, db.getCurrentTimestamp());
  
  await db.run(sql, values);
}

/**
 * Sell a ticket (basic function)
 * 
 * @param {string} ticketNumber - Ticket number
 * @param {Object} buyerInfo - Buyer information
 * @returns {Promise<Object>} - Updated ticket
 */
async function sellTicket(ticketNumber, buyerInfo) {
  try {
    const ticket = await getTicketByNumber(ticketNumber);
    
    if (!ticket) {
      throw new Error('Ticket not found');
    }

    if (ticket.status !== 'AVAILABLE') {
      throw new Error('Ticket is not available for sale');
    }

    await db.run(
      `UPDATE tickets 
       SET status = 'SOLD',
           buyer_name = ?,
           buyer_phone = ?,
           seller_name = ?,
           seller_phone = ?
       WHERE ticket_number = ?`,
      [
        buyerInfo.buyer_name,
        buyerInfo.buyer_phone,
        buyerInfo.seller_name,
        buyerInfo.seller_phone,
        ticketNumber
      ]
    );

    return await getTicketByNumber(ticketNumber);
  } catch (error) {
    console.error('Error selling ticket:', error);
    throw error;
  }
}

/**
 * Get tickets by category and raffle
 * 
 * @param {number} raffle_id - Raffle ID
 * @param {string} category - Category code
 * @returns {Promise<Array>} - Array of tickets
 */
async function getTicketsByCategory(raffle_id, category) {
  try {
    const tickets = await db.all(
      `SELECT * FROM tickets 
       WHERE raffle_id = ? AND category = ?
       ORDER BY ticket_number ASC`,
      [raffle_id, category]
    );
    return tickets;
  } catch (error) {
    console.error('Error getting tickets by category:', error);
    throw error;
  }
}

/**
 * Get ticket statistics for a raffle
 * 
 * @param {number} raffle_id - Raffle ID
 * @returns {Promise<Object>} - Statistics
 */
async function getTicketStats(raffle_id) {
  try {
    const stats = await db.get(
      `SELECT 
         COUNT(*) as total,
         COUNT(CASE WHEN status = 'SOLD' THEN 1 END) as sold,
         COUNT(CASE WHEN status = 'AVAILABLE' THEN 1 END) as available,
         COUNT(CASE WHEN printed = TRUE THEN 1 END) as printed,
         SUM(CASE WHEN status = 'SOLD' THEN price ELSE 0 END) as revenue
       FROM tickets
       WHERE raffle_id = ?`,
      [raffle_id]
    );
    return stats;
  } catch (error) {
    console.error('Error getting ticket stats:', error);
    throw error;
  }
}

module.exports = {
  createTicket,
  createTicketsBulk,
  generateAndSaveCodes,
  markAsPrinted,
  getTicketByNumber,
  getTicketByBarcode,
  getTicketsByRange,
  generateTicketNumbers,
  createTicketsForRange,
  generateTickets,
  batchInsertTickets,
  sellTicket,
  getTicketsByCategory,
  getTicketStats
};
