/**
 * Import/Export Service - Handle ticket data import/export
 * Supports Excel and CSV formats
 */

const ExcelJS = require('exceljs');
const db = require('../db');
const ticketService = require('./ticketService');

// Maximum number of tickets that can be exported in a single request
const MAX_EXPORT_LIMIT = 50000;
// Default export limit if not specified
const DEFAULT_EXPORT_LIMIT = 10000;
// Batch size for processing tickets to prevent memory issues
const BATCH_SIZE = 5000;

/**
 * Generate Excel template for ticket import
 * 
 * @returns {Promise<Buffer>} - Excel file buffer
 */
async function generateTemplate() {
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Tickets');

  // Define columns
  worksheet.columns = [
    { header: 'Ticket Number', key: 'ticketNumber', width: 15 },
    { header: 'Category', key: 'category', width: 12 },
    { header: 'Price', key: 'price', width: 10 },
    { header: 'Buyer Name', key: 'buyerName', width: 20 },
    { header: 'Buyer Phone', key: 'buyerPhone', width: 15 },
    { header: 'Seller Name', key: 'sellerName', width: 20 },
    { header: 'Seller Phone', key: 'sellerPhone', width: 15 },
    { header: 'Status', key: 'status', width: 12 }
  ];

  // Add sample data
  worksheet.addRows([
    {
      ticketNumber: 'ABC-000001',
      category: 'ABC',
      price: 50.00,
      buyerName: '',
      buyerPhone: '',
      sellerName: '',
      sellerPhone: '',
      status: 'AVAILABLE'
    },
    {
      ticketNumber: 'EFG-000001',
      category: 'EFG',
      price: 100.00,
      buyerName: '',
      buyerPhone: '',
      sellerName: '',
      sellerPhone: '',
      status: 'AVAILABLE'
    },
    {
      ticketNumber: 'JKL-000001',
      category: 'JKL',
      price: 250.00,
      buyerName: '',
      buyerPhone: '',
      sellerName: '',
      sellerPhone: '',
      status: 'AVAILABLE'
    },
    {
      ticketNumber: 'XYZ-000001',
      category: 'XYZ',
      price: 500.00,
      buyerName: '',
      buyerPhone: '',
      sellerName: '',
      sellerPhone: '',
      status: 'AVAILABLE'
    }
  ]);

  // Style header row
  worksheet.getRow(1).font = { bold: true };
  worksheet.getRow(1).fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFD3D3D3' }
  };

  const buffer = await workbook.xlsx.writeBuffer();
  return buffer;
}

/**
 * Parse Excel/CSV file
 * 
 * @param {Buffer} fileBuffer - File buffer
 * @param {string} fileType - File type (xlsx, xls, csv)
 * @returns {Promise<Array<Object>>} - Parsed ticket data
 */
async function parseImportFile(fileBuffer, fileType) {
  try {
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(fileBuffer);
    
    const worksheet = workbook.worksheets[0];
    const data = [];
    
    // Get header row
    const headerRow = worksheet.getRow(1);
    const headers = [];
    headerRow.eachCell((cell, colNumber) => {
      headers[colNumber] = cell.value;
    });
    
    // Parse data rows
    worksheet.eachRow((row, rowNumber) => {
      if (rowNumber === 1) return; // Skip header
      
      const rowData = {};
      row.eachCell((cell, colNumber) => {
        const header = headers[colNumber];
        if (header) {
          rowData[header] = cell.value;
        }
      });
      
      data.push(rowData);
    });

    return data;
  } catch (error) {
    console.error('Error parsing import file:', error);
    throw new Error(`Failed to parse file: ${error.message}`);
  }
}

/**
 * Validate imported ticket data
 * 
 * @param {Array<Object>} tickets - Parsed ticket data
 * @returns {Object} - { valid: Array, invalid: Array, errors: Array }
 */
function validateImportData(tickets) {
  const valid = [];
  const invalid = [];
  const errors = [];

  const validCategories = ['ABC', 'EFG', 'JKL', 'XYZ'];
  const validStatuses = ['AVAILABLE', 'SOLD', 'RESERVED'];

  tickets.forEach((ticket, index) => {
    const rowErrors = [];
    const row = index + 2; // Excel row (1-indexed + header)

    // Validate ticket number
    if (!ticket['Ticket Number']) {
      rowErrors.push(`Row ${row}: Missing ticket number`);
    } else {
      const ticketNumMatch = ticket['Ticket Number'].match(/^([A-Z]{3})-(\d{6})$/);
      if (!ticketNumMatch) {
        rowErrors.push(`Row ${row}: Invalid ticket number format. Expected ABC-000001`);
      }
    }

    // Validate category
    if (!ticket['Category']) {
      rowErrors.push(`Row ${row}: Missing category`);
    } else if (!validCategories.includes(ticket['Category'].toUpperCase())) {
      rowErrors.push(`Row ${row}: Invalid category. Must be ABC, EFG, JKL, or XYZ`);
    }

    // Validate price
    if (ticket['Price'] === undefined || ticket['Price'] === null) {
      rowErrors.push(`Row ${row}: Missing price`);
    } else {
      const price = parseFloat(ticket['Price']);
      if (isNaN(price) || price < 0) {
        rowErrors.push(`Row ${row}: Invalid price`);
      }
    }

    // Validate status (optional)
    if (ticket['Status'] && !validStatuses.includes(ticket['Status'].toUpperCase())) {
      rowErrors.push(`Row ${row}: Invalid status. Must be AVAILABLE, SOLD, or RESERVED`);
    }

    if (rowErrors.length > 0) {
      invalid.push({ row, ticket, errors: rowErrors });
      errors.push(...rowErrors);
    } else {
      valid.push(ticket);
    }
  });

  return { valid, invalid, errors };
}

/**
 * Import tickets from validated data
 * 
 * @param {Array<Object>} tickets - Validated ticket data
 * @param {number} raffle_id - Raffle ID
 * @returns {Promise<Object>} - Import results
 */
async function importTickets(tickets, raffle_id) {
  const results = {
    total: tickets.length,
    created: 0,
    updated: 0,
    skipped: 0,
    errors: []
  };

  const batchSize = 1000;

  for (let i = 0; i < tickets.length; i += batchSize) {
    const batch = tickets.slice(i, i + batchSize);

    for (const ticketData of batch) {
      try {
        // Get category information
        const category = ticketData['Category'].toUpperCase();
        const categoryInfo = await db.get(
          'SELECT id, price FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
          [raffle_id, category]
        );

        if (!categoryInfo) {
          results.errors.push(`Category ${category} not found in raffle`);
          results.skipped++;
          continue;
        }

        // Check if ticket already exists
        const existing = await ticketService.getTicketByNumber(ticketData['Ticket Number']);

        if (existing) {
          // Update existing ticket
          await db.run(
            `UPDATE tickets 
             SET status = ?,
                 buyer_name = ?,
                 buyer_phone = ?,
                 seller_name = ?,
                 seller_phone = ?
             WHERE ticket_number = ?`,
            [
              ticketData['Status'] || 'AVAILABLE',
              ticketData['Buyer Name'] || null,
              ticketData['Buyer Phone'] || null,
              ticketData['Seller Name'] || null,
              ticketData['Seller Phone'] || null,
              ticketData['Ticket Number']
            ]
          );
          results.updated++;
        } else {
          // Create new ticket
          await ticketService.createTicket({
            raffle_id: raffle_id,
            category_id: categoryInfo.id,
            category: category,
            ticket_number: ticketData['Ticket Number'],
            price: parseFloat(ticketData['Price'] || categoryInfo.price)
          });
          results.created++;
        }
      } catch (error) {
        console.error(`Error importing ticket ${ticketData['Ticket Number']}:`, error);
        results.errors.push(`${ticketData['Ticket Number']}: ${error.message}`);
        results.skipped++;
      }
    }
  }

  return results;
}

/**
 * Export tickets to Excel (STREAMING VERSION)
 * Processes tickets in batches to prevent memory issues with large datasets
 * 
 * @param {Object} filters - Export filters
 * @returns {Promise<Buffer>} - Excel file buffer
 */
async function exportTickets(filters = {}) {
  try {
    // Apply default and maximum limits to prevent memory issues
    const limit = Math.min(
      filters.limit || DEFAULT_EXPORT_LIMIT,
      MAX_EXPORT_LIMIT
    );
    const offset = filters.offset || 0;
    
    console.log(`📊 Export request - limit: ${limit.toLocaleString()}, offset: ${offset.toLocaleString()}`);
    
    let query = `
      SELECT 
        t.ticket_number as 'Ticket Number',
        t.category as 'Category',
        t.price as 'Price',
        t.barcode as 'Barcode',
        t.status as 'Status',
        t.buyer_name as 'Buyer Name',
        t.buyer_phone as 'Buyer Phone',
        t.seller_name as 'Seller Name',
        t.seller_phone as 'Seller Phone',
        t.printed as 'Printed',
        t.printed_at as 'Printed At',
        t.created_at as 'Created At'
      FROM tickets t
      WHERE 1=1
    `;
    
    const params = [];

    if (filters.raffle_id) {
      query += ' AND t.raffle_id = ?';
      params.push(filters.raffle_id);
    }

    if (filters.category) {
      query += ' AND t.category = ?';
      params.push(filters.category);
    }

    if (filters.status) {
      query += ' AND t.status = ?';
      params.push(filters.status);
    }

    if (filters.printed !== undefined) {
      query += ' AND t.printed = ?';
      params.push(filters.printed ? 1 : 0);
    }

    query += ' ORDER BY t.ticket_number ASC';

    // Process tickets in batches to prevent memory issues
    const allTickets = [];
    const totalToFetch = limit;
    
    console.log(`📦 Starting batch processing - total to fetch: ${totalToFetch.toLocaleString()}`);
    
    // Use processBatches to fetch data in chunks
    await db.processBatches(
      query,
      params,
      async (batch) => {
        // Calculate how many tickets we can still add without exceeding limit
        const remainingCapacity = totalToFetch - allTickets.length;
        
        if (remainingCapacity <= 0) {
          return true; // Already at or over limit, stop processing
        }
        
        // Only take what we need from this batch
        const batchToAdd = batch.slice(0, remainingCapacity);
        
        // Transform batch and add to results
        const transformedBatch = batchToAdd.map(ticket => ({
          ...ticket,
          'Printed': ticket['Printed'] ? 'Yes' : 'No'
        }));
        
        allTickets.push(...transformedBatch);
        
        console.log(`📈 Progress: ${allTickets.length.toLocaleString()} tickets processed`);
        
        // Stop if we've reached the limit
        if (allTickets.length >= totalToFetch) {
          return true; // Signal to stop processing more batches
        }
        
        return false; // Continue processing
      },
      { batchSize: BATCH_SIZE }
    );
    
    console.log(`✅ Batch processing complete - total tickets: ${allTickets.length.toLocaleString()}`);

    // Generate Excel file from collected tickets using ExcelJS
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Tickets');

    if (allTickets.length > 0) {
      // Set columns from first ticket keys
      const firstTicket = allTickets[0];
      worksheet.columns = Object.keys(firstTicket).map(key => ({
        header: key,
        key: key,
        width: Math.min(Math.max(key.length, 10), 30)
      }));

      // Add rows
      worksheet.addRows(allTickets);

      // Style header row
      worksheet.getRow(1).font = { bold: true };
      worksheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFD3D3D3' }
      };
    }

    const buffer = await workbook.xlsx.writeBuffer();
    
    console.log(`📄 Excel file generated - size: ${(buffer.length / 1024 / 1024).toFixed(2)} MB`);
    
    return buffer;
  } catch (error) {
    console.error('Error exporting tickets:', error);
    throw error;
  }
}

/**
 * Export tickets to CSV
 * 
 * @param {Object} filters - Export filters
 * @returns {Promise<string>} - CSV string
 */
async function exportTicketsCSV(filters = {}) {
  try {
    const buffer = await exportTickets(filters);
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer);
    
    const worksheet = workbook.worksheets[0];
    let csv = '';
    
    worksheet.eachRow((row) => {
      const values = [];
      row.eachCell((cell) => {
        let value = cell.value || '';
        // Escape quotes and wrap in quotes if contains comma
        if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
          value = '"' + value.replace(/"/g, '""') + '"';
        }
        values.push(value);
      });
      csv += values.join(',') + '\n';
    });
    
    return csv;
  } catch (error) {
    console.error('Error exporting tickets to CSV:', error);
    throw error;
  }
}

module.exports = {
  generateTemplate,
  parseImportFile,
  validateImportData,
  importTickets,
  exportTickets,
  exportTicketsCSV
};
