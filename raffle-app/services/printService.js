/**
 * Print Service - Generate PDF tickets for printing
 * Supports Avery 16145 and PrintWorks custom templates
 */

const PDFDocument = require('pdfkit');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');
const db = require('../db');
const fs = require('fs');
const path = require('path');
const bwipjs = require('bwip-js');
const ticketService = require('./ticketService');

// Category display names mapping
const CATEGORY_NAMES = {
  'ABC': { full: 'ABC - Regular', short: 'ABC ($50)' },
  'EFG': { full: 'EFG - Silver', short: 'EFG ($100)' },
  'JKL': { full: 'JKL - Gold', short: 'JKL ($250)' },
  'XYZ': { full: 'XYZ - Platinum', short: 'XYZ ($500)' }
};

// Barcode generation constants for BWIP-JS
// EAN-13 barcode standard width is approximately 60 modules (bars)
// Scale factor is calculated relative to this baseline for proportional sizing
const BARCODE_BASE_WIDTH = 60;
// BWIP-JS uses millimeters for height while PDFKit uses points (1 point ≈ 0.35mm)
// Height ratio converts from points to approximate mm scale for consistent rendering
const BARCODE_HEIGHT_RATIO = 2;

// Paper templates configuration
const TEMPLATES = {
  AVERY_16145: {
    name: 'Avery 16145',
    ticketWidth: 5.5 * 72,       // 5.5 inches in points (72 points = 1 inch) - LANDSCAPE
    ticketHeight: 1.75 * 72,     // 1.75 inches in points - LANDSCAPE
    mainHeight: 1.25 * 72,       // Main ticket section height (front side)
    stubHeight: 0.5 * 72,        // Stub section height (back side for duplex)
    perforationLine: true,
    ticketsPerPage: 10,          // 2 columns x 5 rows
    columns: 2,
    rows: 5,
    topMargin: 0.5 * 72,
    leftMargin: 0.1875 * 72,
    rightMargin: 0.1875 * 72,
    bottomMargin: 0.5 * 72,
    spacing: 0,
    pageWidth: 8.5 * 72,
    pageHeight: 11 * 72
  },
  PRINTWORKS: {
    name: 'PrintWorks Custom',
    ticketWidth: 5.5 * 72,       // 5.5 inches in points - LANDSCAPE
    ticketHeight: 2.125 * 72,    // 2.125 inches in points - LANDSCAPE
    mainHeight: 1.675 * 72,      // Main ticket section
    stubHeight: 0.45 * 72,       // Stub section
    perforationLine: false,      // Manual cutting with guides
    ticketsPerPage: 8,           // 2 columns x 4 rows
    columns: 2,
    rows: 4,
    topMargin: 0.5 * 72,
    leftMargin: 0.3125 * 72,
    rightMargin: 0.3125 * 72,
    bottomMargin: 0.5 * 72,
    spacing: 0.05 * 72,
    pageWidth: 8.5 * 72,
    pageHeight: 11 * 72
  },
  LETTER_8_TICKETS: {
    name: 'Letter 8.5" x 11" - 8 Tickets',
    ticketWidth: 2.125 * 72,     // 2.125 inches in points - PORTRAIT
    ticketHeight: 5.5 * 72,      // 5.5 inches in points - PORTRAIT
    mainHeight: 5.5 * 72,        // Full height for ticket
    stubHeight: 0,               // No stub section (front/back design)
    perforationLine: true,       // Dashed borders for tear-off
    ticketsPerPage: 8,           // 4 columns x 2 rows
    columns: 4,
    rows: 2,
    topMargin: 0,
    leftMargin: 0,
    rightMargin: 0,
    bottomMargin: 0,
    spacing: 0,
    pageWidth: 8.5 * 72,
    pageHeight: 11 * 72
  },
  GRID_20_TICKETS: {
    name: 'Grid Layout - 20 Tickets (4×5)',
    ticketWidth: 2 * 72,         // 2 inches in points (144 points)
    ticketHeight: 2.1 * 72,      // 2.1 inches in points (151.2 points)
    mainHeight: 0,               // Not used in grid layout
    stubHeight: 0,               // Not used in grid layout
    perforationLine: true,       // Dashed perforation line
    ticketsPerPage: 20,          // 4 columns x 5 rows
    columns: 4,
    rows: 5,
    topMargin: 0.25 * 72,        // 0.25 inch margin (18 points)
    leftMargin: 0.25 * 72,       // 0.25 inch margin (18 points)
    rightMargin: 0.25 * 72,      // 0.25 inch margin (18 points)
    bottomMargin: 0.25 * 72,     // 0.25 inch margin (18 points)
    spacing: 0,                  // No gap between tickets
    pageWidth: 8.5 * 72,         // Letter width (612 points)
    pageHeight: 11 * 72          // Letter height (792 points)
  },
  DEFAULT_TEAROFF: {
    name: 'Default Tear-off Ticket',
    ticketWidth: 396,            // 5.5" × 72 DPI
    ticketHeight: 153,           // 2.125" × 72 DPI
    mainTicketHeight: 95,        // 62% for buyer (main ticket)
    tearOffHeight: 58,           // 38% for seller stub
    tearOffY: 95,                // Perforation line position
    margin: 10,
    padding: 8,
    perforationLine: true,       // Show perforation line
    ticketsPerPage: 8,           // 2 columns x 4 rows
    columns: 2,
    rows: 4,
    topMargin: 0.5 * 72,
    leftMargin: 0.3125 * 72,
    rightMargin: 0.3125 * 72,
    bottomMargin: 0.5 * 72,
    spacing: 0.05 * 72,
    pageWidth: 8.5 * 72,
    pageHeight: 11 * 72
  },
  PORTRAIT_8UP: {
    name: 'Portrait 8-up (2.1" × 5.5")',
    ticketWidth: 2.1 * 72,       // 2.1 inches in points - PORTRAIT WIDTH
    ticketHeight: 5.5 * 72,      // 5.5 inches in points - PORTRAIT HEIGHT
    mainHeight: 4.0 * 72,        // Main ticket section (bottom 4")
    stubHeight: 1.5 * 72,        // Stub section (top 1.5")
    perforationLine: true,       // Dashed perforation line
    ticketsPerPage: 8,           // 4 columns x 2 rows
    columns: 4,
    rows: 2,
    topMargin: 0.25 * 72,        // 0.25 inch margin
    leftMargin: 0.25 * 72,       // 0.25 inch margin
    rightMargin: 0.25 * 72,      // 0.25 inch margin
    bottomMargin: 0.25 * 72,     // 0.25 inch margin
    spacing: 0,                  // No gap between tickets
    pageWidth: 8.5 * 72,         // Letter width (612 points)
    pageHeight: 11 * 72          // Letter height (792 points)
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
 * Draw a single ticket FRONT side on the PDF (buyer keeps this)
 * 
 * @param {PDFDocument} doc - PDF document
 * @param {Object} ticket - Ticket data
 * @param {Object} template - Template configuration
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {Buffer} qrMainImage - Main QR code image buffer
 * @param {Buffer} barcodeImage - Barcode image buffer
 */
async function drawTicketFront(doc, ticket, template, x, y, qrMainImage, barcodeImage) {
  const { ticketWidth, ticketHeight, perforationLine } = template;
  
  // Detect if this is the smaller LETTER_8_TICKETS format
  const isSmallFormat = ticketWidth < 200; // 2.125" * 72 = 153 points
  
  // Scale down content for smaller tickets
  const padding = isSmallFormat ? 4 : 8;
  const titleSize = isSmallFormat ? 8 : 12;
  const ticketNumSize = isSmallFormat ? 11 : 16;
  const bodySize = isSmallFormat ? 7 : 9;
  const priceSize = isSmallFormat ? 8 : 10;
  const fieldSize = isSmallFormat ? 6 : 8;
  const footerSize = isSmallFormat ? 6 : 7;
  const qrSize = isSmallFormat ? 50 : 80;
  const barcodeWidth = isSmallFormat ? 90 : 120;
  const barcodeHeight = isSmallFormat ? 30 : 40;
  
  // Draw border (dashed for tear-off if specified)
  if (perforationLine) {
    doc.save();
    doc.strokeColor('#999999');
    doc.lineWidth(1);
    doc.dash(5, { space: 5 });
    doc.rect(x, y, ticketWidth, ticketHeight).stroke();
    doc.restore();
  } else {
    doc.rect(x, y, ticketWidth, ticketHeight).stroke();
  }

  // Title with emoji
  doc.fontSize(titleSize)
     .font('Helvetica-Bold')
     .text('🎫 RAFFLE TICKET', x + padding, y + padding, {
       width: ticketWidth - (padding * 2),
       align: 'center'
     });

  // Ticket number (prominent)
  const ticketNumY = y + padding + (isSmallFormat ? 15 : 20);
  doc.fontSize(ticketNumSize)
     .font('Helvetica-Bold')
     .text(ticket.ticket_number, x + padding, ticketNumY, {
       width: ticketWidth - qrSize - (padding * 3),
       align: 'left'
     });

  const categoryY = ticketNumY + (isSmallFormat ? 16 : 18);
  doc.fontSize(bodySize)
     .font('Helvetica')
     .text(`Category: ${CATEGORY_NAMES[ticket.category]?.full || ticket.category}`, x + padding, categoryY, {
       width: ticketWidth - qrSize - (padding * 3)
     });
  
  const priceY = categoryY + (isSmallFormat ? 12 : 14);
  doc.fontSize(priceSize)
     .font('Helvetica-Bold')
     .text(`Price: $${parseFloat(ticket.price).toFixed(2)}`, x + padding, priceY, {
       width: ticketWidth - qrSize - (padding * 3)
     });

  // QR Code (right side)
  if (qrMainImage) {
    const qrX = x + ticketWidth - qrSize - padding;
    const qrY = y + padding + (isSmallFormat ? 8 : 10);
    doc.image(qrMainImage, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // EAN-13 Barcode (center area)
  if (barcodeImage) {
    const barcodeX = x + (ticketWidth - barcodeWidth) / 2;
    const barcodeY = y + priceY + (isSmallFormat ? 20 : 30);
    doc.image(barcodeImage, barcodeX, barcodeY, {
      width: barcodeWidth,
      height: barcodeHeight
    });
    
    // Display barcode number below the barcode
    if (ticket.barcode) {
      doc.fontSize(footerSize)
         .font('Helvetica')
         .text(ticket.barcode, x + padding, barcodeY + barcodeHeight + 2, {
           width: ticketWidth - (padding * 2),
           align: 'center'
         });
    }
  }

  // Buyer information fields
  const fieldsStartY = y + ticketHeight - (isSmallFormat ? 28 : 35);
  doc.fontSize(fieldSize)
     .font('Helvetica');
  
  if (isSmallFormat) {
    // Compact layout for small tickets
    doc.text('Date: _____________', x + padding, fieldsStartY, {
      width: ticketWidth - (padding * 2)
    });
    doc.text('Name: _____________', x + padding, fieldsStartY + 8, {
      width: ticketWidth - (padding * 2)
    });
    doc.text('Phone: ____________', x + padding, fieldsStartY + 16, {
      width: ticketWidth - (padding * 2)
    });
  } else {
    // Original layout for larger tickets
    doc.text('Date: ___________________', x + padding, fieldsStartY)
       .text('Name: ___________________', x + padding + 140, fieldsStartY);
    doc.text('Phone: __________________', x + padding, fieldsStartY + 12)
       .text('Draw Date: [INSERT DATE]', x + padding + 140, fieldsStartY + 12);
  }

  // Footer
  doc.fontSize(footerSize)
     .font('Helvetica')
     .text('Keep this ticket for entry', x + padding, y + ticketHeight - (isSmallFormat ? 8 : 15), {
       width: ticketWidth - (padding * 2),
       align: 'center'
     });
}

/**
 * Draw a single ticket BACK side on the PDF (seller stub - tracks who sold it)
 * 
 * @param {PDFDocument} doc - PDF document
 * @param {Object} ticket - Ticket data
 * @param {Object} template - Template configuration
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {Buffer} qrStubImage - Stub QR code image buffer
 */
function drawTicketBack(doc, ticket, template, x, y, qrStubImage) {
  const { ticketWidth, ticketHeight, perforationLine } = template;
  
  // Detect if this is the smaller LETTER_8_TICKETS format
  const isSmallFormat = ticketWidth < 200;
  
  // Scale down content for smaller tickets
  const padding = isSmallFormat ? 4 : 8;
  const titleSize = isSmallFormat ? 8 : 12;
  const ticketNumSize = isSmallFormat ? 9 : 11;
  const bodySize = isSmallFormat ? 7 : 9;
  const fieldSize = isSmallFormat ? 6 : 8;
  const footerSize = isSmallFormat ? 6 : 7;
  const qrSize = isSmallFormat ? 36 : 50;
  
  // Draw border (dashed for tear-off if specified)
  if (perforationLine) {
    doc.save();
    doc.strokeColor('#999999');
    doc.lineWidth(1);
    doc.dash(5, { space: 5 });
    doc.rect(x, y, ticketWidth, ticketHeight).stroke();
    doc.restore();
  } else {
    doc.rect(x, y, ticketWidth, ticketHeight).stroke();
  }

  // Title with emoji
  doc.fontSize(titleSize)
     .font('Helvetica-Bold')
     .text('📋 SELLER STUB', x + padding, y + padding, {
       width: ticketWidth - qrSize - (padding * 3),
       align: 'left'
     });

  // Small QR code (top right)
  if (qrStubImage) {
    const qrX = x + ticketWidth - qrSize - padding;
    const qrY = y + padding;
    doc.image(qrStubImage, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // Ticket number
  const ticketNumY = y + padding + (isSmallFormat ? 15 : 20);
  doc.fontSize(ticketNumSize)
     .font('Helvetica-Bold')
     .text(`Ticket #: ${ticket.ticket_number}`, x + padding, ticketNumY);

  const categoryY = ticketNumY + (isSmallFormat ? 12 : 15);
  doc.fontSize(bodySize)
     .font('Helvetica')
     .text(`Category: ${CATEGORY_NAMES[ticket.category]?.short || ticket.category}`, x + padding, categoryY);

  // Seller information fields
  const fieldsStartY = categoryY + (isSmallFormat ? 18 : 20);
  doc.fontSize(fieldSize)
     .font('Helvetica');
  
  if (isSmallFormat) {
    // Compact layout for small tickets
    doc.text('Sold By: ___________', x + padding, fieldsStartY);
    doc.text('Seller ID: _________', x + padding, fieldsStartY + 10);
    doc.text('Buyer Name: ________', x + padding, fieldsStartY + 20);
    doc.text('Buyer Phone: _______', x + padding, fieldsStartY + 30);
    doc.text('Date Sold: _________', x + padding, fieldsStartY + 40);
    doc.text('Payment: [Cash/Check/Card]', x + padding, fieldsStartY + 50);
  } else {
    // Original layout for larger tickets
    doc.text('Sold By: __________________', x + padding, fieldsStartY)
       .text('Seller ID: _____________', x + padding + 140, fieldsStartY);
    doc.text('Buyer Name: _______________', x + padding, fieldsStartY + 12)
       .text('Buyer Phone: ______________', x + padding + 140, fieldsStartY + 12);
    doc.text('Date Sold: ________________', x + padding, fieldsStartY + 24)
       .text('Payment: [Cash/Check/Card]', x + padding + 140, fieldsStartY + 24);
  }

  // Footer
  doc.fontSize(footerSize)
     .font('Helvetica-Bold')
     .text('Office Use Only - Keep Record', x + padding, y + ticketHeight - (isSmallFormat ? 8 : 15), {
       width: ticketWidth - (padding * 2),
       align: 'center'
     });
}

/**
 * Draw ticket FRONT with tear-off perforation and custom design
 * CRITICAL: NO BARCODE ON FRONT! Barcode appears ONLY on back side stub.
 */
async function drawTicketFrontWithTearoff(doc, ticket, template, x, y, qrMainImage, customDesign = null) {
  const { ticketWidth, ticketHeight, mainTicketHeight, tearOffY, tearOffHeight } = template;
  
  // === MAIN TICKET (TOP) ===
  
  // Custom background with rotation/scaling
  if (customDesign && customDesign.front_image_path) {
    const imagePath = path.join(__dirname, '..', 'public', customDesign.front_image_path);
    if (fs.existsSync(imagePath)) {
      doc.save();
      doc.rect(x, y, ticketWidth, mainTicketHeight).clip();
      
      // Apply rotation
      if (customDesign.rotation) {
        const centerX = x + ticketWidth / 2;
        const centerY = y + mainTicketHeight / 2;
        doc.rotate(customDesign.rotation, { origin: [centerX, centerY] });
      }
      
      // Apply scaling
      const scaleW = (customDesign.scale_width || 100) / 100;
      const scaleH = (customDesign.scale_height || 100) / 100;
      
      doc.image(imagePath, 
        x + (customDesign.offset_x || 0), 
        y + (customDesign.offset_y || 0), {
        width: ticketWidth * scaleW,
        height: mainTicketHeight * scaleH
      });
      
      doc.restore();
    }
  } else {
    doc.rect(x, y, ticketWidth, mainTicketHeight).fillAndStroke('#FFFFFF', '#000000');
  }
  
  // Semi-transparent overlays for readability
  if (customDesign) {
    doc.rect(x + 10, y + 5, ticketWidth - 20, 35)
       .fillOpacity(0.85).fill('#FFFFFF').fillOpacity(1);
  }
  
  // Header
  doc.fontSize(14).font('Helvetica-Bold').fillColor('#000000');
  doc.text('RAFFLE TICKET', x + 8, y + 8, { width: ticketWidth - 16, align: 'center' });
  
  // Ticket number (LARGE, CENTERED)
  doc.fontSize(16).font('Helvetica-Bold');
  doc.text(`Ticket #: ${ticket.ticket_number}`, x + 8, y + 25, { width: ticketWidth - 16, align: 'center' });
  
  // Category badge
  const categoryColors = {
    'ABC': '#FF6B6B', 'EFG': '#4ECDC4', 'JKL': '#45B7D1', 'XYZ': '#F7DC6F'
  };
  const categoryColor = categoryColors[ticket.category] || '#95a5a6';
  doc.rect(x + 12, y + 48, 70, 20).fillAndStroke(categoryColor, '#2c3e50');
  doc.fontSize(12).fillColor('#ffffff').text(ticket.category, x + 17, y + 53, { width: 60, align: 'center' });
  
  // Price
  doc.fontSize(11).fillColor('#000000').font('Helvetica');
  doc.text('Price:', x + 95, y + 53);
  doc.font('Helvetica-Bold').text(`$${parseFloat(ticket.price).toFixed(2)}`, x + 125, y + 53);
  
  // QR Code (top right, NO barcode on front!)
  if (qrMainImage) {
    if (customDesign) {
      doc.rect(x + ticketWidth - 65, y + 5, 60, 60).fillOpacity(0.95).fill('#FFFFFF').fillOpacity(1);
    }
    doc.image(qrMainImage, x + ticketWidth - 60, y + 8, { width: 50, height: 50 });
  }
  
  // === PERFORATION LINE ===
  
  const perforationY = y + tearOffY;
  doc.fontSize(12).fillColor('#666666').text('✂', x + 5, perforationY - 6);
  doc.strokeColor('#999999').lineWidth(1).dash(5, 3);
  doc.moveTo(x + 20, perforationY).lineTo(x + ticketWidth - 20, perforationY).stroke();
  doc.undash();
  doc.fontSize(7).fillColor('#999999').text('TEAR OFF HERE', x + ticketWidth - 70, perforationY - 4);
  
  // === TEAR-OFF STUB (BOTTOM) ===
  
  const stubY = y + tearOffY + 2;
  
  // Custom background for stub
  if (customDesign && customDesign.front_image_path) {
    const imagePath = path.join(__dirname, '..', 'public', customDesign.front_image_path);
    if (fs.existsSync(imagePath)) {
      doc.save();
      doc.rect(x, stubY, ticketWidth, tearOffHeight - 2).clip();
      doc.image(imagePath, x, stubY, {
        width: ticketWidth,
        height: tearOffHeight - 2
      });
      doc.restore();
    }
  } else {
    doc.rect(x, stubY, ticketWidth, tearOffHeight - 2).fillAndStroke('#F8F9FA', '#000000');
  }
  
  // Border
  doc.rect(x, y, ticketWidth, ticketHeight).stroke('#000000');
  
  // Stub header
  if (customDesign) {
    doc.rect(x + 5, stubY + 3, ticketWidth - 10, 30).fillOpacity(0.9).fill('#FFFFFF').fillOpacity(1);
  }
  doc.fontSize(10).font('Helvetica-Bold').fillColor('#000000');
  doc.text('SELLER STUB', x + 8, stubY + 5, { width: ticketWidth - 16, align: 'center' });
  doc.fontSize(11).text(`#${ticket.ticket_number}`, x + 8, stubY + 18);
  
  // Small QR on stub
  if (qrMainImage) {
    if (customDesign) {
      doc.rect(x + ticketWidth - 47, stubY + 3, 42, 42).fillOpacity(0.95).fill('#FFFFFF').fillOpacity(1);
    }
    doc.image(qrMainImage, x + ticketWidth - 43, stubY + 5, { width: 35, height: 35 });
  }
  
  // **NO BARCODE ON FRONT STUB - It's only on the back!**
}

/**
 * Draw ticket BACK with tear-off perforation and BARCODE on stub
 * CRITICAL: Barcode appears ONLY on back side stub (adjustable size)
 */
async function drawTicketBackWithTearoff(doc, ticket, template, x, y, qrStubImage, customDesign = null, barcodeSettings = {}) {
  const { ticketWidth, ticketHeight, mainTicketHeight, tearOffY, tearOffHeight } = template;
  
  // Adjustable barcode size (from settings)
  const barcodeWidth = barcodeSettings.width || 90;
  const barcodeHeight = barcodeSettings.height || 20;
  
  // === MAIN TICKET BACK (TOP) ===
  
  // Custom background
  if (customDesign && customDesign.back_image_path) {
    const imagePath = path.join(__dirname, '..', 'public', customDesign.back_image_path);
    if (fs.existsSync(imagePath)) {
      doc.save();
      doc.rect(x, y, ticketWidth, mainTicketHeight).clip();
      
      // Apply rotation/scaling
      if (customDesign.rotation) {
        const centerX = x + ticketWidth / 2;
        const centerY = y + mainTicketHeight / 2;
        doc.rotate(customDesign.rotation, { origin: [centerX, centerY] });
      }
      const scaleW = (customDesign.scale_width || 100) / 100;
      const scaleH = (customDesign.scale_height || 100) / 100;
      
      doc.image(imagePath, x, y, {
        width: ticketWidth * scaleW,
        height: mainTicketHeight * scaleH
      });
      doc.restore();
    }
  } else {
    doc.rect(x, y, ticketWidth, mainTicketHeight).fillAndStroke('#F8F9FA', '#000000');
  }
  
  // Terms section
  if (customDesign) {
    doc.rect(x + 10, y + 10, ticketWidth - 20, mainTicketHeight - 20)
       .fillOpacity(0.9).fill('#FFFFFF').fillOpacity(1);
  }
  doc.fontSize(10).font('Helvetica-Bold').fillColor('#000000');
  doc.text('RAFFLE TERMS', x + 8, y + 12, { width: ticketWidth - 16, align: 'center' });
  
  doc.fontSize(7).font('Helvetica').fillColor('#333333');
  doc.text('• Ticket is non-refundable', x + 13, y + 25);
  doc.text('• Winner notified by phone', x + 13, y + 35);
  doc.text('• Prize must be claimed within 30 days', x + 13, y + 45);
  
  // === PERFORATION LINE ===
  
  const perforationY = y + tearOffY;
  doc.fontSize(12).fillColor('#666666').text('✂', x + 5, perforationY - 6);
  doc.strokeColor('#999999').lineWidth(1).dash(5, 3);
  doc.moveTo(x + 20, perforationY).lineTo(x + ticketWidth - 20, perforationY).stroke();
  doc.undash();
  doc.fontSize(7).fillColor('#999999').text('TEAR OFF HERE', x + ticketWidth - 70, perforationY - 4);
  
  // === TEAR-OFF STUB BACK (BOTTOM) - **BARCODE HERE** ===
  
  const stubY = y + tearOffY + 2;
  
  if (customDesign && customDesign.back_image_path) {
    const imagePath = path.join(__dirname, '..', 'public', customDesign.back_image_path);
    if (fs.existsSync(imagePath)) {
      doc.save();
      doc.rect(x, stubY, ticketWidth, tearOffHeight - 2).clip();
      doc.image(imagePath, x, stubY, { width: ticketWidth, height: tearOffHeight - 2 });
      doc.restore();
    }
  } else {
    doc.rect(x, stubY, ticketWidth, tearOffHeight - 2).fillAndStroke('#FFFFFF', '#000000');
  }
  
  doc.rect(x, y, ticketWidth, ticketHeight).stroke('#000000');
  
  // Seller info
  if (customDesign) {
    doc.rect(x + 5, stubY + 3, ticketWidth - 10, tearOffHeight - 8)
       .fillOpacity(0.9).fill('#FFFFFF').fillOpacity(1);
  }
  doc.fontSize(9).font('Helvetica-Bold').fillColor('#000000');
  doc.text('SELLER RECORD', x + 8, stubY + 5, { width: ticketWidth - 16, align: 'center' });
  
  doc.fontSize(8).font('Helvetica');
  doc.text(`Ticket: ${ticket.ticket_number}`, x + 13, stubY + 18);
  
  // **BARCODE ON BACK STUB** (adjustable size)
  if (ticket.barcode) {
    const barcodeX = x + (ticketWidth - barcodeWidth) / 2;
    const barcodeY = stubY + tearOffHeight - barcodeHeight - 10;
    
    if (customDesign) {
      doc.rect(barcodeX - 5, barcodeY - 3, barcodeWidth + 10, barcodeHeight + 8)
         .fillOpacity(0.95).fill('#FFFFFF').fillOpacity(1);
    }
    
    // Generate barcode with adjustable size using module-level constants
    try {
      const barcodeBuffer = await bwipjs.toBuffer({
        bcid: 'ean13',
        text: ticket.barcode,
        scale: barcodeWidth / BARCODE_BASE_WIDTH, // Scale proportionally from base width
        height: Math.floor(barcodeHeight / BARCODE_HEIGHT_RATIO), // Convert points to mm for bwip-js
        includetext: false
      });
      
      doc.image(barcodeBuffer, barcodeX, barcodeY, { width: barcodeWidth, height: barcodeHeight });
      
      doc.fontSize(6).fillColor('#000000');
      doc.text(ticket.barcode, x + 8, barcodeY + barcodeHeight + 1, { width: ticketWidth - 16, align: 'center' });
    } catch (error) {
      console.error('Barcode generation error:', error);
    }
  }
}

/**
 * Generate PDF for ticket printing with proper duplex layout
 * Front side (odd pages): Buyer tickets
 * Back side (even pages): Seller stubs
 * 
 * @param {Array} tickets - Array of ticket objects
 * @param {string} paperType - Paper type (AVERY_16145 or PRINTWORKS)
 * @param {number} printJobId - Print job ID
 * @param {Object} customDesign - Optional custom design configuration
 * @param {Object} barcodeSettings - Optional barcode size settings
 * @returns {Promise<PDFDocument>} - PDF document stream
 */
async function generatePrintPDF(tickets, paperType, printJobId, customDesign = null, barcodeSettings = {}) {
  const template = TEMPLATES[paperType];
  if (!template) {
    throw new Error(`Unknown paper type: ${paperType}`);
  }

  // Determine if we should use tear-off layout
  const useTearoffLayout = template.mainTicketHeight && template.tearOffHeight && template.tearOffY;

  // Create PDF document
  const doc = new PDFDocument({
    size: [template.pageWidth, template.pageHeight],
    margin: 0
  });

  let ticketCount = 0;
  const totalTickets = tickets.length;

  // Process tickets in batches per page
  for (let i = 0; i < tickets.length; i += template.ticketsPerPage) {
    const batch = tickets.slice(i, i + template.ticketsPerPage);
    
    // Add page for FRONT side (buyer tickets) - always add page (even for first batch)
    if (i > 0) doc.addPage();
    
    // Pre-generate all codes for the batch to avoid redundant generation
    const batchWithCodes = await Promise.all(batch.map(async (ticket) => {
      // Generate codes if not already generated
      const ticketService = require('./ticketService');
      const barcodeGenerator = require('./barcodeGenerator');
      if (!ticket.barcode || !ticket.qr_code_data) {
        const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
        ticket.barcode = codes.barcode;
        ticket.qr_code_data = codes.qrCodeData;
      }

      // Detect if this is the smaller LETTER_8_TICKETS format
      const isSmallFormat = template.ticketWidth < 200;
      
      // Generate QR code images with full ticket data (scaled for format)
      const qrMainBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: isSmallFormat ? 67 : 96, // 0.7" at 96 DPI for small format, 1" for regular
        errorCorrectionLevel: 'M'
      });
      
      const qrStubBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: isSmallFormat ? 48 : 50, // 0.5" at 96 DPI for small format
        errorCorrectionLevel: 'M'
      });
      
      // Generate EAN-13 barcode image (using bwip-js)
      const bwipjs = require('bwip-js');
      let barcodeBuffer = null;
      if (ticket.barcode) {
        try {
          barcodeBuffer = await bwipjs.toBuffer({
            bcid: 'ean13',
            text: ticket.barcode,
            scale: isSmallFormat ? 1.5 : 2,
            height: isSmallFormat ? 8 : 10,
            includetext: false,
            textxalign: 'center'
          });
        } catch (error) {
          console.error('Barcode generation error:', error);
        }
      }
      
      return {
        ticket,
        qrMainBuffer,
        qrStubBuffer,
        barcodeBuffer
      };
    }));
    
    // Draw FRONT side tickets in grid layout
    for (let j = 0; j < batchWithCodes.length; j++) {
      const { ticket, qrMainBuffer, barcodeBuffer } = batchWithCodes[j];

      // Calculate position in grid (2 columns x N rows)
      const col = j % template.columns;
      const row = Math.floor(j / template.columns);
      
      const x = template.leftMargin + (col * template.ticketWidth) + (col * template.spacing);
      const y = template.topMargin + (row * template.ticketHeight) + (row * template.spacing);

      // Draw FRONT side - use tear-off layout if enabled
      if (useTearoffLayout) {
        await drawTicketFrontWithTearoff(doc, ticket, template, x, y, qrMainBuffer, customDesign);
      } else {
        await drawTicketFront(doc, ticket, template, x, y, qrMainBuffer, barcodeBuffer);
      }
    }
    
    // Add page for BACK side (seller stubs) - for duplex printing
    doc.addPage();
    
    // Draw BACK side stubs in same layout (will be on back when printed duplex)
    for (let j = 0; j < batchWithCodes.length; j++) {
      const { ticket, qrStubBuffer } = batchWithCodes[j];

      // Calculate position in grid (same as front)
      const col = j % template.columns;
      const row = Math.floor(j / template.columns);
      
      const x = template.leftMargin + (col * template.ticketWidth) + (col * template.spacing);
      const y = template.topMargin + (row * template.ticketHeight) + (row * template.spacing);

      // Draw BACK side - use tear-off layout if enabled
      if (useTearoffLayout) {
        await drawTicketBackWithTearoff(doc, ticket, template, x, y, qrStubBuffer, customDesign, barcodeSettings);
      } else {
        drawTicketBack(doc, ticket, template, x, y, qrStubBuffer);
      }
      
      // Mark ticket as printed after processing both sides
      const ticketService = require('./ticketService');
      await ticketService.markAsPrinted(ticket.ticket_number);
      
      ticketCount++;
      
      // Update progress
      const progress = Math.round((ticketCount / totalTickets) * 100);
      if (ticketCount % 5 === 0 || ticketCount === totalTickets) {
        await updatePrintJobStatus(printJobId, 'in_progress', progress);
      }
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

/**
 * Generate PDF for ticket printing with custom template
 * Uses uploaded custom images instead of default template design
 * Overlays barcodes and QR codes on top of custom template
 * 
 * @param {Array} tickets - Array of ticket objects
 * @param {Object} customTemplate - Custom template object from database
 * @param {string} paperType - Paper type (AVERY_16145 or PRINTWORKS)
 * @param {number} printJobId - Print job ID
 * @returns {Promise<PDFDocument>} - PDF document stream
 */
async function generateCustomTemplatePDF(tickets, customTemplate, paperType, printJobId) {
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
  const totalTickets = tickets.length;

  // Validate and resolve paths for custom template images
  // Security: Ensure paths don't contain traversal attempts and only reference files in uploads/templates
  const validateTemplatePath = (filePath) => {
    if (!filePath || typeof filePath !== 'string') {
      throw new Error('Invalid template path');
    }
    // Remove any path traversal attempts
    const normalized = path.normalize(filePath).replace(/^(\.\.[\/\\])+/, '');
    // Ensure the path is within uploads/templates directory
    if (normalized.includes('..') || path.isAbsolute(normalized)) {
      throw new Error('Invalid template path - path traversal not allowed');
    }
    return normalized;
  };

  const frontImageFile = validateTemplatePath(customTemplate.front_image_path);
  const backImageFile = validateTemplatePath(customTemplate.back_image_path);
  
  const frontImagePath = path.join(__dirname, '..', 'uploads', 'templates', path.basename(frontImageFile));
  const backImagePath = path.join(__dirname, '..', 'uploads', 'templates', path.basename(backImageFile));

  // Check if images exist
  if (!fs.existsSync(frontImagePath)) {
    throw new Error(`Front template image not found: ${path.basename(frontImageFile)}`);
  }
  if (!fs.existsSync(backImagePath)) {
    throw new Error(`Back template image not found: ${path.basename(backImageFile)}`);
  }

  // Load template images once for reuse (performance optimization)
  let frontImageBuffer, backImageBuffer;
  try {
    frontImageBuffer = fs.readFileSync(frontImagePath);
    backImageBuffer = fs.readFileSync(backImagePath);
  } catch (error) {
    throw new Error(`Failed to load template images: ${error.message}`);
  }

  // Process tickets in batches per page
  for (let i = 0; i < tickets.length; i += template.ticketsPerPage) {
    const batch = tickets.slice(i, i + template.ticketsPerPage);
    
    // Add page for FRONT side (buyer tickets)
    if (i > 0) doc.addPage();
    
    // Pre-generate all codes for the batch
    const batchWithCodes = await Promise.all(batch.map(async (ticket) => {
      // Generate codes if not already generated
      const ticketService = require('./ticketService');
      if (!ticket.barcode || !ticket.qr_code_data) {
        const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
        ticket.barcode = codes.barcode;
        ticket.qr_code_data = codes.qrCodeData;
      }

      // Detect if this is the smaller LETTER_8_TICKETS format
      const isSmallFormat = template.ticketWidth < 200;

      // Generate QR code images with full ticket data
      const qrMainBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: isSmallFormat ? 67 : 96,
        errorCorrectionLevel: 'M'
      });
      
      const qrStubBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: isSmallFormat ? 48 : 50,
        errorCorrectionLevel: 'M'
      });
      
      // Generate EAN-13 barcode image
      const bwipjs = require('bwip-js');
      let barcodeBuffer = null;
      if (ticket.barcode) {
        try {
          barcodeBuffer = await bwipjs.toBuffer({
            bcid: 'ean13',
            text: ticket.barcode,
            scale: isSmallFormat ? 1.5 : 2,
            height: isSmallFormat ? 8 : 10,
            includetext: false,
            textxalign: 'center'
          });
        } catch (error) {
          console.error('Barcode generation error:', error);
        }
      }
      
      return {
        ticket,
        qrMainBuffer,
        qrStubBuffer,
        barcodeBuffer
      };
    }));
    
    // Draw FRONT side tickets with custom template
    for (let j = 0; j < batchWithCodes.length; j++) {
      const { ticket, qrMainBuffer, barcodeBuffer } = batchWithCodes[j];

      // Calculate position in grid (2 columns x N rows)
      const col = j % template.columns;
      const row = Math.floor(j / template.columns);
      
      const x = template.leftMargin + (col * template.ticketWidth) + (col * template.spacing);
      const y = template.topMargin + (row * template.ticketHeight) + (row * template.spacing);

      // Draw custom template image as background (using pre-loaded buffer)
      try {
        doc.image(frontImageBuffer, x, y, {
          width: template.ticketWidth,
          height: template.ticketHeight,
          fit: customTemplate.fit_mode || 'cover'
        });
      } catch (error) {
        console.error('Error drawing front template image:', error);
        // Fallback to default template
        await drawTicketFront(doc, ticket, template, x, y, qrMainBuffer, barcodeBuffer);
        continue;
      }

      // Overlay QR code (top right corner)
      if (qrMainBuffer) {
        const qrSize = 60;
        const qrX = x + template.ticketWidth - qrSize - 10;
        const qrY = y + 10;
        doc.image(qrMainBuffer, qrX, qrY, {
          width: qrSize,
          height: qrSize
        });
      }

      // Overlay barcode (bottom center)
      if (barcodeBuffer) {
        const barcodeWidth = 120;
        const barcodeHeight = 40;
        const barcodeX = x + (template.ticketWidth - barcodeWidth) / 2;
        const barcodeY = y + template.ticketHeight - barcodeHeight - 15;
        
        doc.image(barcodeBuffer, barcodeX, barcodeY, {
          width: barcodeWidth,
          height: barcodeHeight
        });
        
        // Barcode number below
        if (ticket.barcode) {
          doc.fontSize(7)
             .font('Helvetica')
             .fillColor('#000000')
             .text(ticket.barcode, x, barcodeY + barcodeHeight + 2, {
               width: template.ticketWidth,
               align: 'center'
             });
        }
      }
    }
    
    // Add page for BACK side (seller stubs)
    doc.addPage();
    
    // Draw BACK side stubs with custom template
    for (let j = 0; j < batchWithCodes.length; j++) {
      const { ticket, qrStubBuffer } = batchWithCodes[j];

      // Calculate position in grid (same as front)
      const col = j % template.columns;
      const row = Math.floor(j / template.columns);
      
      const x = template.leftMargin + (col * template.ticketWidth) + (col * template.spacing);
      const y = template.topMargin + (row * template.ticketHeight) + (row * template.spacing);

      // Draw custom template image as background (using pre-loaded buffer)
      try {
        doc.image(backImageBuffer, x, y, {
          width: template.ticketWidth,
          height: template.ticketHeight,
          fit: customTemplate.fit_mode || 'cover'
        });
      } catch (error) {
        console.error('Error drawing back template image:', error);
        // Fallback to default template
        drawTicketBack(doc, ticket, template, x, y, qrStubBuffer);
        continue;
      }

      // Overlay small QR code (top right corner)
      if (qrStubBuffer) {
        const qrSize = 50;
        const qrX = x + template.ticketWidth - qrSize - 10;
        const qrY = y + 10;
        doc.image(qrStubBuffer, qrX, qrY, {
          width: qrSize,
          height: qrSize
        });
      }
      
      // Mark ticket as printed after processing both sides
      const ticketService = require('./ticketService');
      await ticketService.markAsPrinted(ticket.ticket_number);
      
      ticketCount++;
      
      // Update progress
      const progress = Math.round((ticketCount / totalTickets) * 100);
      if (ticketCount % 5 === 0 || ticketCount === totalTickets) {
        await updatePrintJobStatus(printJobId, 'in_progress', progress);
      }
    }
  }

  // Mark job as completed
  await updatePrintJobStatus(printJobId, 'completed', 100);

  return doc;
}

/**
 * Draw tear-off line for custom templates
 * 
 * @param {PDFDocument} doc - PDF document
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {number} width - Ticket width
 * @param {number} height - Ticket height
 */
function drawTearOffLine(doc, x, y, width, height) {
  doc.save();
  doc.strokeColor('#999999');
  doc.lineWidth(1);
  doc.dash(5, { space: 5 }); // Dashed line pattern
  
  // Draw horizontal line at bottom of ticket
  doc.moveTo(x, y + height);
  doc.lineTo(x + width, y + height);
  doc.stroke();
  
  doc.restore();
}

/**
 * Generate PDF with category-specific custom designs (new system)
 * Uses ticket_designs table for category-specific backgrounds
 * Optimized for LETTER_8_TICKETS format (4x2 grid)
 * 
 * @param {Array} tickets - Array of ticket objects
 * @param {Object} categoryDesign - Design object from ticket_designs table
 * @returns {Promise<Buffer>} - PDF buffer
 */
async function generateCategoryCustomPDF(tickets, categoryDesign) {
  const paperType = TEMPLATES.LETTER_8_TICKETS;
  
  // Create PDF document
  const doc = new PDFDocument({
    size: [paperType.pageWidth, paperType.pageHeight],
    margin: 0
  });

  // Collect PDF chunks
  const chunks = [];
  doc.on('data', chunk => chunks.push(chunk));
  
  const pdfPromise = new Promise((resolve, reject) => {
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });

  let frontImageBuffer = null;
  let backImageBuffer = null;

  // Load custom design images if available
  if (categoryDesign) {
    // Try to load from file path first
    if (categoryDesign.front_image_path) {
      try {
        const frontPath = path.join(__dirname, '..', 'uploads', 'designs', path.basename(categoryDesign.front_image_path));
        if (fs.existsSync(frontPath)) {
          frontImageBuffer = fs.readFileSync(frontPath);
        }
      } catch (error) {
        console.warn('Could not load front image from path:', error.message);
      }
    }
    
    // Try to load from base64 if no file buffer
    if (!frontImageBuffer && categoryDesign.front_image_base64) {
      try {
        const base64Data = categoryDesign.front_image_base64.replace(/^data:image\/\w+;base64,/, '');
        frontImageBuffer = Buffer.from(base64Data, 'base64');
      } catch (error) {
        console.warn('Could not decode front image base64:', error.message);
      }
    }

    // Same for back image
    if (categoryDesign.back_image_path) {
      try {
        const backPath = path.join(__dirname, '..', 'uploads', 'designs', path.basename(categoryDesign.back_image_path));
        if (fs.existsSync(backPath)) {
          backImageBuffer = fs.readFileSync(backPath);
        }
      } catch (error) {
        console.warn('Could not load back image from path:', error.message);
      }
    }
    
    if (!backImageBuffer && categoryDesign.back_image_base64) {
      try {
        const base64Data = categoryDesign.back_image_base64.replace(/^data:image\/\w+;base64,/, '');
        backImageBuffer = Buffer.from(base64Data, 'base64');
      } catch (error) {
        console.warn('Could not decode back image base64:', error.message);
      }
    }
  }

  // Pre-generate all codes for all tickets
  const ticketsWithCodes = await Promise.all(tickets.map(async (ticket) => {
    // Generate codes if not already generated
    const ticketService = require('./ticketService');
    if (!ticket.barcode || !ticket.qr_code_data) {
      const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
      ticket.barcode = codes.barcode;
      ticket.qr_code_data = codes.qrCodeData;
    }

    // Generate QR code and barcode images (smaller for LETTER_8_TICKETS)
    const qrMainBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
      size: 67, // 0.7" at 96 DPI
      errorCorrectionLevel: 'M'
    });
    
    const qrStubBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
      size: 48, // 0.5" at 96 DPI
      errorCorrectionLevel: 'M'
    });
    
    // Generate EAN-13 barcode
    const bwipjs = require('bwip-js');
    let barcodeBuffer = null;
    if (ticket.barcode) {
      try {
        barcodeBuffer = await bwipjs.toBuffer({
          bcid: 'ean13',
          text: ticket.barcode,
          scale: 1.5,
          height: 8,
          includetext: false,
          textxalign: 'center'
        });
      } catch (error) {
        console.error('Barcode generation error:', error);
      }
    }
    
    return {
      ticket,
      qrMainBuffer,
      qrStubBuffer,
      barcodeBuffer
    };
  }));

  // Process tickets in batches of 8 per page
  for (let i = 0; i < ticketsWithCodes.length; i += paperType.ticketsPerPage) {
    const batch = ticketsWithCodes.slice(i, i + paperType.ticketsPerPage);
    
    // Add page for FRONT side
    if (i > 0) doc.addPage();
    
    // Draw FRONT side tickets in 4x2 grid
    for (let j = 0; j < batch.length; j++) {
      const { ticket, qrMainBuffer, barcodeBuffer } = batch[j];
      
      const col = j % paperType.columns;
      const row = Math.floor(j / paperType.columns);
      
      const x = col * paperType.ticketWidth;
      const y = row * paperType.ticketHeight;
      
      // Draw custom background if available
      if (frontImageBuffer) {
        try {
          doc.image(frontImageBuffer, x, y, {
            width: paperType.ticketWidth,
            height: paperType.ticketHeight,
            align: 'center',
            valign: 'center'
          });
        } catch (error) {
          console.error('Error drawing front background:', error);
        }
      }
      
      // Draw ticket content with semi-transparent backgrounds
      drawCustomTicketContent(doc, ticket, x, y, paperType.ticketWidth, paperType.ticketHeight, qrMainBuffer, barcodeBuffer);
      
      // Draw dashed border for tear-off line
      doc.save()
         .strokeColor('#999999')
         .lineWidth(0.5)
         .dash(3, 3)
         .rect(x, y, paperType.ticketWidth, paperType.ticketHeight)
         .stroke()
         .restore();
    }
    
    // Add page for BACK side
    doc.addPage();
    
    // Draw BACK side stubs in same layout
    for (let j = 0; j < batch.length; j++) {
      const { ticket, qrStubBuffer } = batch[j];
      
      const col = j % paperType.columns;
      const row = Math.floor(j / paperType.columns);
      
      const x = col * paperType.ticketWidth;
      const y = row * paperType.ticketHeight;
      
      // Draw custom background if available
      if (backImageBuffer) {
        try {
          doc.image(backImageBuffer, x, y, {
            width: paperType.ticketWidth,
            height: paperType.ticketHeight,
            align: 'center',
            valign: 'center'
          });
        } catch (error) {
          console.error('Error drawing back background:', error);
        }
      }
      
      // Draw ticket stub content
      drawCustomTicketBackContent(doc, ticket, x, y, paperType.ticketWidth, paperType.ticketHeight, qrStubBuffer);
      
      // Draw dashed border
      doc.save()
         .strokeColor('#999999')
         .lineWidth(0.5)
         .dash(3, 3)
         .rect(x, y, paperType.ticketWidth, paperType.ticketHeight)
         .stroke()
         .restore();
    }
  }

  doc.end();
  return pdfPromise;
}

/**
 * Draw ticket content with semi-transparent backgrounds for readability
 * Optimized for LETTER_8_TICKETS format (2.125" × 5.5")
 */
function drawCustomTicketContent(doc, ticket, x, y, width, height, qrBuffer, barcodeBuffer) {
  const padding = 4;

  // Semi-transparent white background for ticket number area
  doc.rect(x + 10, y + 10, width - 20, 30)
     .fillOpacity(0.85)
     .fill('#FFFFFF')
     .fillOpacity(1);

  // Ticket number (large, centered)
  doc.fontSize(14)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text(`Ticket: ${ticket.ticket_number}`, x + 15, y + 18, {
       width: width - 30,
       align: 'center'
     });

  // Category badge with background
  doc.rect(x + 10, y + 45, 60, 20)
     .fillOpacity(0.85)
     .fill('#FFFFFF')
     .fillOpacity(1);
  
  doc.fontSize(10)
     .fillColor('#000000')
     .text(ticket.category, x + 15, y + 50, { width: 50, align: 'center' });

  // Price
  doc.fontSize(10)
     .text(`$${parseFloat(ticket.price).toFixed(2)}`, x + 80, y + 50);

  // Barcode (bottom center)
  if (barcodeBuffer) {
    const barcodeWidth = 70;
    const barcodeHeight = 25;
    const barcodeX = x + (width - barcodeWidth) / 2;
    const barcodeY = y + height - barcodeHeight - 35;

    // White background for barcode
    doc.rect(barcodeX - 5, barcodeY - 5, barcodeWidth + 10, barcodeHeight + 15)
       .fillOpacity(0.9)
       .fill('#FFFFFF')
       .fillOpacity(1);

    doc.image(barcodeBuffer, barcodeX, barcodeY, {
      width: barcodeWidth,
      height: barcodeHeight
    });

    // Barcode number text
    doc.fontSize(6)
       .fillColor('#000000')
       .text(ticket.barcode, barcodeX, barcodeY + barcodeHeight + 2, {
         width: barcodeWidth,
         align: 'center'
       });
  }

  // QR code (top right)
  if (qrBuffer) {
    const qrSize = 45;
    const qrX = x + width - qrSize - 10;
    const qrY = y + 10;

    // White background for QR code
    doc.rect(qrX - 3, qrY - 3, qrSize + 6, qrSize + 6)
       .fillOpacity(0.9)
       .fill('#FFFFFF')
       .fillOpacity(1);

    doc.image(qrBuffer, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }
}

/**
 * Draw ticket in grid layout with borders
 * Compact design for 2" × 2.1" tickets
 * 
 * @param {PDFDocument} doc - PDF document
 * @param {Object} ticket - Ticket data
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {number} width - Ticket width
 * @param {number} height - Ticket height
 * @param {Buffer} qrImage - QR code image buffer
 * @param {Buffer} barcodeImage - Barcode image buffer
 */
async function drawGridTicket(doc, ticket, x, y, width, height, qrImage, barcodeImage) {
  const padding = 4;
  
  // Draw border
  doc.save();
  doc.strokeColor('#000000');
  doc.lineWidth(1);
  doc.rect(x, y, width, height).stroke();
  doc.restore();
  
  // Background
  doc.rect(x, y, width, height).fillOpacity(1).fill('#FFFFFF');
  
  // Ticket number (large, top)
  doc.fontSize(14)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text(ticket.ticket_number, x + padding, y + padding + 2, {
       width: width - (padding * 2),
       align: 'center'
     });
  
  // Category badge (small, colored)
  const categoryColors = {
    'ABC': '#FF6B6B',
    'EFG': '#4ECDC4',
    'JKL': '#45B7D1',
    'XYZ': '#F7DC6F'
  };
  
  const badgeY = y + padding + 20;
  const badgeWidth = 35;
  const badgeHeight = 15;
  const badgeX = x + padding;
  
  doc.rect(badgeX, badgeY, badgeWidth, badgeHeight)
     .fillAndStroke(categoryColors[ticket.category] || '#95a5a6', '#000000');
  
  doc.fontSize(9)
     .fillColor('#FFFFFF')
     .font('Helvetica-Bold')
     .text(ticket.category, badgeX, badgeY + 3, {
       width: badgeWidth,
       align: 'center'
     });
  
  // Price (next to badge)
  doc.fontSize(10)
     .fillColor('#000000')
     .font('Helvetica-Bold')
     .text(`$${parseFloat(ticket.price).toFixed(0)}`, badgeX + badgeWidth + 5, badgeY + 2);
  
  // QR Code (top right, small)
  if (qrImage) {
    const qrSize = 35;
    doc.image(qrImage, x + width - qrSize - padding, y + padding, {
      width: qrSize,
      height: qrSize
    });
  }
  
  // ===== TEAR-OFF PERFORATION LINE =====
  const perforationY = y + height * 0.60; // 60% down
  
  doc.save();
  doc.strokeColor('#999999')
     .lineWidth(0.5)
     .dash(3, 2);
  
  doc.moveTo(x + 5, perforationY)
     .lineTo(x + width - 5, perforationY)
     .stroke();
  
  doc.restore();
  
  // Scissors icon
  doc.fontSize(8)
     .fillColor('#999999')
     .text('✂', x + 2, perforationY - 4);
  
  // ===== MAIN TICKET SECTION (Above perforation) =====
  
  // Barcode #1 (center, above perforation)
  if (barcodeImage) {
    const barcodeWidth = 70;
    const barcodeHeight = 20;
    const barcodeX = x + (width - barcodeWidth) / 2;
    const barcodeY = perforationY - barcodeHeight - 5;
    
    doc.image(barcodeImage, barcodeX, barcodeY, {
      width: barcodeWidth,
      height: barcodeHeight
    });
    
    // Barcode number
    if (ticket.barcode) {
      doc.fontSize(5)
         .font('Helvetica')
         .fillColor('#000000')
         .text(ticket.barcode, x + padding, barcodeY + barcodeHeight + 1, {
           width: width - (padding * 2),
           align: 'center'
         });
    }
  }
  
  // ===== SELLER STUB SECTION (Below perforation) =====
  
  const stubY = perforationY + 3;
  
  // "STUB" label
  doc.fontSize(7)
     .font('Helvetica-Bold')
     .fillColor('#666666')
     .text('STUB', x + padding, stubY + 2, {
       width: width - (padding * 2),
       align: 'center'
     });
  
  // Ticket number on stub
  doc.fontSize(8)
     .font('Helvetica')
     .fillColor('#000000')
     .text(`#${ticket.ticket_number}`, x + padding, stubY + 12);
  
  // Barcode #2 (duplicate on stub)
  if (barcodeImage) {
    const barcodeWidthStub = 60;
    const barcodeHeightStub = 18;
    const barcodeXStub = x + (width - barcodeWidthStub) / 2;
    const barcodeYStub = y + height - barcodeHeightStub - padding - 5;
    
    doc.image(barcodeImage, barcodeXStub, barcodeYStub, {
      width: barcodeWidthStub,
      height: barcodeHeightStub
    });
    
    // Barcode number
    if (ticket.barcode) {
      doc.fontSize(5)
         .font('Helvetica')
         .fillColor('#000000')
         .text(ticket.barcode, x + padding, barcodeYStub + barcodeHeightStub + 1, {
           width: width - (padding * 2),
           align: 'center'
         });
    }
  }
  
  // Seller info (very small)
  if (ticket.seller_name) {
    doc.fontSize(6)
       .font('Helvetica')
       .fillColor('#666666')
       .text(`Seller: ${ticket.seller_name.substring(0, 12)}`, x + padding, stubY + 23, {
         width: width - (padding * 2),
         ellipsis: true
       });
  }
}

/**
 * Draw ticket back/stub content with semi-transparent backgrounds
 */
function drawCustomTicketBackContent(doc, ticket, x, y, width, height, qrBuffer) {
  const padding = 4;

  // Semi-transparent background for title
  doc.rect(x + 10, y + 10, width - 20, 25)
     .fillOpacity(0.85)
     .fill('#FFFFFF')
     .fillOpacity(1);

  // Title
  doc.fontSize(10)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text('📋 SELLER STUB', x + 15, y + 17, {
       width: width - 30,
       align: 'center'
     });

  // Ticket info background
  doc.rect(x + 10, y + 40, width - 20, 60)
     .fillOpacity(0.85)
     .fill('#FFFFFF')
     .fillOpacity(1);

  // Ticket information
  doc.fontSize(9)
     .font('Helvetica-Bold')
     .text(`Ticket: ${ticket.ticket_number}`, x + 15, y + 45);
  
  doc.fontSize(8)
     .font('Helvetica')
     .text(`Category: ${ticket.category}`, x + 15, y + 60)
     .text(`Price: $${parseFloat(ticket.price).toFixed(2)}`, x + 15, y + 72);

  // QR code (top right)
  if (qrBuffer) {
    const qrSize = 36;
    const qrX = x + width - qrSize - 10;
    const qrY = y + 10;

    doc.rect(qrX - 3, qrY - 3, qrSize + 6, qrSize + 6)
       .fillOpacity(0.9)
       .fill('#FFFFFF')
       .fillOpacity(1);

    doc.image(qrBuffer, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // Seller info fields background
  doc.rect(x + 10, y + 105, width - 20, 85)
     .fillOpacity(0.85)
     .fill('#FFFFFF')
     .fillOpacity(1);

  // Seller fields
  doc.fontSize(6)
     .font('Helvetica')
     .fillColor('#000000')
     .text('Sold By: ___________', x + 15, y + 110)
     .text('Seller ID: _________', x + 15, y + 125)
     .text('Buyer: _____________', x + 15, y + 140)
     .text('Phone: _____________', x + 15, y + 155)
     .text('Date: ______________', x + 15, y + 170);
}

/**
 * Generate PDF with grid layout (4 columns × 5 rows)
 * 20 tickets per page, each ticket 2" × 2.1"
 * 
 * @param {Array} tickets - Array of ticket objects
 * @param {Object} customDesign - Optional custom design object
 * @returns {Promise<Buffer>} - PDF buffer
 */
async function generateGridPDF(tickets, customDesign = null) {
  const template = TEMPLATES.GRID_20_TICKETS;
  
  const doc = new PDFDocument({
    size: 'LETTER',
    margin: template.topMargin,
    bufferPages: true
  });
  
  const buffers = [];
  doc.on('data', (chunk) => buffers.push(chunk));
  
  const pdfPromise = new Promise((resolve, reject) => {
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);
  });
  
  const ticketsPerPage = template.columns * template.rows; // 20
  let ticketCount = 0;
  
  for (const ticket of tickets) {
    const positionOnPage = ticketCount % ticketsPerPage;
    const row = Math.floor(positionOnPage / template.columns);
    const col = positionOnPage % template.columns;
    
    // Calculate position
    const x = template.leftMargin + (col * template.ticketWidth);
    const y = template.topMargin + (row * template.ticketHeight);
    
    // Generate codes if not already generated
    if (!ticket.barcode || !ticket.qr_code_data) {
      const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
      ticket.barcode = codes.barcode;
      ticket.qr_code_data = codes.qrCodeData;
    }
    
    // Generate QR code image
    const qrImage = await qrcodeService.generateQRCodeBuffer(ticket, {
      size: 48, // 0.5" at 96 DPI for small format
      errorCorrectionLevel: 'M'
    });
    
    // Generate EAN-13 barcode image
    let barcodeImage = null;
    if (ticket.barcode) {
      try {
        barcodeImage = await bwipjs.toBuffer({
          bcid: 'ean13',
          text: ticket.barcode,
          scale: 1.5,
          height: 6,
          includetext: false,
          textxalign: 'center'
        });
      } catch (error) {
        console.error('Barcode generation error:', error);
      }
    }
    
    // Draw ticket in grid
    await drawGridTicket(
      doc, 
      ticket, 
      x, 
      y, 
      template.ticketWidth, 
      template.ticketHeight,
      qrImage,
      barcodeImage
    );
    
    ticketCount++;
    
    // Add new page if needed
    if (ticketCount % ticketsPerPage === 0 && ticketCount < tickets.length) {
      doc.addPage();
    }
  }
  
  doc.end();
  return pdfPromise;
}

/**
 * Generate 8-up PORTRAIT ticket layout for letter paper (8.5" × 11")
 * Ticket size: 2.1" wide × 5.5" tall (151pt × 396pt at 72 DPI)
 * Layout: 4 columns × 2 rows = 8 tickets per page
 * Includes barcodes, QR codes, and all ticket information
 */
async function generateXYZ8UpPortraitPDF(tickets, customDesign, barcodeSettings) {
  const doc = new PDFDocument({
    size: 'LETTER',  // Portrait: 612pt × 792pt (8.5" × 11")
    margins: { top: 0, bottom: 0, left: 0, right: 0 }
  });

  // PORTRAIT dimensions for 8-up layout
  const TICKET_WIDTH = 2.1 * 72;   // 2.1" = 151.2pt
  const TICKET_HEIGHT = 5.5 * 72;  // 5.5" = 396pt
  const TICKETS_PER_PAGE = 8;
  const COLS = 4;  // 4 columns across
  const ROWS = 2;  // 2 rows down
  const TOP_MARGIN = 0.25 * 72;    // 0.25" = 18pt
  const LEFT_MARGIN = 0.25 * 72;   // 0.25" = 18pt

  const pdfPromise = new Promise((resolve, reject) => {
    const chunks = [];
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });

  let ticketIndex = 0;

  for (const ticket of tickets) {
    // Add new page after every 8 tickets
    if (ticketIndex > 0 && ticketIndex % TICKETS_PER_PAGE === 0) {
      doc.addPage();
    }

    const positionOnPage = ticketIndex % TICKETS_PER_PAGE;
    const col = positionOnPage % COLS;
    const row = Math.floor(positionOnPage / COLS);

    const x = LEFT_MARGIN + (col * TICKET_WIDTH);
    const y = TOP_MARGIN + (row * TICKET_HEIGHT);

    // Generate codes if not already present
    if (!ticket.barcode || !ticket.qr_code_data) {
      const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
      ticket.barcode = codes.barcode;
      ticket.qr_code_data = codes.qrCodeData;
    }

    // Generate QR code
    let qrBuffer = null;
    try {
      qrBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: 67, // 0.93 inches at 72 DPI (67pt / 72 DPI = 0.93")
        errorCorrectionLevel: 'M'
      });
    } catch (error) {
      console.error('Error generating QR code:', error);
    }

    // Generate barcode
    let barcodeBuffer = null;
    if (ticket.barcode) {
      try {
        // Use code128 for reliability (works with any alphanumeric barcode)
        // EAN-13 requires exact 12 digits + valid check digit which may not always be guaranteed
        const BARCODE_BASE_WIDTH = 60; // Base width in modules for scaling
        const BARCODE_HEIGHT_RATIO = 2; // Conversion factor from points to mm for bwip-js
        
        barcodeBuffer = await bwipjs.toBuffer({
          bcid: 'code128', // More flexible than EAN-13, works with any format
          text: ticket.barcode,
          scale: barcodeSettings.width ? (barcodeSettings.width / BARCODE_BASE_WIDTH) : 1.5,
          height: barcodeSettings.height ? Math.floor(barcodeSettings.height / BARCODE_HEIGHT_RATIO) : 10,
          includetext: false,
          textxalign: 'center'
        });
      } catch (error) {
        console.error('Error generating barcode:', error);
      }
    }

    // Draw the ticket
    await drawXYZPortraitTicketFront(doc, ticket, customDesign, x, y, qrBuffer, barcodeBuffer);

    ticketIndex++;
  }

  doc.end();
  return pdfPromise;
}

/**
 * Draw PORTRAIT ticket FRONT with custom image background
 * Includes barcode, QR code, category, price, and form fields
 */
async function drawXYZPortraitTicketFront(doc, ticket, customDesign, x, y, qrBuffer, barcodeBuffer) {
  const TICKET_WIDTH = 2.1 * 72;   // 2.1" = 151.2pt
  const TICKET_HEIGHT = 5.5 * 72;  // 5.5" = 396pt
  const STUB_HEIGHT = 1.5 * 72;    // 1.5" = 108pt (top section)
  const MAIN_HEIGHT = 4.0 * 72;    // 4.0" = 288pt (bottom section)
  
  // Layout constants for better maintainability
  const PADDING = 5;
  const FIELD_SPACING = 18; // Space between form fields
  const FIELD_LINE_OFFSET = 12; // Offset from label to line

  // Draw outer border
  doc.save();
  doc.strokeColor('#000000')
     .lineWidth(1)
     .rect(x, y, TICKET_WIDTH, TICKET_HEIGHT)
     .stroke();
  doc.restore();

  // Draw custom front image as background (if provided)
  if (customDesign && customDesign.front_image_path) {
    const imagePath = path.join(__dirname, '..', 'public', customDesign.front_image_path);
    try {
      if (fs.existsSync(imagePath)) {
        doc.save();
        doc.rect(x, y, TICKET_WIDTH, TICKET_HEIGHT).clip();
        doc.image(imagePath, x, y, {
          width: TICKET_WIDTH,
          height: TICKET_HEIGHT,
          fit: 'cover'
        });
        doc.restore();
      }
    } catch (err) {
      console.error('Error loading front image:', err);
    }
  }

  // Draw horizontal perforation line (between stub and main)
  doc.save();
  doc.strokeColor('#999999')
     .lineWidth(1)
     .dash(5, 5);
  doc.moveTo(x, y + STUB_HEIGHT)
     .lineTo(x + TICKET_WIDTH, y + STUB_HEIGHT)
     .stroke();
  doc.restore();

  // Draw scissors icon at perforation
  doc.fontSize(10).fillColor('#666666').font('Helvetica')
     .text('✂', x + 2, y + STUB_HEIGHT - 6);

  // === STUB SECTION (Top 1.5") - Buyer info fields ===
  doc.fontSize(7).fillColor('#000000').font('Helvetica-Bold');
  
  // Define field positions using constants
  let fieldY = y + 8;
  
  // Name field
  doc.text('Name:', x + PADDING, fieldY, { width: TICKET_WIDTH - 10 });
  doc.strokeColor('#000000').lineWidth(0.5);
  doc.moveTo(x + PADDING, fieldY + FIELD_LINE_OFFSET).lineTo(x + TICKET_WIDTH - PADDING, fieldY + FIELD_LINE_OFFSET).stroke();
  fieldY += FIELD_SPACING;

  // Phone field
  doc.text('Phone:', x + PADDING, fieldY, { width: TICKET_WIDTH - 10 });
  doc.moveTo(x + PADDING, fieldY + FIELD_LINE_OFFSET).lineTo(x + TICKET_WIDTH - PADDING, fieldY + FIELD_LINE_OFFSET).stroke();
  fieldY += FIELD_SPACING;

  // Email field
  doc.text('Email:', x + PADDING, fieldY, { width: TICKET_WIDTH - 10 });
  doc.moveTo(x + PADDING, fieldY + FIELD_LINE_OFFSET).lineTo(x + TICKET_WIDTH - PADDING, fieldY + FIELD_LINE_OFFSET).stroke();
  fieldY += FIELD_SPACING;

  // Date field
  doc.text('Date:', x + PADDING, fieldY, { width: TICKET_WIDTH - 10 });
  doc.moveTo(x + PADDING, fieldY + FIELD_LINE_OFFSET).lineTo(x + TICKET_WIDTH - PADDING, fieldY + FIELD_LINE_OFFSET).stroke();

  // Small ticket number on stub
  doc.fontSize(6).fillColor('#666666').font('Helvetica')
     .text(`#${ticket.ticket_number}`, x + PADDING, y + STUB_HEIGHT - 15, {
       width: TICKET_WIDTH - 10,
       align: 'center'
     });

  // === MAIN SECTION (Bottom 4") - Ticket details ===
  
  const mainY = y + STUB_HEIGHT + 5;
  
  // Semi-transparent background for text readability
  if (customDesign) {
    doc.rect(x + 5, mainY, TICKET_WIDTH - 10, 35)
       .fillOpacity(0.85)
       .fill('#FFFFFF')
       .fillOpacity(1);
  }

  // Title
  doc.fontSize(10).fillColor('#000000').font('Helvetica-Bold')
     .text('🎫 RAFFLE TICKET', x + 5, mainY + 3, {
       width: TICKET_WIDTH - 10,
       align: 'center'
     });

  // Ticket number (large)
  doc.fontSize(12).font('Helvetica-Bold')
     .text(ticket.ticket_number, x + 5, mainY + 18, {
       width: TICKET_WIDTH - 10,
       align: 'center'
     });

  // Category and price
  const categoryY = mainY + 35;
  doc.fontSize(8).font('Helvetica')
     .text(`Category: ${ticket.category}`, x + 5, categoryY, {
       width: TICKET_WIDTH - 10,
       align: 'center'
     });
  
  doc.fontSize(9).font('Helvetica-Bold')
     .text(`Price: $${parseFloat(ticket.price).toFixed(2)}`, x + 5, categoryY + 12, {
       width: TICKET_WIDTH - 10,
       align: 'center'
     });

  // QR Code (right side of main section)
  if (qrBuffer) {
    const qrSize = 50;
    const qrX = x + TICKET_WIDTH - qrSize - 8;
    const qrY = mainY + 45;

    if (customDesign) {
      doc.rect(qrX - 3, qrY - 3, qrSize + 6, qrSize + 6)
         .fillOpacity(0.9)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }

    doc.image(qrBuffer, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // Barcode (bottom center of main section)
  if (barcodeBuffer) {
    const barcodeWidth = 100;
    const barcodeHeight = 35;
    const barcodeX = x + (TICKET_WIDTH - barcodeWidth) / 2;
    const barcodeY = y + TICKET_HEIGHT - barcodeHeight - 25;

    // White background for barcode
    if (customDesign) {
      doc.rect(barcodeX - 5, barcodeY - 5, barcodeWidth + 10, barcodeHeight + 18)
         .fillOpacity(0.95)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }

    doc.image(barcodeBuffer, barcodeX, barcodeY, {
      width: barcodeWidth,
      height: barcodeHeight
    });

    // Barcode number text
    if (ticket.barcode) {
      doc.fontSize(6).fillColor('#000000').font('Helvetica')
         .text(ticket.barcode, x + 5, barcodeY + barcodeHeight + 2, {
           width: TICKET_WIDTH - 10,
           align: 'center'
         });
    }
  }

  // Footer message
  doc.fontSize(6).fillColor('#666666').font('Helvetica')
     .text('Keep this ticket for raffle entry', x + 5, y + TICKET_HEIGHT - 8, {
       width: TICKET_WIDTH - 10,
       align: 'center'
     });
}

module.exports = {
  createPrintJob,
  updatePrintJobStatus,
  generatePrintPDF,
  generateCustomTemplatePDF,
  generateCategoryCustomPDF,
  generateGridPDF,
  generateXYZ8UpPortraitPDF,
  getPrintJobs,
  getPrintJob,
  TEMPLATES
};
