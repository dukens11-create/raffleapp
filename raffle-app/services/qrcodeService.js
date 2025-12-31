/**
 * QR Code Service - Generate QR codes for raffle tickets
 * Uses qrcode library to generate QR codes with verification URLs
 */

const QRCode = require('qrcode');

// Base URL for ticket verification
const VERIFICATION_BASE_URL = process.env.VERIFICATION_URL || 'https://enejipamticket.com/verify';

/**
 * Generate verification URL for a ticket
 * 
 * @param {string} ticketNumber - Ticket number (e.g., "ABC-000001")
 * @returns {string} - Verification URL
 */
function generateVerificationURL(ticketNumber) {
  if (!ticketNumber || typeof ticketNumber !== 'string') {
    throw new Error('Invalid ticket number');
  }

  return `${VERIFICATION_BASE_URL}/${ticketNumber}`;
}

/**
 * Generate QR code image as PNG buffer
 * 
 * @param {string} data - Data to encode (typically verification URL)
 * @param {Object} options - QR code generation options
 * @param {number} options.size - Size in pixels for main ticket (default: 96 = 1 inch at 96 DPI)
 * @param {string} options.errorCorrectionLevel - Error correction level: L, M, Q, H (default: M)
 * @returns {Promise<Buffer>} - PNG image buffer
 */
async function generateQRCodeImage(data, options = {}) {
  const {
    size = 96, // 1 inch at 96 DPI
    errorCorrectionLevel = 'M' // Medium error correction (15% restoration)
  } = options;

  try {
    const buffer = await QRCode.toBuffer(data, {
      errorCorrectionLevel: errorCorrectionLevel,
      type: 'png',
      width: size,
      margin: 1, // Quiet zone margin
      color: {
        dark: '#000000',  // Black
        light: '#FFFFFF'  // White
      }
    });

    return buffer;
  } catch (error) {
    console.error('QR code generation error:', error);
    throw new Error(`Failed to generate QR code: ${error.message}`);
  }
}

/**
 * Generate QR code for ticket verification
 * Creates both main ticket size (1" x 1") and stub size (0.4" x 0.4")
 * 
 * @param {string} ticketNumber - Ticket number (e.g., "ABC-000001")
 * @returns {Promise<Object>} - { verificationURL, mainQRCode, stubQRCode }
 */
async function generateTicketQRCode(ticketNumber) {
  const verificationURL = generateVerificationURL(ticketNumber);
  
  // Generate main QR code (1" x 1" at 96 DPI)
  const mainQRCode = await generateQRCodeImage(verificationURL, {
    size: 96, // 1 inch at 96 DPI
    errorCorrectionLevel: 'M'
  });

  // Generate stub QR code (0.4" x 0.4" at 96 DPI)
  const stubQRCode = await generateQRCodeImage(verificationURL, {
    size: 38, // 0.4 inch at 96 DPI (rounded from 38.4)
    errorCorrectionLevel: 'M'
  });

  return {
    verificationURL,
    mainQRCode,
    stubQRCode
  };
}

/**
 * Generate QR code as data URL (for web display)
 * 
 * @param {string} data - Data to encode
 * @param {Object} options - Options for QR code generation
 * @returns {Promise<string>} - Data URL
 */
async function generateQRCodeDataURL(data, options = {}) {
  const {
    size = 96,
    errorCorrectionLevel = 'M'
  } = options;

  try {
    const dataURL = await QRCode.toDataURL(data, {
      errorCorrectionLevel: errorCorrectionLevel,
      width: size,
      margin: 1,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    return dataURL;
  } catch (error) {
    console.error('QR code data URL generation error:', error);
    throw new Error(`Failed to generate QR code data URL: ${error.message}`);
  }
}

/**
 * Validate verification URL format
 * 
 * @param {string} url - URL to validate
 * @returns {boolean} - True if valid
 */
function validateVerificationURL(url) {
  if (!url || typeof url !== 'string') {
    return false;
  }

  // Check if URL starts with verification base URL
  return url.startsWith(VERIFICATION_BASE_URL);
}

/**
 * Extract ticket number from verification URL
 * 
 * @param {string} url - Verification URL
 * @returns {string|null} - Ticket number or null if invalid
 */
function extractTicketNumberFromURL(url) {
  if (!validateVerificationURL(url)) {
    return null;
  }

  const parts = url.split('/');
  return parts[parts.length - 1];
}

/**
 * Generate QR code data with full ticket information
 * Creates JSON data containing all ticket details
 * 
 * @param {Object} ticket - Ticket object
 * @param {string} ticket.ticket_number - Ticket number
 * @param {string} ticket.barcode - Barcode number
 * @param {string} ticket.category - Category code
 * @param {number} ticket.price - Ticket price
 * @param {number} ticket.raffle_id - Raffle ID
 * @returns {string} - JSON string with ticket data
 */
function generateQRCodeData(ticket) {
  const qrData = {
    ticket_number: ticket.ticket_number,
    barcode: ticket.barcode,
    category: ticket.category,
    price: ticket.price,
    raffle_id: ticket.raffle_id,
    generated_at: new Date().toISOString()
  };
  
  return JSON.stringify(qrData);
}

/**
 * Generate QR code buffer for printing with full ticket data
 * 
 * @param {Object} ticket - Ticket object with all details
 * @param {Object} options - QR code options
 * @param {number} options.size - Size in pixels (default: 150)
 * @returns {Promise<Buffer>} - PNG buffer
 */
async function generateQRCodeBuffer(ticket, options = {}) {
  const {
    size = 150,
    errorCorrectionLevel = 'M'
  } = options;

  const qrString = generateQRCodeData(ticket);
  
  try {
    const buffer = await QRCode.toBuffer(qrString, {
      errorCorrectionLevel: errorCorrectionLevel,
      type: 'png',
      width: size,
      margin: 1,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    
    return buffer;
  } catch (error) {
    console.error('QR code buffer generation error:', error);
    throw new Error(`Failed to generate QR code buffer: ${error.message}`);
  }
}

/**
 * Generate QR code as data URL with full ticket data
 * 
 * @param {Object} ticket - Ticket object with all details
 * @param {Object} options - QR code options
 * @returns {Promise<string>} - Data URL
 */
async function generateQRCode(ticket, options = {}) {
  const {
    size = 200,
    errorCorrectionLevel = 'M'
  } = options;

  const qrString = generateQRCodeData(ticket);
  
  try {
    const dataURL = await QRCode.toDataURL(qrString, {
      errorCorrectionLevel: errorCorrectionLevel,
      width: size,
      margin: 1,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    
    return dataURL;
  } catch (error) {
    console.error('QR code data URL generation error:', error);
    throw new Error(`Failed to generate QR code: ${error.message}`);
  }
}

module.exports = {
  generateVerificationURL,
  generateQRCodeImage,
  generateTicketQRCode,
  generateQRCodeDataURL,
  validateVerificationURL,
  extractTicketNumberFromURL,
  generateQRCodeData,
  generateQRCodeBuffer,
  generateQRCode,
  VERIFICATION_BASE_URL
};
