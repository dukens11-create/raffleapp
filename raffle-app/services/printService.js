/**
 * Print Service - Generate PDF tickets for printing
 * Supports Avery 16145 and PrintWorks custom templates
 */

const PDFDocument = require('pdfkit');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');
const ticketService = require('./ticketService');
const bwipjs = require('bwip-js');
const db = require('../db');
const fs = require('fs');
const path = require('path');

// Category display names mapping
const CATEGORY_NAMES = {
  'ABC': { full: 'ABC - Regular', short: 'ABC ($50)' },
  'EFG': { full: 'EFG - Silver', short: 'EFG ($100)' },
  'JKL': { full: 'JKL - Gold', short: 'JKL ($250)' },
  'XYZ': { full: 'XYZ - Platinum', short: 'XYZ ($500)' }
};

// Standard raffle ticket size: 5.5" x 2.125" with tear-off
const DEFAULT_TEMPLATE = {
  ticketWidth: 396,      // 5.5 inches * 72 DPI = 396 points
  ticketHeight: 153,     // 2.125 inches * 72 DPI = 153 points
  mainTicketHeight: 95,  // Main ticket section (top 62%)
  tearOffHeight: 58,     // Tear-off stub section (bottom 38%)
  tearOffY: 95,          // Y position where tear-off starts
  margin: 10,
  padding: 8,
  fontSize: {
    title: 16,
    header: 14,
    body: 11,
    small: 8,
    tiny: 7
  }
};

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
 * @param {Object} customDesign - Optional custom design
 */
async function drawTicketFront(doc, ticket, template, x, y, qrMainImage, barcodeImage, customDesign = null) {
  const { ticketWidth, ticketHeight, perforationLine } = template;
  
  // Check if this is the DEFAULT_TEMPLATE with tear-off
  const hasTearOff = template.mainTicketHeight && template.tearOffHeight && template.tearOffY;
  
  // Detect if this is the smaller LETTER_8_TICKETS format
  const isSmallFormat = ticketWidth < 200; // 2.125" * 72 = 153 points
  
  if (hasTearOff) {
    // New tear-off design with duplicate barcode
    const { mainTicketHeight, tearOffHeight, tearOffY } = template;
    const padding = 8;
    
    // ========================================
    // SECTION 1: MAIN TICKET (TOP SECTION)
    // ========================================
    
    // Draw custom background if provided (main ticket area only)
    if (customDesign && customDesign.front_image_path) {
      try {
        const imagePath = path.join(__dirname, '..', 'public', customDesign.front_image_path);
        if (fs.existsSync(imagePath)) {
          doc.save();
          doc.rect(x, y, ticketWidth, mainTicketHeight).clip();
          doc.image(imagePath, x, y, {
            width: ticketWidth,
            height: mainTicketHeight,
            fit: [ticketWidth, mainTicketHeight],
            align: 'center',
            valign: 'center'
          });
          doc.restore();
        }
      } catch (error) {
        console.error('Error loading front design image:', error);
      }
    } else {
      // Default white background with border (main ticket only)
      doc.rect(x, y, ticketWidth, mainTicketHeight).fillAndStroke('#FFFFFF', '#000000');
    }
    
    // Semi-transparent overlay for text readability (main ticket)
    if (customDesign && customDesign.front_image_path) {
      doc.rect(x + 10, y + 5, ticketWidth - 20, 35)
         .fillOpacity(0.85)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }
    
    // Main ticket header
    doc.fontSize(14).font('Helvetica-Bold').fillColor('#000000');
    doc.text('RAFFLE TICKET', x + padding, y + 8, {
      width: ticketWidth - (padding * 2),
      align: 'center'
    });
    
    // Ticket Number (LARGE, BOLD, CENTERED)
    doc.fontSize(16)
       .font('Helvetica-Bold')
       .fillColor('#000000')
       .text(`Ticket #: ${ticket.ticket_number}`, x + padding, y + 25, {
         width: ticketWidth - (padding * 2),
         align: 'center'
       });
    
    // Category badge and price (on main ticket)
    const categoryColors = {
      'ABC': '#FF6B6B',
      'EFG': '#4ECDC4',
      'JKL': '#45B7D1',
      'XYZ': '#F7DC6F'
    };
    
    const categoryY = y + 48;
    
    if (customDesign && customDesign.front_image_path) {
      doc.rect(x + 10, categoryY - 2, 100, 22)
         .fillOpacity(0.9)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }
    
    doc.rect(x + 12, categoryY, 70, 20)
       .fillAndStroke(categoryColors[ticket.category] || '#95a5a6', '#2c3e50');
    doc.fontSize(12).fillColor('#ffffff').font('Helvetica-Bold');
    doc.text(ticket.category, x + 17, categoryY + 5, { width: 60, align: 'center' });
    
    // Price
    if (customDesign && customDesign.front_image_path) {
      doc.rect(x + 90, categoryY - 2, 80, 22)
         .fillOpacity(0.9)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }
    
    doc.fontSize(11).fillColor('#000000').font('Helvetica');
    doc.text('Price:', x + 95, categoryY + 5);
    doc.font('Helvetica-Bold');
    doc.text(`$${ticket.price.toFixed(2)}`, x + 125, categoryY + 5);
    
    // QR Code on main ticket (top right)
    if (qrMainImage) {
      const qrSize = 50;
      if (customDesign && customDesign.front_image_path) {
        doc.rect(x + ticketWidth - qrSize - 15, y + 5, qrSize + 10, qrSize + 10)
           .fillOpacity(0.95)
           .fill('#FFFFFF')
           .fillOpacity(1);
      }
      doc.image(qrMainImage, x + ticketWidth - qrSize - 10, y + 8, {
        width: qrSize,
        height: qrSize
      });
    }

    // BARCODE #1 - On main ticket (centered at bottom of main section)
    if (barcodeImage) {
      const barcodeWidth = 100;
      const barcodeHeight = 28;
      const barcodeX = x + (ticketWidth - barcodeWidth) / 2;
      const barcodeY = y + mainTicketHeight - barcodeHeight - 8;
      
      if (customDesign && customDesign.front_image_path) {
        doc.rect(barcodeX - 5, barcodeY - 3, barcodeWidth + 10, barcodeHeight + 10)
           .fillOpacity(0.95)
           .fill('#FFFFFF')
           .fillOpacity(1);
      }
      
      doc.image(barcodeImage, barcodeX, barcodeY, {
        width: barcodeWidth,
        height: barcodeHeight
      });
      
      if (ticket.barcode) {
        doc.fontSize(7)
           .font('Helvetica')
           .fillColor('#000000')
           .text(ticket.barcode, x + padding, barcodeY + barcodeHeight + 1, {
             width: ticketWidth - (padding * 2),
             align: 'center'
           });
      }
    }
    
    // ========================================
    // TEAR-OFF PERFORATION LINE
    // ========================================
    
    const perforationY = y + tearOffY;
    
    // Draw scissors icon at the left
    doc.fontSize(12).fillColor('#666666');
    doc.text('✂', x + 5, perforationY - 6);
    
    // Draw dashed perforation line
    doc.strokeColor('#999999')
       .lineWidth(1)
       .dash(5, 3); // 5 points line, 3 points gap
    
    doc.moveTo(x + 20, perforationY)
       .lineTo(x + ticketWidth - 20, perforationY)
       .stroke();
    
    doc.undash(); // Reset to solid line
    
    // "TEAR OFF HERE" text
    doc.fontSize(7)
       .font('Helvetica')
       .fillColor('#999999')
       .text('TEAR OFF HERE', x + ticketWidth - 70, perforationY - 4);
    
    // ========================================
    // SECTION 2: TEAR-OFF STUB (BOTTOM SECTION)
    // ========================================
    
    const stubY = y + tearOffY + 2;
    
    // Draw custom background for stub if provided (using front_image_path for front side)
    if (customDesign && customDesign.front_image_path) {
      try {
        const imagePath = path.join(__dirname, '..', 'public', customDesign.front_image_path);
        if (fs.existsSync(imagePath)) {
          doc.save();
          doc.rect(x, stubY, ticketWidth, tearOffHeight - 2).clip();
          doc.image(imagePath, x, stubY, {
            width: ticketWidth,
            height: tearOffHeight - 2,
            fit: [ticketWidth, tearOffHeight - 2],
            align: 'center',
            valign: 'center'
          });
          doc.restore();
        }
      } catch (error) {
        console.error('Error loading stub design image:', error);
      }
    } else {
      // Default light gray background for stub
      doc.rect(x, stubY, ticketWidth, tearOffHeight - 2)
         .fillAndStroke('#F8F9FA', '#000000');
    }
    
    // Border around entire ticket
    doc.rect(x, y, ticketWidth, ticketHeight).stroke('#000000');
    
    // Stub header with semi-transparent background
    if (customDesign && customDesign.front_image_path) {
      doc.rect(x + 5, stubY + 3, ticketWidth - 10, 30)
         .fillOpacity(0.9)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }
    
    doc.fontSize(10).font('Helvetica-Bold').fillColor('#000000');
    doc.text('SELLER STUB', x + padding, stubY + 5, {
      width: ticketWidth - (padding * 2),
      align: 'center'
    });
    
    // Ticket number on stub
    doc.fontSize(11).font('Helvetica-Bold');
    doc.text(`#${ticket.ticket_number}`, x + padding, stubY + 18, {
      width: ticketWidth - 60,
      align: 'left'
    });
    
    // Small QR code on stub (top right)
    if (qrMainImage) {
      const qrSizeStub = 35;
      if (customDesign && customDesign.front_image_path) {
        doc.rect(x + ticketWidth - qrSizeStub - 12, stubY + 3, qrSizeStub + 7, qrSizeStub + 7)
           .fillOpacity(0.95)
           .fill('#FFFFFF')
           .fillOpacity(1);
      }
      doc.image(qrMainImage, x + ticketWidth - qrSizeStub - 8, stubY + 5, {
        width: qrSizeStub,
        height: qrSizeStub
      });
    }
    
    // BARCODE #2 - On tear-off stub (SAME BARCODE - DUPLICATE)
    if (barcodeImage) {
      const barcodeWidthStub = 90;
      const barcodeHeightStub = 20;
      const barcodeXStub = x + (ticketWidth - barcodeWidthStub) / 2;
      const barcodeYStub = stubY + tearOffHeight - barcodeHeightStub - 10;
      
      if (customDesign && customDesign.front_image_path) {
        doc.rect(barcodeXStub - 5, barcodeYStub - 3, barcodeWidthStub + 10, barcodeHeightStub + 8)
           .fillOpacity(0.95)
           .fill('#FFFFFF')
           .fillOpacity(1);
      }
      
      // Draw SAME barcode on stub
      doc.image(barcodeImage, barcodeXStub, barcodeYStub, {
        width: barcodeWidthStub,
        height: barcodeHeightStub
      });
      
      // Barcode number below
      if (ticket.barcode) {
        doc.fontSize(6)
           .font('Helvetica')
           .fillColor('#000000')
           .text(ticket.barcode, x + padding, barcodeYStub + barcodeHeightStub + 1, {
             width: ticketWidth - (padding * 2),
             align: 'center'
           });
      }
    }
    
    return; // Exit early for tear-off template
  }
  
  // ========================================
  // ORIGINAL DESIGN (for other templates)
  // ========================================
  
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
 * @param {Object} customDesign - Optional custom design
 */
function drawTicketBack(doc, ticket, template, x, y, qrStubImage, customDesign = null) {
  const { ticketWidth, ticketHeight, perforationLine } = template;
  
  // Check if this is the DEFAULT_TEMPLATE with tear-off
  const hasTearOff = template.mainTicketHeight && template.tearOffHeight && template.tearOffY;
  
  // Detect if this is the smaller LETTER_8_TICKETS format
  const isSmallFormat = ticketWidth < 200;
  
  if (hasTearOff) {
    // New tear-off design
    const { mainTicketHeight, tearOffY, tearOffHeight } = template;
    const padding = 8;
    
    // ========================================
    // MAIN TICKET BACK (TOP SECTION)
    // ========================================
    
    // Draw custom background for main back if provided
    if (customDesign && customDesign.back_image_path) {
      try {
        const imagePath = path.join(__dirname, '..', 'public', customDesign.back_image_path);
        if (fs.existsSync(imagePath)) {
          doc.save();
          doc.rect(x, y, ticketWidth, mainTicketHeight).clip();
          doc.image(imagePath, x, y, {
            width: ticketWidth,
            height: mainTicketHeight,
            fit: [ticketWidth, mainTicketHeight],
            align: 'center',
            valign: 'center'
          });
          doc.restore();
        }
      } catch (error) {
        console.error('Error loading back design image:', error);
      }
    } else {
      // Default background
      doc.rect(x, y, ticketWidth, mainTicketHeight).fillAndStroke('#F8F9FA', '#000000');
    }
    
    // Terms and conditions area on main back
    if (customDesign && customDesign.back_image_path) {
      doc.rect(x + 10, y + 10, ticketWidth - 20, mainTicketHeight - 20)
         .fillOpacity(0.9)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }
    
    doc.fontSize(10).font('Helvetica-Bold').fillColor('#000000');
    doc.text('RAFFLE TERMS', x + padding, y + 12, {
      width: ticketWidth - (padding * 2),
      align: 'center'
    });
    
    doc.fontSize(7).font('Helvetica').fillColor('#333333');
    const termsY = y + 25;
    doc.text('• Ticket is non-refundable', x + padding + 5, termsY);
    doc.text('• Winner will be notified by phone', x + padding + 5, termsY + 10);
    doc.text('• Prize must be claimed within 30 days', x + padding + 5, termsY + 20);
    doc.text('• Valid for draw date only', x + padding + 5, termsY + 30);
    
    doc.fontSize(8).font('Helvetica-Bold');
    doc.text('KEEP THIS TICKET SAFE', x + padding, y + mainTicketHeight - 15, {
      width: ticketWidth - (padding * 2),
      align: 'center'
    });
    
    // ========================================
    // TEAR-OFF PERFORATION LINE (BACK SIDE)
    // ========================================
    
    const perforationY = y + tearOffY;
    
    doc.fontSize(12).fillColor('#666666');
    doc.text('✂', x + 5, perforationY - 6);
    
    doc.strokeColor('#999999')
       .lineWidth(1)
       .dash(5, 3);
    
    doc.moveTo(x + 20, perforationY)
       .lineTo(x + ticketWidth - 20, perforationY)
       .stroke();
    
    doc.undash();
    
    doc.fontSize(7)
       .font('Helvetica')
       .fillColor('#999999')
       .text('TEAR OFF HERE', x + ticketWidth - 70, perforationY - 4);
    
    // ========================================
    // TEAR-OFF STUB BACK (BOTTOM SECTION)
    // ========================================
    
    const stubY = y + tearOffY + 2;
    
    if (customDesign && customDesign.back_image_path) {
      try {
        const imagePath = path.join(__dirname, '..', 'public', customDesign.back_image_path);
        if (fs.existsSync(imagePath)) {
          doc.save();
          doc.rect(x, stubY, ticketWidth, tearOffHeight - 2).clip();
          doc.image(imagePath, x, stubY, {
            width: ticketWidth,
            height: tearOffHeight - 2,
            fit: [ticketWidth, tearOffHeight - 2],
            align: 'center',
            valign: 'center'
          });
          doc.restore();
        }
      } catch (error) {
        console.error('Error loading stub back design:', error);
      }
    } else {
      doc.rect(x, stubY, ticketWidth, tearOffHeight - 2)
         .fillAndStroke('#FFFFFF', '#000000');
    }
    
    // Border around entire ticket
    doc.rect(x, y, ticketWidth, ticketHeight).stroke('#000000');
    
    // Seller information on stub back
    if (customDesign && customDesign.back_image_path) {
      doc.rect(x + 5, stubY + 3, ticketWidth - 10, tearOffHeight - 8)
         .fillOpacity(0.9)
         .fill('#FFFFFF')
         .fillOpacity(1);
    }
    
    doc.fontSize(9).font('Helvetica-Bold').fillColor('#000000');
    doc.text('SELLER RECORD', x + padding, stubY + 5, {
      width: ticketWidth - (padding * 2),
      align: 'center'
    });
    
    doc.fontSize(8).font('Helvetica');
    let infoY = stubY + 18;
    
    doc.text(`Ticket: ${ticket.ticket_number}`, x + padding + 5, infoY);
    infoY += 10;
    
    if (ticket.seller_name) {
      doc.text(`Seller: ${ticket.seller_name}`, x + padding + 5, infoY);
      infoY += 10;
    }
    
    if (ticket.seller_phone) {
      doc.text(`Phone: ${ticket.seller_phone}`, x + padding + 5, infoY);
    }
    
    return; // Exit early for tear-off template
  }
  
  // ========================================
  // ORIGINAL DESIGN (for other templates)
  // ========================================
  
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
 * Generate PDF for ticket printing with proper duplex layout
 * Front side (odd pages): Buyer tickets
 * Back side (even pages): Seller stubs
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
  const totalTickets = tickets.length;

  // Process tickets in batches per page
  for (let i = 0; i < tickets.length; i += template.ticketsPerPage) {
    const batch = tickets.slice(i, i + template.ticketsPerPage);
    
    // Add page for FRONT side (buyer tickets) - always add page (even for first batch)
    if (i > 0) doc.addPage();
    
    // Pre-generate all codes for the batch to avoid redundant generation
    const batchWithCodes = await Promise.all(batch.map(async (ticket) => {
      // Generate codes if not already generated
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

      // Draw FRONT side with barcode
      await drawTicketFront(doc, ticket, template, x, y, qrMainBuffer, barcodeBuffer);
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

      // Draw BACK side
      drawTicketBack(doc, ticket, template, x, y, qrStubBuffer);
      
      // Mark ticket as printed after processing both sides
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
 * Generate PDF for ticket printing with DEFAULT_TEMPLATE and tear-off design
 * This function creates tickets with tear-off perforation line and duplicate barcodes
 * 
 * @param {Array} tickets - Array of ticket objects
 * @param {Object} customDesign - Optional custom design object
 * @returns {Promise<Buffer>} - PDF buffer
 */
function generateTicketPDF(tickets, customDesign = null) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      size: 'LETTER',
      margin: 20,
      bufferPages: true
    });
    
    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);
    
    const template = DEFAULT_TEMPLATE;
    const ticketsPerRow = 1; // One ticket per row for 5.5" width
    const ticketsPerPage = 4; // 4 tickets per letter-size page
    
    let ticketCount = 0;
    
    // Process tickets asynchronously
    (async () => {
      try {
        for (const ticket of tickets) {
          const row = Math.floor((ticketCount % ticketsPerPage) / ticketsPerRow);
          const col = ticketCount % ticketsPerRow;
          
          const x = 20 + (col * (template.ticketWidth + 10));
          const y = 30 + (row * (template.ticketHeight + 15));
          
          // Generate codes if not already generated
          if (!ticket.barcode || !ticket.qr_code_data) {
            const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
            ticket.barcode = codes.barcode;
            ticket.qr_code_data = codes.qrCodeData;
          }
          
          // Generate QR codes and barcodes
          const qrMainImage = await qrcodeService.generateQRCodeBuffer(ticket, {
            size: 96,
            errorCorrectionLevel: 'M'
          });
          
          let barcodeImage = null;
          if (ticket.barcode) {
            try {
              barcodeImage = await bwipjs.toBuffer({
                bcid: 'ean13',
                text: ticket.barcode,
                scale: 2,
                height: 10,
                includetext: false,
                textxalign: 'center'
              });
            } catch (error) {
              console.error('Barcode generation error:', error);
            }
          }
          
          // Draw front side with tear-off
          await drawTicketFront(doc, ticket, template, x, y, qrMainImage, barcodeImage, customDesign);
          
          ticketCount++;
          
          if (ticketCount % ticketsPerPage === 0 && ticketCount < tickets.length) {
            doc.addPage();
          }
        }
        
        // Add back sides on separate pages
        if (tickets.length > 0) {
          doc.addPage();
          
          ticketCount = 0;
          for (const ticket of tickets) {
            const row = Math.floor((ticketCount % ticketsPerPage) / ticketsPerRow);
            const col = ticketCount % ticketsPerRow;
            
            const x = 20 + (col * (template.ticketWidth + 10));
            const y = 30 + (row * (template.ticketHeight + 15));
            
            const qrStubImage = await qrcodeService.generateQRCodeBuffer(ticket, {
              size: 50,
              errorCorrectionLevel: 'M'
            });
            
            // Draw back side with tear-off
            drawTicketBack(doc, ticket, template, x, y, qrStubImage, customDesign);
            
            ticketCount++;
            
            if (ticketCount % ticketsPerPage === 0 && ticketCount < tickets.length) {
              doc.addPage();
            }
          }
        }
        
        doc.end();
      } catch (error) {
        reject(error);
      }
    })();
  });
}

module.exports = {
  createPrintJob,
  updatePrintJobStatus,
  generatePrintPDF,
  generateCustomTemplatePDF,
  generateCategoryCustomPDF,
  generateTicketPDF,
  getPrintJobs,
  getPrintJob,
  TEMPLATES,
  DEFAULT_TEMPLATE
};
