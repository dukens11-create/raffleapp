/**
 * Barcode Generator Service - Generate 8-digit barcodes for raffle tickets
 * 
 * 8-Digit Format: 8 digits total
 * Structure: CTTTTTTT
 * - C: Category prefix (1=ABC, 2=EFG, 3=JKL, 4=XYZ) - 1 digit
 * - TTTTTTT: Ticket sequence number (7 digits, zero-padded, supports 1-9,999,999)
 * Total: 1 + 7 = 8 digits
 * 
 * Examples:
 *   ABC-000001 -> 10000001
 *   EFG-000001 -> 20000001
 *   JKL-000001 -> 30000001
 *   XYZ-000001 -> 40000001
 */

/**
 * Category mapping to 1-digit prefix for 8-digit barcodes
 */
const CATEGORY_MAP = {
  'BAS': '1',
  'PRM': '2',
  'BRZ': '3',
  'SLV': '4',
  'GLD': '5',
  'DIA': '6'
};

// No check digit calculation needed for 8-digit barcodes

/**
 * Generate 8-digit barcode for a ticket
 * 
 * @param {string} category - Category code (BAS, PRM, BRZ, SLV, GLD, DIA)
 * @param {number} ticketNumber - Ticket sequence number (1-9999999)
 * @returns {string} - 8-digit barcode
 * 
 * @example
 * generateBarcode('BAS', 1)         // Returns: "10000001"
 * generateBarcode('BAS', 500000)    // Returns: "10500000"
 * generateBarcode('PRM', 1)         // Returns: "20000001"
 * generateBarcode('DIA', 999999)    // Returns: "60999999"
 */
function generateBarcode(category, ticketNumber) {
  if (!category || typeof category !== 'string') {
    throw new Error('Category must be a non-empty string');
  }

  const categoryPrefix = CATEGORY_MAP[category.toUpperCase()];
  if (!categoryPrefix) {
    throw new Error(`Invalid category: ${category}. Valid categories: ABC, EFG, JKL, XYZ`);
  }

  if (!Number.isInteger(ticketNumber) || ticketNumber < 1 || ticketNumber > 9999999) {
    throw new Error('Ticket number must be an integer between 1 and 9999999');
  }

  // Build barcode: 1 digit category prefix + 7 digit ticket number = 8 digits
  const ticketPadded = String(ticketNumber).padStart(7, '0');
  const barcode = categoryPrefix + ticketPadded;

  return barcode;
}

/**
 * Validate 8-digit barcode format
 * 
 * @param {string} barcode - 8-digit barcode
 * @returns {boolean} - True if valid
 */
function validateBarcode(barcode) {
  if (!barcode || typeof barcode !== 'string' || barcode.length !== 8) {
    return false;
  }

  // Check all characters are digits
  if (!/^\d{8}$/.test(barcode)) {
    return false;
  }

  // Check first digit is valid category (1-4)
  const categoryDigit = barcode[0];
  if (!['1', '2', '3', '4'].includes(categoryDigit)) {
    return false;
  }

  return true;
}

/**
 * Extract category and ticket number from 8-digit barcode
 * 
 * @param {string} barcode - 8-digit barcode
 * @returns {Object} - { category, ticketNumber } or null if invalid
 */
function parseBarcode(barcode) {
  if (!validateBarcode(barcode)) {
    return null;
  }

  // Extract parts: CTTTTTTT
  const categoryDigit = barcode[0];
  const ticketNumberStr = barcode.slice(1);

  // Reverse lookup category
  const categoryReverse = {
    '1': 'BAS',
    '2': 'PRM',
    '3': 'BRZ',
    '4': 'SLV',
    '5': 'GLD',
    '6': 'DIA'
  };

  const category = categoryReverse[categoryDigit];
  if (!category) {
    return null;
  }

  const ticketNumber = parseInt(ticketNumberStr, 10);

  return {
    category,
    ticketNumber
  };
}

module.exports = {
  generateBarcode,
  validateBarcode,
  parseBarcode,
  CATEGORY_MAP
};
