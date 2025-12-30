/**
 * Barcode Generation Service
 * Generates unique barcodes for raffle tickets using Code128 format
 */

const bwipjs = require('bwip-js');

/**
 * Generate barcode number from ticket number
 * Category prefix mapping:
 * - ABC: 1000000 + ticket_num
 * - EFG: 2000000 + ticket_num  
 * - JKL: 3000000 + ticket_num
 * - XYZ: 4000000 + ticket_num
 * 
 * @param {string} ticketNumber - Ticket number (e.g., "ABC-000001")
 * @returns {string} - Barcode number (e.g., "1000001")
 */
function generateBarcodeNumber(ticketNumber) {
  // Extract category and number from ticket_number
  const parts = ticketNumber.split('-');
  if (parts.length !== 2) {
    throw new Error('Invalid ticket number format. Expected format: ABC-000001');
  }
  
  const category = parts[0].toUpperCase();
  const ticketNum = parseInt(parts[1], 10);
  
  if (isNaN(ticketNum)) {
    throw new Error('Invalid ticket number. Number part must be numeric.');
  }
  
  // Map category to prefix
  const prefixMap = {
    'ABC': 1000000,
    'EFG': 2000000,
    'JKL': 3000000,
    'XYZ': 4000000
  };
  
  const prefix = prefixMap[category];
  if (!prefix) {
    throw new Error(`Unknown category: ${category}. Valid categories: ABC, EFG, JKL, XYZ`);
  }
  
  const barcodeNumber = prefix + ticketNum;
  return barcodeNumber.toString();
}

/**
 * Generate barcode image as PNG buffer
 * 
 * @param {string} barcodeNumber - The barcode number to encode
 * @param {object} options - Options for barcode generation
 * @returns {Promise<Buffer>} - PNG image buffer
 */
async function generateBarcodeImage(barcodeNumber, options = {}) {
  const defaultOptions = {
    bcid: 'code128',        // Barcode type: Code128
    text: barcodeNumber,     // Text to encode
    scale: 3,                // 3x scaling factor
    height: 10,              // Bar height in millimeters
    includetext: true,       // Show text below barcode
    textxalign: 'center',    // Center the text
  };
  
  const barcodeOptions = { ...defaultOptions, ...options };
  
  try {
    const png = await bwipjs.toBuffer(barcodeOptions);
    return png;
  } catch (error) {
    console.error('Error generating barcode:', error);
    throw new Error(`Failed to generate barcode: ${error.message}`);
  }
}

/**
 * Generate barcode image as Base64 data URL
 * 
 * @param {string} barcodeNumber - The barcode number to encode
 * @param {object} options - Options for barcode generation
 * @returns {Promise<string>} - Base64 data URL
 */
async function generateBarcodeDataURL(barcodeNumber, options = {}) {
  const png = await generateBarcodeImage(barcodeNumber, options);
  const base64 = png.toString('base64');
  return `data:image/png;base64,${base64}`;
}

/**
 * Validate barcode number format
 * 
 * @param {string} barcodeNumber - Barcode number to validate
 * @returns {boolean} - True if valid
 */
function isValidBarcode(barcodeNumber) {
  const num = parseInt(barcodeNumber, 10);
  if (isNaN(num)) return false;
  
  // Check if it falls in valid ranges
  if (num >= 1000001 && num <= 1500000) return true; // ABC
  if (num >= 2000001 && num <= 2500000) return true; // EFG
  if (num >= 3000001 && num <= 3250000) return true; // JKL
  if (num >= 4000001 && num <= 4250000) return true; // XYZ
  
  return false;
}

/**
 * Get category from barcode number
 * 
 * @param {string} barcodeNumber - Barcode number
 * @returns {string} - Category code (ABC, EFG, JKL, XYZ)
 */
function getCategoryFromBarcode(barcodeNumber) {
  const num = parseInt(barcodeNumber, 10);
  if (isNaN(num)) return null;
  
  if (num >= 1000000 && num < 2000000) return 'ABC';
  if (num >= 2000000 && num < 3000000) return 'EFG';
  if (num >= 3000000 && num < 4000000) return 'JKL';
  if (num >= 4000000 && num < 5000000) return 'XYZ';
  
  return null;
}

/**
 * Get ticket number from barcode
 * 
 * @param {string} barcodeNumber - Barcode number
 * @returns {string} - Ticket number (e.g., "ABC-000001")
 */
function getTicketNumberFromBarcode(barcodeNumber) {
  const category = getCategoryFromBarcode(barcodeNumber);
  if (!category) return null;
  
  const num = parseInt(barcodeNumber, 10);
  const prefixMap = {
    'ABC': 1000000,
    'EFG': 2000000,
    'JKL': 3000000,
    'XYZ': 4000000
  };
  
  const ticketNum = num - prefixMap[category];
  return `${category}-${ticketNum.toString().padStart(6, '0')}`;
}

module.exports = {
  generateBarcodeNumber,
  generateBarcodeImage,
  generateBarcodeDataURL,
  isValidBarcode,
  getCategoryFromBarcode,
  getTicketNumberFromBarcode
};
