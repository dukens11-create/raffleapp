/**
 * Print Service - Generate PDF tickets for printing
 * Supports Avery 16145 and PrintWorks custom templates
 */

const PDFDocument = require('pdfkit');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');
const db = require('../db');

// Paper templates configuration
const TEMPLATES = {
  AVERY_16145: {
    name: 'Avery 16145',
    ticketWidth: 1.75 * 72,      // 1.75 inches in points (72 points = 1 inch)
    ticketHeight: 5.5 * 72,      // 5.5 inches in points
    mainHeight: 1.25 * 72,       // 1.25 inches
    stubHeight: 0.5 * 72,        // 0.5 inches
    perforationLine: true,
    ticketsPerPage: 10,
    topMargin: 0.5 * 72,
    leftMargin: 0.1875 * 72,
    rightMargin: 0.1875 * 72,
    spacing: 0,
    pageWidth: 8.5 * 72,
    pageHeight: 11 * 72
  },
  PRINTWORKS: {
    name: 'PrintWorks Custom',
    ticketWidth: 2.125 * 72,     // 2.125 inches in points
    ticketHeight: 5.5 * 72,      // 5.5 inches in points
    mainHeight: 1.675 * 72,      // 1.675 inches
    stubHeight: 0.45 * 72,       // 0.45 inches
    perforationLine: false,      // Manual cutting with guides
    ticketsPerPage: 8,
    topMargin: 0.5 * 72,
    leftMargin: 0.3125 * 72,
    rightMargin: 0.3125 * 72,
    spacing: 0.05 * 72,
    pageWidth: 8.5 * 72,
    pageHeight: 11 * 72
  }
};

/**
 * Create a print job record
 * 
 * @param {Object} jobData - Print job information
 * @returns {Promise<number>} - Print job ID
 */
async function createPrintJob(jobData) {
  const {
    admin_id,
    raffle_id,
    category,
    ticket_range_start,
    ticket_range_end,
    total_tickets,
    paper_type
  } = jobData;

  try {
    const template = TEMPLATES[paper_type];
    const total_pages = Math.ceil(total_tickets / template.ticketsPerPage);

    const result = await db.run(
      `INSERT INTO print_jobs 
       (admin_id, raffle_id, category, ticket_range_start, ticket_range_end, 
        total_tickets, total_pages, paper_type, status, started_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'in_progress', ${db.getCurrentTimestamp()})`,
      [admin_id, raffle_id, category, ticket_range_start, ticket_range_end, 
       total_tickets, total_pages, paper_type]
    );

    return result.lastID;
  } catch (error) {
    console.error('Error creating print job:', error);
    throw error;
  }
}

/**
 * Update print job status
 * 
 * @param {number} jobId - Print job ID
 * @param {string} status - Status (in_progress, completed, failed)
 * @param {number} progress - Progress percentage (0-100)
 * @returns {Promise<void>}
 */
async function updatePrintJobStatus(jobId, status, progress = 0) {
  try {
    const updates = ['status = ?', 'progress_percent = ?'];
    const params = [status, progress];

    if (status === 'completed') {
      updates.push(`completed_at = ${db.getCurrentTimestamp()}`);
    }

    await db.run(
      `UPDATE print_jobs 
       SET ${updates.join(', ')}
       WHERE id = ?`,
      [...params, jobId]
    );
  } catch (error) {
    console.error('Error updating print job status:', error);
    throw error;
  }
}

/**
 * Draw a single ticket on the PDF
 * 
 * @param {PDFDocument} doc - PDF document
 * @param {Object} ticket - Ticket data
 * @param {Object} template - Template configuration
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {Buffer} barcodeImage - Barcode image buffer
 * @param {Buffer} qrMainImage - Main QR code image buffer
 * @param {Buffer} qrStubImage - Stub QR code image buffer
 */
function drawTicket(doc, ticket, template, x, y, barcodeImage, qrMainImage, qrStubImage) {
  const { ticketWidth, mainHeight, stubHeight, perforationLine } = template;

  // Main ticket section (top)
  const mainY = y;
  
  // Draw border for main ticket
  doc.rect(x, mainY, ticketWidth, mainHeight).stroke();

  // Ticket number (top)
  doc.fontSize(14)
     .font('Helvetica-Bold')
     .text(ticket.ticket_number, x + 10, mainY + 10, {
       width: ticketWidth - 20,
       align: 'center'
     });

  // Category and price
  doc.fontSize(10)
     .font('Helvetica')
     .text(`Category: ${ticket.category}`, x + 10, mainY + 30);
  
  doc.text(`Price: $${parseFloat(ticket.price).toFixed(2)}`, x + 10, mainY + 45);

  // Add barcode (centered)
  if (barcodeImage) {
    const barcodeWidth = 120;
    const barcodeHeight = 30;
    const barcodeX = x + (ticketWidth - barcodeWidth) / 2;
    const barcodeY = mainY + 60;
    doc.image(barcodeImage, barcodeX, barcodeY, {
      width: barcodeWidth,
      height: barcodeHeight
    });
  }

  // Add QR code (bottom right of main ticket)
  if (qrMainImage) {
    const qrSize = 50;
    const qrX = x + ticketWidth - qrSize - 10;
    const qrY = mainY + mainHeight - qrSize - 10;
    doc.image(qrMainImage, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // Perforation line or separator
  const separatorY = mainY + mainHeight;
  if (perforationLine) {
    // Draw dashed line for perforation
    doc.save();
    doc.dash(5, { space: 3 });
    doc.moveTo(x, separatorY)
       .lineTo(x + ticketWidth, separatorY)
       .stroke();
    doc.undash();
    doc.restore();
  } else {
    // Draw solid line with scissors icon
    doc.moveTo(x, separatorY)
       .lineTo(x + ticketWidth, separatorY)
       .stroke();
  }

  // Stub section (bottom)
  const stubY = separatorY;
  
  // Draw border for stub
  doc.rect(x, stubY, ticketWidth, stubHeight).stroke();

  // Ticket number on stub (smaller)
  doc.fontSize(8)
     .font('Helvetica-Bold')
     .text(ticket.ticket_number, x + 5, stubY + 5, {
       width: ticketWidth / 2 - 10,
       align: 'left'
     });

  // Add QR code on stub (smaller)
  if (qrStubImage) {
    const qrSize = 25;
    const qrX = x + ticketWidth - qrSize - 5;
    const qrY = stubY + 5;
    doc.image(qrStubImage, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }
}

/**
 * Generate PDF for ticket printing
 * 
 * @param {Array} tickets - Array of ticket objects
 * @param {string} paperType - Paper type (AVERY_16145 or PRINTWORKS)
 * @param {number} printJobId - Print job ID
 * @returns {Promise<PDFDocument>} - PDF document stream
 */
async function generatePrintPDF(tickets, paperType, printJobId) {
  const template = TEMPLATES[paperType];
  if (!template) {
    throw new Error(`Unknown paper type: ${paperType}`);
  }

  // Create PDF document
  const doc = new PDFDocument({
    size: [template.pageWidth, template.pageHeight],
    margin: 0
  });

  let ticketCount = 0;
  let pageCount = 0;
  const totalTickets = tickets.length;

  // Process tickets
  for (let i = 0; i < tickets.length; i++) {
    const ticket = tickets[i];
    
    // Generate codes if not already generated
    const ticketService = require('./ticketService');
    let codes;
    if (!ticket.barcode || !ticket.qr_code_data) {
      codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
      ticket.barcode = codes.barcode;
      ticket.qr_code_data = codes.qrCodeData;
    }

    // Generate barcode image
    const barcodeImage = await barcodeService.generateBarcodeImage(ticket.barcode, {
      height: 30,
      width: 2,
      includetext: true
    });

    // Generate QR code images
    const qrCodes = await qrcodeService.generateTicketQRCode(ticket.ticket_number);

    // Calculate position on page
    const ticketIndex = ticketCount % template.ticketsPerPage;
    
    if (ticketIndex === 0 && ticketCount > 0) {
      doc.addPage();
      pageCount++;
    }

    const x = template.leftMargin;
    const y = template.topMargin + (ticketIndex * template.ticketHeight) + (ticketIndex * template.spacing);

    // Draw ticket
    drawTicket(doc, ticket, template, x, y, barcodeImage, qrCodes.mainQRCode, qrCodes.stubQRCode);

    // Mark ticket as printed
    await ticketService.markAsPrinted(ticket.ticket_number);

    ticketCount++;

    // Update progress
    const progress = Math.round((ticketCount / totalTickets) * 100);
    if (ticketCount % 10 === 0 || ticketCount === totalTickets) {
      await updatePrintJobStatus(printJobId, 'in_progress', progress);
    }
  }

  // Mark job as completed
  await updatePrintJobStatus(printJobId, 'completed', 100);

  return doc;
}

/**
 * Get print jobs
 * 
 * @param {Object} filters - Filter options
 * @returns {Promise<Array>} - Array of print jobs
 */
async function getPrintJobs(filters = {}) {
  try {
    let query = 'SELECT * FROM print_jobs WHERE 1=1';
    const params = [];

    if (filters.raffle_id) {
      query += ' AND raffle_id = ?';
      params.push(filters.raffle_id);
    }

    if (filters.status) {
      query += ' AND status = ?';
      params.push(filters.status);
    }

    query += ' ORDER BY started_at DESC';

    if (filters.limit) {
      query += ' LIMIT ?';
      params.push(filters.limit);
    }

    const jobs = await db.all(query, params);
    return jobs;
  } catch (error) {
    console.error('Error getting print jobs:', error);
    throw error;
  }
}

/**
 * Get print job by ID
 * 
 * @param {number} jobId - Print job ID
 * @returns {Promise<Object|null>} - Print job or null
 */
async function getPrintJob(jobId) {
  try {
    const job = await db.get('SELECT * FROM print_jobs WHERE id = ?', [jobId]);
    return job || null;
  } catch (error) {
    console.error('Error getting print job:', error);
    throw error;
  }
}

module.exports = {
  createPrintJob,
  updatePrintJobStatus,
  generatePrintPDF,
  getPrintJobs,
  getPrintJob,
  TEMPLATES
};
