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
 * Check if a barcode is in legacy format
 * Legacy formats include:
 * - 13 digits (EAN-13): e.g., 9780000000001
 * - Ticket number formats: ABC000001, ABC-000001, ABC-000-001
 * - Pure numeric sequences: 1000001 (7 digits), 000001 (6 digits)
 * - Any barcode with 6+ characters that doesn't match 8-digit format
 * 
 * @param {string} barcode - Barcode to check
 * @returns {boolean} - True if legacy format
 */
function isLegacyBarcode(barcode) {
  if (!barcode || typeof barcode !== 'string') {
    return false;
  }

  // Remove whitespace
  const cleaned = barcode.trim();
  
  // Too short to be valid
  if (cleaned.length < 6) {
    return false;
  }

  // If it matches the 8-digit format, it's not legacy
  const new8DigitFormat = /^[1-4]\d{7}$/;
  if (new8DigitFormat.test(cleaned)) {
    return false;
  }

  // Check for common legacy patterns
  // 13 digits (EAN-13)
  if (/^\d{13}$/.test(cleaned)) {
    return true;
  }

  const cleanedUpper = cleaned.toUpperCase();

  // Alphanumeric with optional dashes (ticket number patterns)
  if (/^[A-Z]{3}-?\d{6}$/.test(cleanedUpper)) {
    return true;
  }

  // Alphanumeric with multiple dashes
  if (/^[A-Z]{3}-\d{3}-\d{3}$/.test(cleanedUpper)) {
    return true;
  }

  // Pure numeric sequences (6-7 digits, or 9-13 digits)
  // Note: 8 digits excluded above, 14+ would be too long for typical barcodes
  if (/^\d{6,7}$/.test(cleaned) || /^\d{9,13}$/.test(cleaned)) {
    return true;
  }

  // Any other alphanumeric pattern with letters and numbers (6+ chars)
  if (/^[A-Z0-9-]{6,}$/.test(cleanedUpper) && /[A-Z]/.test(cleanedUpper) && /\d/.test(cleaned)) {
    return true;
  }

  return false;
}

/**
 * Validate barcode number format
 * Accepts both new 8-digit format and legacy formats
 * 
 * @param {string} barcodeNumber - Barcode number to validate
 * @returns {boolean} - True if valid (either new or legacy format)
 */
function validateBarcodeNumber(barcodeNumber) {
  if (!barcodeNumber || typeof barcodeNumber !== 'string') {
    return false;
  }

  // Remove whitespace
  const cleaned = barcodeNumber.trim();

  // Reject empty or whitespace-only strings
  if (cleaned.length === 0) {
    return false;
  }

  // Reject if only special characters (no letters or numbers)
  if (!/[A-Z0-9]/i.test(cleaned)) {
    return false;
  }

  // Check new 8-digit format: 8 digits, first digit 1-4
  const new8DigitFormat = /^[1-4]\d{7}$/;
  if (new8DigitFormat.test(cleaned)) {
    return true;
  }

  // Check if it's a valid legacy format
  return isLegacyBarcode(cleaned);
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
  isLegacyBarcode,
  getCategoryFromBarcode,
  CATEGORY_PREFIX_MAP
};
