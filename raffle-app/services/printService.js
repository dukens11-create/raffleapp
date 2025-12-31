/**
 * Print Service - Generate PDF tickets for printing
 * Supports Avery 16145 and PrintWorks custom templates
 */

const PDFDocument = require('pdfkit');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');
const db = require('../db');
const fs = require('fs');

// Category display names mapping
const CATEGORY_NAMES = {
  'ABC': { full: 'ABC - Regular', short: 'ABC ($50)' },
  'EFG': { full: 'EFG - Silver', short: 'EFG ($100)' },
  'JKL': { full: 'JKL - Gold', short: 'JKL ($250)' },
  'XYZ': { full: 'XYZ - Platinum', short: 'XYZ ($500)' }
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
  const { ticketWidth, ticketHeight } = template;
  const padding = 8;
  
  // Draw border
  doc.rect(x, y, ticketWidth, ticketHeight).stroke();

  // Title with emoji
  doc.fontSize(12)
     .font('Helvetica-Bold')
     .text('🎫 RAFFLE TICKET', x + padding, y + padding, {
       width: ticketWidth - (padding * 2),
       align: 'center'
     });

  // Ticket number (LARGE, BOLD, CENTERED - MORE PROMINENT)
  doc.fontSize(18)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text(`Ticket #: ${ticket.ticket_number}`, x + padding, y + padding + 22, {
       width: ticketWidth - 120 - (padding * 2),
       align: 'center'
     });

  doc.fontSize(9)
     .font('Helvetica')
     .fillColor('#000000')
     .text(`Category: ${CATEGORY_NAMES[ticket.category]?.full || ticket.category}`, x + padding, y + padding + 45, {
       width: ticketWidth - 120 - (padding * 2)
     });
  
  doc.fontSize(10)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text(`Price: $${parseFloat(ticket.price).toFixed(2)}`, x + padding, y + padding + 59, {
       width: ticketWidth - 120 - (padding * 2)
     });

  // QR Code (right side)
  if (qrMainImage) {
    const qrSize = 80;
    const qrX = x + ticketWidth - qrSize - padding;
    const qrY = y + padding + 10;
    doc.image(qrMainImage, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // EAN-13 Barcode (center-bottom area)
  if (barcodeImage) {
    const barcodeWidth = 120;
    const barcodeHeight = 40;
    const barcodeX = x + (ticketWidth - barcodeWidth) / 2;
    const barcodeY = y + padding + 75;
    doc.image(barcodeImage, barcodeX, barcodeY, {
      width: barcodeWidth,
      height: barcodeHeight
    });
    
    // Display barcode number below the barcode
    if (ticket.barcode) {
      doc.fontSize(7)
         .font('Helvetica')
         .fillColor('#000000')
         .text(ticket.barcode, x + padding, barcodeY + barcodeHeight + 2, {
           width: ticketWidth - (padding * 2),
           align: 'center'
         });
    }
  }

  // Buyer information fields
  const fieldsY = y + ticketHeight - 35;
  doc.fontSize(8)
     .font('Helvetica')
     .text('Date: ___________________', x + padding, fieldsY)
     .text('Name: ___________________', x + padding + 140, fieldsY);
  
  doc.text('Phone: __________________', x + padding, fieldsY + 12)
     .text('Draw Date: [INSERT DATE]', x + padding + 140, fieldsY + 12);

  // Footer
  doc.fontSize(7)
     .font('Helvetica')
     .text('Keep this ticket for entry', x + padding, y + ticketHeight - 15, {
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
  const { ticketWidth, ticketHeight } = template;
  const padding = 8;
  
  // Draw border
  doc.rect(x, y, ticketWidth, ticketHeight).stroke();

  // Title with emoji
  doc.fontSize(12)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text('📋 SELLER STUB', x + padding, y + padding, {
       width: ticketWidth - 70 - (padding * 2),
       align: 'left'
     });

  // Small QR code (top right)
  if (qrStubImage) {
    const qrSize = 50;
    const qrX = x + ticketWidth - qrSize - padding;
    const qrY = y + padding;
    doc.image(qrStubImage, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });
  }

  // Ticket number (LARGE, BOLD - MORE PROMINENT)
  doc.fontSize(16)
     .font('Helvetica-Bold')
     .fillColor('#000000')
     .text(`Ticket #: ${ticket.ticket_number}`, x + padding, y + padding + 20, {
       width: ticketWidth - 70 - (padding * 2),
       align: 'left'
     });

  doc.fontSize(9)
     .font('Helvetica')
     .fillColor('#000000')
     .text(`Category: ${CATEGORY_NAMES[ticket.category]?.short || ticket.category}`, x + padding, y + padding + 38);

  // Seller information fields
  const fieldsY = y + padding + 58;
  doc.fontSize(8)
     .font('Helvetica')
     .fillColor('#000000')
     .text('Sold By: __________________', x + padding, fieldsY)
     .text('Seller ID: _____________', x + padding + 140, fieldsY);
  
  doc.text('Buyer Name: _______________', x + padding, fieldsY + 12)
     .text('Buyer Phone: ______________', x + padding + 140, fieldsY + 12);
  
  doc.text('Date Sold: ________________', x + padding, fieldsY + 24)
     .text('Payment: [Cash/Check/Card]', x + padding + 140, fieldsY + 24);

  // Footer
  doc.fontSize(7)
     .font('Helvetica-Bold')
     .text('Office Use Only - Keep Record', x + padding, y + ticketHeight - 15, {
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
      const ticketService = require('./ticketService');
      const barcodeGenerator = require('./barcodeGenerator');
      if (!ticket.barcode || !ticket.qr_code_data) {
        const codes = await ticketService.generateAndSaveCodes(ticket.ticket_number);
        ticket.barcode = codes.barcode;
        ticket.qr_code_data = codes.qrCodeData;
      }

      // Generate QR code images with full ticket data
      const qrMainBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: 96, // 1 inch at 96 DPI
        errorCorrectionLevel: 'M'
      });
      
      const qrStubBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: 50, // Smaller for stub
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
            scale: 2,
            height: 10,
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

  // Load custom template images
  const frontImageBuffer = fs.readFileSync(customTemplate.front_image_path);
  const backImageBuffer = fs.readFileSync(customTemplate.back_image_path);

  // Process tickets in batches per page
  for (let i = 0; i < tickets.length; i += template.ticketsPerPage) {
    const batch = tickets.slice(i, i + template.ticketsPerPage);
    
    // Add page for FRONT side (buyer tickets)
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

      // Generate QR code images with full ticket data
      const qrMainBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: 96, // 1 inch at 96 DPI
        errorCorrectionLevel: 'M'
      });
      
      const qrStubBuffer = await qrcodeService.generateQRCodeBuffer(ticket, {
        size: 50, // Smaller for stub
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
            scale: 2,
            height: 10,
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

      // Draw custom template image
      doc.image(frontImageBuffer, x, y, {
        width: template.ticketWidth,
        height: template.ticketHeight
      });

      // === OVERLAY TICKET NUMBER (PROMINENT, WITH BACKGROUND FOR READABILITY) ===
      // Add semi-transparent white background box for ticket number
      const padding = 8;
      doc.rect(x + 10, y + 30, template.ticketWidth - 20, 25)
         .fillOpacity(0.85)
         .fill('#FFFFFF')
         .fillOpacity(1);
      
      // Ticket number text
      doc.fontSize(16)
         .font('Helvetica-Bold')
         .fillColor('#000000')
         .text(`Ticket #: ${ticket.ticket_number}`, x + 15, y + 37, {
           width: template.ticketWidth - 30,
           align: 'center'
         });
      
      // Add barcode (bottom center)
      if (barcodeBuffer) {
        const barcodeWidth = 120;
        const barcodeHeight = 40;
        const barcodeX = x + (template.ticketWidth - barcodeWidth) / 2;
        const barcodeY = y + template.ticketHeight - barcodeHeight - 25;
        
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
      
      // Add QR code (top right corner)
      if (qrMainBuffer) {
        const qrSize = 60;
        const qrX = x + template.ticketWidth - qrSize - 10;
        const qrY = y + 10;
        
        doc.image(qrMainBuffer, qrX, qrY, {
          width: qrSize,
          height: qrSize
        });
      }

      // Draw tear-off line
      drawTearOffLine(doc, x, y, template.ticketWidth, template.ticketHeight);
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

      // Draw custom template image
      doc.image(backImageBuffer, x, y, {
        width: template.ticketWidth,
        height: template.ticketHeight
      });

      // === OVERLAY TICKET NUMBER ON BACK SIDE ===
      // Add background box
      const padding = 8;
      doc.rect(x + 10, y + 25, template.ticketWidth - 70, 22)
         .fillOpacity(0.85)
         .fill('#FFFFFF')
         .fillOpacity(1);
      
      // Ticket number
      doc.fontSize(14)
         .font('Helvetica-Bold')
         .fillColor('#000000')
         .text(`Ticket #: ${ticket.ticket_number}`, x + 15, y + 30, {
           width: template.ticketWidth - 80,
           align: 'left'
         });
      
      // Small QR code (top right)
      if (qrStubBuffer) {
        const qrSize = 50;
        const qrX = x + template.ticketWidth - qrSize - 10;
        const qrY = y + 10;
        
        doc.image(qrStubBuffer, qrX, qrY, {
          width: qrSize,
          height: qrSize
        });
      }

      // Draw tear-off line
      drawTearOffLine(doc, x, y, template.ticketWidth, template.ticketHeight);
      
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

module.exports = {
  createPrintJob,
  updatePrintJobStatus,
  generatePrintPDF,
  generateCustomTemplatePDF,
  getPrintJobs,
  getPrintJob,
  TEMPLATES
};
