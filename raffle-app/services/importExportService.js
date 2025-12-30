/**
 * Import/Export Service
 * Handles bulk import and export of tickets using Excel/CSV
 */

const XLSX = require('xlsx');
const db = require('../db');
const ticketService = require('./ticketService');
const barcodeService = require('./barcodeService');
const qrcodeService = require('./qrcodeService');

/**
 * Export tickets to Excel
 * Includes all ticket data, barcodes, and QR codes
 */
async function exportTicketsToExcel(options = {}) {
  const {
    raffleId = null,
    category = null,
    status = null,
    includeImages = true
  } = options;
  
  try {
    // Build query
    let sql = `
      SELECT 
        t.id,
        t.ticket_number,
        t.category,
        tc.category_name,
        t.price,
        t.barcode,
        t.qr_code_data,
        t.status,
        t.printed,
        t.print_count,
        t.buyer_name,
        t.buyer_phone,
        t.buyer_email,
        t.seller_name,
        t.seller_phone,
        t.payment_method,
        t.actual_price_paid,
        t.seller_commission,
        t.sold_at,
        t.is_winner,
        t.prize_level,
        t.created_at
      FROM tickets t
      LEFT JOIN ticket_categories tc ON t.category_id = tc.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (raffleId) {
      sql += ' AND t.raffle_id = ?';
      params.push(raffleId);
    }
    
    if (category) {
      sql += ' AND t.category = ?';
      params.push(category);
    }
    
    if (status) {
      sql += ' AND t.status = ?';
      params.push(status);
    }
    
    sql += ' ORDER BY t.ticket_number';
    
    const tickets = await db.all(sql, params);
    
    // Convert to Excel-friendly format
    const excelData = tickets.map(ticket => {
      const row = {
        'Ticket Number': ticket.ticket_number,
        'Category': ticket.category,
        'Category Name': ticket.category_name || '',
        'Price': parseFloat(ticket.price || 0).toFixed(2),
        'Barcode': ticket.barcode || '',
        'QR Code URL': ticket.qr_code_data || '',
        'Status': ticket.status,
        'Printed': ticket.printed ? 'Yes' : 'No',
        'Print Count': ticket.print_count || 0,
        'Buyer Name': ticket.buyer_name || '',
        'Buyer Phone': ticket.buyer_phone || '',
        'Buyer Email': ticket.buyer_email || '',
        'Seller Name': ticket.seller_name || '',
        'Seller Phone': ticket.seller_phone || '',
        'Payment Method': ticket.payment_method || '',
        'Actual Price Paid': ticket.actual_price_paid ? parseFloat(ticket.actual_price_paid).toFixed(2) : '',
        'Seller Commission': ticket.seller_commission ? parseFloat(ticket.seller_commission).toFixed(2) : '',
        'Sold At': ticket.sold_at || '',
        'Is Winner': ticket.is_winner ? 'Yes' : 'No',
        'Prize Level': ticket.prize_level || '',
        'Created At': ticket.created_at || ''
      };
      
      return row;
    });
    
    // Create workbook
    const workbook = XLSX.utils.book_new();
    const worksheet = XLSX.utils.json_to_sheet(excelData);
    
    // Set column widths
    const columnWidths = [
      { wch: 15 }, // Ticket Number
      { wch: 10 }, // Category
      { wch: 15 }, // Category Name
      { wch: 8 },  // Price
      { wch: 12 }, // Barcode
      { wch: 50 }, // QR Code URL
      { wch: 10 }, // Status
      { wch: 8 },  // Printed
      { wch: 10 }, // Print Count
      { wch: 20 }, // Buyer Name
      { wch: 15 }, // Buyer Phone
      { wch: 25 }, // Buyer Email
      { wch: 20 }, // Seller Name
      { wch: 15 }, // Seller Phone
      { wch: 15 }, // Payment Method
      { wch: 15 }, // Actual Price Paid
      { wch: 15 }, // Seller Commission
      { wch: 20 }, // Sold At
      { wch: 10 }, // Is Winner
      { wch: 15 }, // Prize Level
      { wch: 20 }  // Created At
    ];
    worksheet['!cols'] = columnWidths;
    
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Tickets');
    
    // Generate buffer
    const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
    
    return {
      success: true,
      buffer,
      ticketCount: tickets.length,
      filename: `raffle_tickets_export_${Date.now()}.xlsx`
    };
    
  } catch (error) {
    console.error('Error exporting tickets:', error);
    throw error;
  }
}

/**
 * Generate template Excel file for import
 */
function generateImportTemplate() {
  const templateData = [
    {
      'Ticket Number': 'ABC-000001',
      'Category': 'ABC',
      'Price': '50.00',
      'Status': 'AVAILABLE'
    },
    {
      'Ticket Number': 'ABC-000002',
      'Category': 'ABC',
      'Price': '50.00',
      'Status': 'AVAILABLE'
    },
    {
      'Ticket Number': 'EFG-000001',
      'Category': 'EFG',
      'Price': '100.00',
      'Status': 'AVAILABLE'
    }
  ];
  
  const workbook = XLSX.utils.book_new();
  const worksheet = XLSX.utils.json_to_sheet(templateData);
  
  // Add instructions sheet
  const instructions = [
    { 'Column': 'Ticket Number', 'Required': 'Yes', 'Format': 'ABC-000001', 'Notes': 'Must be unique' },
    { 'Column': 'Category', 'Required': 'Yes', 'Format': 'ABC/EFG/JKL/XYZ', 'Notes': 'Valid categories only' },
    { 'Column': 'Price', 'Required': 'Yes', 'Format': '50.00', 'Notes': 'Decimal format' },
    { 'Column': 'Status', 'Required': 'No', 'Format': 'AVAILABLE', 'Notes': 'Defaults to AVAILABLE' }
  ];
  
  const instructionsSheet = XLSX.utils.json_to_sheet(instructions);
  
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Template');
  XLSX.utils.book_append_sheet(workbook, instructionsSheet, 'Instructions');
  
  const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
  
  return {
    success: true,
    buffer,
    filename: 'ticket_import_template.xlsx'
  };
}

/**
 * Import tickets from Excel file
 * Processes in batches to prevent timeout
 */
async function importTicketsFromExcel(fileBuffer, options = {}) {
  const {
    raffleId = 1,
    batchSize = 1000,
    generateCodes = false
  } = options;
  
  try {
    // Parse Excel file
    const workbook = XLSX.read(fileBuffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    const data = XLSX.utils.sheet_to_json(worksheet);
    
    if (!data || data.length === 0) {
      throw new Error('No data found in Excel file');
    }
    
    console.log(`Starting import of ${data.length} tickets...`);
    
    const results = {
      total: data.length,
      imported: 0,
      skipped: 0,
      errors: [],
      batchesProcessed: 0
    };
    
    // Get category mapping
    const categories = await db.all(
      'SELECT id, category_code, price FROM ticket_categories WHERE raffle_id = ?',
      [raffleId]
    );
    
    const categoryMap = {};
    categories.forEach(cat => {
      categoryMap[cat.category_code] = cat;
    });
    
    // Process in batches
    for (let i = 0; i < data.length; i += batchSize) {
      const batch = data.slice(i, i + batchSize);
      
      for (const row of batch) {
        try {
          const ticketNumber = row['Ticket Number'] || row.ticket_number;
          const category = row['Category'] || row.category;
          const price = parseFloat(row['Price'] || row.price || 0);
          const status = row['Status'] || row.status || 'AVAILABLE';
          
          // Validate
          if (!ticketNumber || !category) {
            results.errors.push({ row: i + 1, error: 'Missing ticket number or category' });
            results.skipped++;
            continue;
          }
          
          // Check if ticket already exists
          const existing = await db.get(
            'SELECT id FROM tickets WHERE ticket_number = ?',
            [ticketNumber]
          );
          
          if (existing) {
            results.skipped++;
            continue;
          }
          
          // Get category info
          const categoryInfo = categoryMap[category];
          if (!categoryInfo) {
            results.errors.push({ row: i + 1, error: `Unknown category: ${category}` });
            results.skipped++;
            continue;
          }
          
          // Insert ticket
          const result = await db.run(
            `INSERT INTO tickets (
              raffle_id, category_id, category, ticket_number, price, status
            ) VALUES (?, ?, ?, ?, ?, ?)`,
            [
              raffleId,
              categoryInfo.id,
              category,
              ticketNumber,
              price || categoryInfo.price,
              status
            ]
          );
          
          results.imported++;
          
          // Generate codes if requested
          if (generateCodes && result.lastID) {
            await ticketService.generateCodesForTicket(result.lastID, ticketNumber);
          }
          
        } catch (error) {
          results.errors.push({ row: i + 1, error: error.message });
          results.skipped++;
        }
      }
      
      results.batchesProcessed++;
      console.log(`Processed batch ${results.batchesProcessed}, imported ${results.imported} tickets`);
    }
    
    console.log(`Import completed: ${results.imported} imported, ${results.skipped} skipped`);
    
    return {
      success: true,
      ...results
    };
    
  } catch (error) {
    console.error('Error importing tickets:', error);
    throw error;
  }
}

/**
 * Export tickets to CSV
 */
async function exportTicketsToCSV(options = {}) {
  const excelResult = await exportTicketsToExcel(options);
  
  // Convert to CSV
  const workbook = XLSX.read(excelResult.buffer, { type: 'buffer' });
  const worksheet = workbook.Sheets[workbook.SheetNames[0]];
  const csv = XLSX.utils.sheet_to_csv(worksheet);
  
  return {
    success: true,
    buffer: Buffer.from(csv, 'utf8'),
    ticketCount: excelResult.ticketCount,
    filename: `raffle_tickets_export_${Date.now()}.csv`
  };
}

module.exports = {
  exportTicketsToExcel,
  exportTicketsToCSV,
  generateImportTemplate,
  importTicketsFromExcel
};
