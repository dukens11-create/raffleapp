/**
 * PDF Printing Service
 * Generates printable PDFs for raffle tickets with barcodes and QR codes
 * Supports Avery 16145 and PrintWorks paper types
 */

const PDFDocument = require('pdfkit');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');
const db = require('../db');

// Paper specifications at 72 DPI (PDF standard)
const PAPER_SPECS = {
  avery_16145: {
    name: 'Avery 16145',
    pageWidth: 612,  // 8.5"
    pageHeight: 792, // 11"
    ticketsPerPage: 10,
    ticketWidth: 396,   // 5.5"
    ticketHeight: 126,  // 1.75"
    topMargin: 36,      // 0.5"
    leftMargin: 13.5,   // 0.1875"
    spacing: 0,
    layout: 'single-column',
    perforated: true,
    mainTicketHeight: 90,    // 1.25"
    stubHeight: 36           // 0.5"
  },
  printworks: {
    name: 'PrintWorks Custom',
    pageWidth: 612,  // 8.5"
    pageHeight: 792, // 11"
    ticketsPerPage: 8,
    ticketWidth: 396,   // 5.5"
    ticketHeight: 153,  // 2.125"
    topMargin: 36,
    leftMargin: 108,    // Centered
    spacing: 0,
    layout: 'single-column',
    perforated: false,
    mainTicketHeight: 120.6,  // 1.675"
    stubHeight: 32.4          // 0.45"
  }
};

/**
 * Create a print job record in database
 */
async function createPrintJob(adminId, raffleId, options) {
  const {
    category,
    ticketRangeStart,
    ticketRangeEnd,
    totalTickets,
    paperType,
    printType = 'initial'
  } = options;
  
  const spec = PAPER_SPECS[paperType] || PAPER_SPECS.avery_16145;
  const totalPages = Math.ceil(totalTickets / spec.ticketsPerPage);
  
  const result = await db.run(
    `INSERT INTO print_jobs (
      admin_id, raffle_id, category, ticket_range_start, ticket_range_end,
      total_tickets, total_pages, paper_type, status, print_type
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      adminId, raffleId, category, ticketRangeStart, ticketRangeEnd,
      totalTickets, totalPages, paperType, 'scheduled', printType
    ]
  );
  
  return result.lastID || result;
}

/**
 * Update print job status
 */
async function updatePrintJobStatus(jobId, status, progressPercent = null, errorMessage = null) {
  let sql = 'UPDATE print_jobs SET status = ?';
  const params = [status];
  
  if (progressPercent !== null) {
    sql += ', progress_percent = ?';
    params.push(progressPercent);
  }
  
  if (errorMessage) {
    sql += ', error_message = ?';
    params.push(errorMessage);
  }
  
  if (status === 'completed' || status === 'failed') {
    const timestamp = db.USE_POSTGRES ? 'CURRENT_TIMESTAMP' : "datetime('now')";
    sql += `, completed_at = ${timestamp}`;
  }
  
  sql += ' WHERE id = ?';
  params.push(jobId);
  
  await db.run(sql, params);
}

/**
 * Draw a ticket on the PDF
 */
async function drawTicket(doc, ticket, x, y, spec, isStub = false) {
  const width = spec.ticketWidth;
  const height = isStub ? spec.stubHeight : spec.mainTicketHeight;
  
  // Draw border
  doc.rect(x, y, width, height).stroke();
  
  if (isStub) {
    // Stub section (organizer keeps)
    doc.fontSize(10).text('ORGANIZER COPY', x + 10, y + 5, { width: width - 20 });
    doc.fontSize(12).font('Helvetica-Bold')
       .text(ticket.ticket_number, x + 10, y + 20, { width: width - 100 });
    doc.fontSize(9).font('Helvetica')
       .text(ticket.category_name || ticket.category, x + 10, y + 35);
    
    // Small QR code on stub
    try {
      const qrBuffer = await qrcodeService.generateTicketQRCode(ticket.ticket_number, 'stub');
      doc.image(qrBuffer, x + width - 50, y + 5, { width: 40, height: 40 });
    } catch (error) {
      console.error('Error adding QR to stub:', error);
    }
    
    // Buyer name field
    doc.fontSize(8).text('Buyer: ___________________', x + 10, y + height - 15);
    
  } else {
    // Main ticket section (customer keeps)
    doc.fontSize(16).font('Helvetica-Bold')
       .text('RAFFLE TICKET', x + width / 2, y + 10, { width: width - 20, align: 'center' });
    
    doc.fontSize(14).font('Helvetica-Bold')
       .text(ticket.ticket_number, x + 10, y + 30, { width: width - 20 });
    
    doc.fontSize(11).font('Helvetica')
       .text(`Category: ${ticket.category_name || ticket.category}`, x + 10, y + 50)
       .text(`Price: $${parseFloat(ticket.price).toFixed(2)}`, x + 10, y + 65);
    
    // Barcode
    try {
      const barcodeBuffer = await barcodeService.generateBarcodeImage(ticket.barcode, {
        scale: 2,
        height: 8
      });
      doc.image(barcodeBuffer, x + 10, y + height - 35, { width: 180, height: 30 });
    } catch (error) {
      console.error('Error adding barcode:', error);
      doc.fontSize(9).text(`Barcode: ${ticket.barcode}`, x + 10, y + height - 30);
    }
    
    // QR Code
    try {
      const qrBuffer = await qrcodeService.generateTicketQRCode(ticket.ticket_number, 'main');
      doc.image(qrBuffer, x + width - 70, y + 30, { width: 60, height: 60 });
    } catch (error) {
      console.error('Error adding QR to ticket:', error);
    }
  }
}

/**
 * Generate PDF for ticket range
 */
async function generateTicketPDF(tickets, paperType = 'avery_16145') {
  return new Promise(async (resolve, reject) => {
    try {
      const spec = PAPER_SPECS[paperType] || PAPER_SPECS.avery_16145;
      
      // Create PDF document
      const doc = new PDFDocument({
        size: [spec.pageWidth, spec.pageHeight],
        margin: 0
      });
      
      // Collect PDF data in buffer
      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);
      
      let ticketIndex = 0;
      
      for (const ticket of tickets) {
        const positionOnPage = ticketIndex % spec.ticketsPerPage;
        
        // Start new page if needed
        if (ticketIndex > 0 && positionOnPage === 0) {
          doc.addPage();
        }
        
        const x = spec.leftMargin;
        const y = spec.topMargin + (positionOnPage * spec.ticketHeight);
        
        // Draw main ticket
        await drawTicket(doc, ticket, x, y, spec, false);
        
        // Draw perforation line or cutting guide
        const perfY = y + spec.mainTicketHeight;
        if (spec.perforated) {
          // Dashed line for perforation
          doc.moveTo(x, perfY)
             .lineTo(x + spec.ticketWidth, perfY)
             .dash(5, { space: 3 })
             .stroke();
          doc.undash();
          
          // Scissors icon
          doc.fontSize(10).text('✂', x - 15, perfY - 5);
        } else {
          // Solid cutting guide
          doc.moveTo(x - 5, perfY)
             .lineTo(x + spec.ticketWidth + 5, perfY)
             .stroke();
          doc.fontSize(8).text('CUT HERE', x + spec.ticketWidth + 10, perfY - 4);
        }
        
        // Draw stub
        await drawTicket(doc, ticket, x, perfY, spec, true);
        
        ticketIndex++;
      }
      
      // Finalize PDF
      doc.end();
      
    } catch (error) {
      reject(error);
    }
  });
}

/**
 * Generate and print tickets
 * Main entry point for printing workflow
 */
async function printTickets(adminId, raffleId, options) {
  const {
    startTicket,
    endTicket,
    paperType = 'avery_16145',
    printType = 'initial'
  } = options;
  
  try {
    // Get tickets in range
    const ticketService = require('./ticketService');
    const tickets = await ticketService.getTicketsByRange(startTicket, endTicket);
    
    if (!tickets || tickets.length === 0) {
      throw new Error('No tickets found in the specified range');
    }
    
    // Create print job
    const category = startTicket.split('-')[0];
    const jobId = await createPrintJob(adminId, raffleId, {
      category,
      ticketRangeStart: startTicket,
      ticketRangeEnd: endTicket,
      totalTickets: tickets.length,
      paperType,
      printType
    });
    
    // Update status to generating
    await updatePrintJobStatus(jobId, 'generating', 10);
    
    // Generate barcodes and QR codes if not already generated
    let generatedCount = 0;
    for (const ticket of tickets) {
      if (!ticket.barcode || !ticket.qr_code_data) {
        await ticketService.generateCodesForTicket(ticket.id, ticket.ticket_number);
        generatedCount++;
      }
      
      // Update progress
      const progress = 10 + Math.floor((generatedCount / tickets.length) * 30);
      if (generatedCount % 100 === 0) {
        await updatePrintJobStatus(jobId, 'generating', progress);
      }
    }
    
    // Refresh tickets with barcodes
    const ticketsWithCodes = await ticketService.getTicketsByRange(startTicket, endTicket);
    
    // Update progress
    await updatePrintJobStatus(jobId, 'generating', 50);
    
    // Generate PDF
    const pdfBuffer = await generateTicketPDF(ticketsWithCodes, paperType);
    
    // Update progress
    await updatePrintJobStatus(jobId, 'printing', 75);
    
    // Mark tickets as printed
    const ticketIds = ticketsWithCodes.map(t => t.id);
    await ticketService.markTicketsAsPrinted(ticketIds);
    
    // Complete job
    await updatePrintJobStatus(jobId, 'completed', 100);
    
    return {
      success: true,
      jobId,
      pdfBuffer,
      ticketCount: tickets.length,
      pagesGenerated: Math.ceil(tickets.length / PAPER_SPECS[paperType].ticketsPerPage)
    };
    
  } catch (error) {
    console.error('Error in printTickets:', error);
    throw error;
  }
}

/**
 * Get print job details
 */
async function getPrintJob(jobId) {
  return await db.get(
    `SELECT pj.*, u.name as admin_name
     FROM print_jobs pj
     LEFT JOIN users u ON pj.admin_id = u.id
     WHERE pj.id = ?`,
    [jobId]
  );
}

/**
 * Get print jobs for admin
 */
async function getPrintJobs(adminId, limit = 50) {
  return await db.all(
    `SELECT pj.*, u.name as admin_name
     FROM print_jobs pj
     LEFT JOIN users u ON pj.admin_id = u.id
     WHERE pj.admin_id = ?
     ORDER BY pj.started_at DESC
     LIMIT ?`,
    [adminId, limit]
  );
}

module.exports = {
  PAPER_SPECS,
  createPrintJob,
  updatePrintJobStatus,
  generateTicketPDF,
  printTickets,
  getPrintJob,
  getPrintJobs
};
