/**
 * Barcode Service - Generate barcodes for raffle tickets
 * Uses bwip-js to generate Code128 barcodes
 */

const bwipjs = require('bwip-js');

/**
 * Category prefix mapping for barcode generation
 * ABC -> 1, EFG -> 2, JKL -> 3, XYZ -> 4
 */
const CATEGORY_PREFIX_MAP = {
  'ABC': '1',
  'EFG': '2',
  'JKL': '3',
  'XYZ': '4'
};

/**
 * Generate barcode number from ticket number
 * Format: Category prefix + ticket sequence number
 * Examples:
 *   ABC-000001 -> 10000001
 *   EFG-000001 -> 20000001
 *   JKL-000001 -> 30000001
 *   XYZ-000001 -> 40000001
 * 
 * @param {string} ticketNumber - Ticket number (e.g., "ABC-000001")
 * @returns {string} - 8-digit barcode (e.g., "10000001")
 */
function generateBarcodeNumber(ticketNumber) {
  if (!ticketNumber || typeof ticketNumber !== 'string') {
    throw new Error('Invalid ticket number');
  }

  const parts = ticketNumber.split('-');
  if (parts.length !== 2) {
    throw new Error('Invalid ticket number format. Expected format: ABC-000001');
  }

  const category = parts[0].toUpperCase();
  const sequence = parts[1];

  const prefix = CATEGORY_PREFIX_MAP[category];
  if (!prefix) {
    throw new Error(`Unknown category: ${category}. Valid categories: ABC, EFG, JKL, XYZ`);
  }

  // Format: 1 digit prefix + 7 digit sequence = 8 digits
  return prefix + sequence;
}

/**
 * Generate barcode image as PNG buffer
 * 
 * @param {string} barcodeNumber - Barcode number to encode
 * @param {Object} options - Barcode generation options
 * @param {number} options.height - Height in pixels (default: 50)
 * @param {number} options.width - Width in pixels (default: 2)
 * @param {boolean} options.includetext - Include human-readable text (default: true)
 * @returns {Promise<Buffer>} - PNG image buffer
 */
async function generateBarcodeImage(barcodeNumber, options = {}) {
  const {
    height = 50,
    width = 2,
    includetext = true
  } = options;

  try {
    const buffer = await bwipjs.toBuffer({
      bcid: 'code128',       // Barcode type: Code128
      text: barcodeNumber,   // Text to encode
      scale: width,          // Bar width multiplier
      height: height,        // Bar height in pixels
      includetext: includetext, // Show human-readable text
      textxalign: 'center',  // Center the text
    });

    return buffer;
  } catch (error) {
    console.error('Barcode generation error:', error);
    throw new Error(`Failed to generate barcode: ${error.message}`);
  }
}

/**
 * Generate barcode for a ticket
 * Combines barcode number generation and image generation
 * 
 * @param {string} ticketNumber - Ticket number (e.g., "ABC-000001")
 * @param {Object} options - Image generation options
 * @returns {Promise<Object>} - { barcodeNumber, imageBuffer }
 */
async function generateTicketBarcode(ticketNumber, options = {}) {
  const barcodeNumber = generateBarcodeNumber(ticketNumber);
  const imageBuffer = await generateBarcodeImage(barcodeNumber, options);
  
  return {
    barcodeNumber,
    imageBuffer
  };
}

/**
 * Validate barcode number format
 * 
 * @param {string} barcodeNumber - Barcode number to validate
 * @returns {boolean} - True if valid
 */
function validateBarcodeNumber(barcodeNumber) {
  if (!barcodeNumber || typeof barcodeNumber !== 'string') {
    return false;
  }

  // Check format: 8 digits, first digit 1-4
  const regex = /^[1-4]\d{7}$/;
  return regex.test(barcodeNumber);
}

/**
 * Get category from barcode number
 * 
 * @param {string} barcodeNumber - Barcode number
 * @returns {string} - Category code (ABC, EFG, JKL, XYZ)
 */
function getCategoryFromBarcode(barcodeNumber) {
  if (!validateBarcodeNumber(barcodeNumber)) {
    throw new Error('Invalid barcode number');
  }

  const prefix = barcodeNumber[0];
  const reverseMap = {
    '1': 'ABC',
    '2': 'EFG',
    '3': 'JKL',
    '4': 'XYZ'
  };

  return reverseMap[prefix];
}

module.exports = {
  generateBarcodeNumber,
  generateBarcodeImage,
  generateTicketBarcode,
  validateBarcodeNumber,
  getCategoryFromBarcode,
  CATEGORY_PREFIX_MAP
};
