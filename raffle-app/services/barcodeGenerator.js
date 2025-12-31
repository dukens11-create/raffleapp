/**
 * Barcode Generator Service - Generate EAN-13 barcodes for raffle tickets
 * 
 * EAN-13 Format: 13 digits total
 * Structure: 978CCCTTTTTTC
 * - 978: Fixed prefix (EAN bookland prefix) - 3 digits
 * - CCC: Category code (001=ABC, 002=EFG, 003=JKL, 004=XYZ) - 3 digits
 * - TTTTTT: Ticket number (6 digits, zero-padded, supports 1-999,999)
 * - C: Check digit (calculated using EAN-13 algorithm) - 1 digit
 * Total: 3 + 3 + 6 + 1 = 13 digits
 */

/**
 * Category mapping to 3-digit codes for EAN-13
 */
const CATEGORY_MAP = {
  'ABC': '001',
  'EFG': '002',
  'JKL': '003',
  'XYZ': '004'
};

/**
 * Calculate EAN-13 check digit
 * Algorithm (from right to left, position 1 is rightmost of the 12 digits):
 * 1. Starting from the rightmost digit (position 1), alternate multiplying by 3 and 1
 * 2. Position 1, 3, 5, 7, 9, 11 (odd positions from right): multiply by 3
 * 3. Position 2, 4, 6, 8, 10, 12 (even positions from right): multiply by 1
 * 4. Sum all results
 * 5. Check digit = (10 - (sum % 10)) % 10
 * 
 * @param {string} barcode12 - First 12 digits of barcode
 * @returns {string} - Check digit (0-9)
 */
function calculateEAN13CheckDigit(barcode12) {
  if (!barcode12 || barcode12.length !== 12) {
    throw new Error('Barcode must be exactly 12 digits');
  }

  let sum = 0;
  // Process from left to right (index 0-11), but consider position from right
  for (let i = 0; i < 12; i++) {
    const digit = parseInt(barcode12[i]);
    if (isNaN(digit)) {
      throw new Error('Barcode must contain only digits');
    }
    // Position from right: 12 - i
    // Odd positions from right (12, 10, 8, 6, 4, 2): multiply by 1
    // Even positions from right (11, 9, 7, 5, 3, 1): multiply by 3
    const positionFromRight = 12 - i;
    sum += (positionFromRight % 2 === 0) ? (digit * 3) : digit;
  }
  
  const checkDigit = (10 - (sum % 10)) % 10;
  return String(checkDigit);
}

/**
 * Generate EAN-13 barcode for a ticket
 * 
 * @param {string} category - Category code (ABC, EFG, JKL, XYZ)
 * @param {number} ticketNumber - Ticket sequence number (1-999999, supports up to 375,000 per category)
 * @returns {string} - 13-digit EAN-13 barcode
 * 
 * @example
 * generateBarcode('ABC', 1)         // Returns: "9780010000011"
 * generateBarcode('ABC', 500000)    // Returns: "9780015000006"
 * generateBarcode('EFG', 1)         // Returns: "9780020000010"
 */
function generateBarcode(category, ticketNumber) {
  if (!category || typeof category !== 'string') {
    throw new Error('Category must be a non-empty string');
  }

  const categoryCode = CATEGORY_MAP[category.toUpperCase()];
  if (!categoryCode) {
    throw new Error(`Invalid category: ${category}. Valid categories: ABC, EFG, JKL, XYZ`);
  }

  if (!Number.isInteger(ticketNumber) || ticketNumber < 1 || ticketNumber > 999999) {
    throw new Error('Ticket number must be an integer between 1 and 999999');
  }

  // Build barcode: 978 + category code (3 digits) + ticket number (6 digits)
  const prefix = '978';
  const ticketPadded = String(ticketNumber).padStart(6, '0');
  const barcode12 = prefix + categoryCode + ticketPadded;

  // Calculate and append check digit
  const checkDigit = calculateEAN13CheckDigit(barcode12);
  const barcode13 = barcode12 + checkDigit;

  return barcode13;
}

/**
 * Validate EAN-13 barcode format and check digit
 * 
 * @param {string} barcode - 13-digit EAN-13 barcode
 * @returns {boolean} - True if valid
 */
function validateEAN13Barcode(barcode) {
  if (!barcode || typeof barcode !== 'string' || barcode.length !== 13) {
    return false;
  }

  // Check all characters are digits
  if (!/^\d{13}$/.test(barcode)) {
    return false;
  }

  // Verify check digit
  const barcode12 = barcode.slice(0, 12);
  const providedCheckDigit = barcode[12];
  const calculatedCheckDigit = calculateEAN13CheckDigit(barcode12);

  return providedCheckDigit === calculatedCheckDigit;
}

/**
 * Extract category and ticket number from EAN-13 barcode
 * 
 * @param {string} barcode - 13-digit EAN-13 barcode
 * @returns {Object} - { category, ticketNumber } or null if invalid
 */
function parseBarcode(barcode) {
  if (!validateEAN13Barcode(barcode)) {
    return null;
  }

  // Extract parts: 978CCCTTTTTTC
  const prefix = barcode.slice(0, 3);
  if (prefix !== '978') {
    return null;
  }

  const categoryCode = barcode.slice(3, 6);
  const ticketNumberStr = barcode.slice(6, 12); // Changed from 6,14 to 6,12

  // Reverse lookup category
  const categoryReverse = {
    '001': 'ABC',
    '002': 'EFG',
    '003': 'JKL',
    '004': 'XYZ'
  };

  const category = categoryReverse[categoryCode];
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
  calculateEAN13CheckDigit,
  validateEAN13Barcode,
  parseBarcode,
  CATEGORY_MAP
};
