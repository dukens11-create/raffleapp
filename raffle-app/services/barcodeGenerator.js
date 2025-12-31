/**
 * Barcode Generator Service - Generate EAN-13 barcodes for raffle tickets
 * 
 * EAN-13 Format: 13 digits total
 * Structure: 978CCCTTTTTTTC
 * - 978: Fixed prefix (EAN bookland prefix)
 * - CCC: Category code (001=ABC, 002=EFG, 003=JKL, 004=XYZ)
 * - TTTTTTTT: Ticket number (8 digits, zero-padded)
 * - C: Check digit (calculated using EAN-13 algorithm)
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
 * Algorithm:
 * 1. Starting from right to left (excluding check digit position)
 * 2. Multiply odd position digits by 1, even position digits by 3
 * 3. Sum all results
 * 4. Check digit = (10 - (sum % 10)) % 10
 * 
 * @param {string} barcode12 - First 12 digits of barcode
 * @returns {string} - Check digit (0-9)
 */
function calculateEAN13CheckDigit(barcode12) {
  if (!barcode12 || barcode12.length !== 12) {
    throw new Error('Barcode must be exactly 12 digits');
  }

  let sum = 0;
  for (let i = 0; i < 12; i++) {
    const digit = parseInt(barcode12[i]);
    if (isNaN(digit)) {
      throw new Error('Barcode must contain only digits');
    }
    // Alternate multiplying by 1 and 3 (starting with 1 for position 0)
    sum += (i % 2 === 0) ? digit : digit * 3;
  }
  
  const checkDigit = (10 - (sum % 10)) % 10;
  return String(checkDigit);
}

/**
 * Generate EAN-13 barcode for a ticket
 * 
 * @param {string} category - Category code (ABC, EFG, JKL, XYZ)
 * @param {number} ticketNumber - Ticket sequence number (1-375000)
 * @returns {string} - 13-digit EAN-13 barcode
 * 
 * @example
 * generateBarcode('ABC', 1)         // Returns: "9780010000001" + check digit
 * generateBarcode('ABC', 500000)    // Returns: "9780015000000" + check digit
 * generateBarcode('EFG', 1)         // Returns: "9780020000001" + check digit
 */
function generateBarcode(category, ticketNumber) {
  if (!category || typeof category !== 'string') {
    throw new Error('Category must be a non-empty string');
  }

  const categoryCode = CATEGORY_MAP[category.toUpperCase()];
  if (!categoryCode) {
    throw new Error(`Invalid category: ${category}. Valid categories: ABC, EFG, JKL, XYZ`);
  }

  if (!Number.isInteger(ticketNumber) || ticketNumber < 1 || ticketNumber > 99999999) {
    throw new Error('Ticket number must be an integer between 1 and 99999999');
  }

  // Build barcode: 978 + category code (3 digits) + ticket number (8 digits)
  const prefix = '978';
  const ticketPadded = String(ticketNumber).padStart(8, '0');
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

  // Extract parts: 978CCCTTTTTTTC
  const prefix = barcode.slice(0, 3);
  if (prefix !== '978') {
    return null;
  }

  const categoryCode = barcode.slice(3, 6);
  const ticketNumberStr = barcode.slice(6, 14);

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
