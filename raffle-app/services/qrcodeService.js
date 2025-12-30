/**
 * QR Code Generation Service
 * Generates QR codes for raffle ticket verification
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
  return `${VERIFICATION_BASE_URL}/${ticketNumber}`;
}

/**
 * Generate QR code as PNG buffer
 * 
 * @param {string} data - Data to encode in QR code
 * @param {object} options - QR code options
 * @returns {Promise<Buffer>} - PNG image buffer
 */
async function generateQRCodeImage(data, options = {}) {
  const defaultOptions = {
    errorCorrectionLevel: 'M',  // Medium error correction (15%)
    type: 'png',
    quality: 1.0,
    margin: 1,
    width: 300,                  // Default width in pixels (for 1" at 300 DPI)
    color: {
      dark: '#000000',
      light: '#FFFFFF'
    }
  };
  
  const qrOptions = { ...defaultOptions, ...options };
  
  try {
    const buffer = await QRCode.toBuffer(data, qrOptions);
    return buffer;
  } catch (error) {
    console.error('Error generating QR code:', error);
    throw new Error(`Failed to generate QR code: ${error.message}`);
  }
}

/**
 * Generate QR code as Base64 data URL
 * 
 * @param {string} data - Data to encode in QR code
 * @param {object} options - QR code options
 * @returns {Promise<string>} - Base64 data URL
 */
async function generateQRCodeDataURL(data, options = {}) {
  const defaultOptions = {
    errorCorrectionLevel: 'M',
    type: 'image/png',
    quality: 1.0,
    margin: 1,
    width: 300
  };
  
  const qrOptions = { ...defaultOptions, ...options };
  
  try {
    const dataURL = await QRCode.toDataURL(data, qrOptions);
    return dataURL;
  } catch (error) {
    console.error('Error generating QR code data URL:', error);
    throw new Error(`Failed to generate QR code: ${error.message}`);
  }
}

/**
 * Generate QR code for ticket verification
 * 
 * @param {string} ticketNumber - Ticket number
 * @param {string} size - Size preset: 'main' (1" x 1") or 'stub' (0.4" x 0.4")
 * @returns {Promise<Buffer>} - PNG image buffer
 */
async function generateTicketQRCode(ticketNumber, size = 'main') {
  const verificationURL = generateVerificationURL(ticketNumber);
  
  // Size presets at 300 DPI
  const sizeOptions = {
    main: { width: 300 },    // 1" x 1" at 300 DPI
    stub: { width: 120 }     // 0.4" x 0.4" at 300 DPI
  };
  
  const options = sizeOptions[size] || sizeOptions.main;
  
  return await generateQRCodeImage(verificationURL, options);
}

/**
 * Generate QR code data URL for ticket verification
 * 
 * @param {string} ticketNumber - Ticket number
 * @param {string} size - Size preset: 'main' or 'stub'
 * @returns {Promise<string>} - Base64 data URL
 */
async function generateTicketQRCodeDataURL(ticketNumber, size = 'main') {
  const verificationURL = generateVerificationURL(ticketNumber);
  
  // Size presets at 300 DPI
  const sizeOptions = {
    main: { width: 300 },    // 1" x 1" at 300 DPI
    stub: { width: 120 }     // 0.4" x 0.4" at 300 DPI
  };
  
  const options = sizeOptions[size] || sizeOptions.main;
  
  return await generateQRCodeDataURL(verificationURL, options);
}

/**
 * Validate QR code data
 * 
 * @param {string} data - QR code data to validate
 * @returns {boolean} - True if valid
 */
function isValidQRData(data) {
  // Check if it's a verification URL
  if (data.startsWith(VERIFICATION_BASE_URL)) {
    return true;
  }
  return false;
}

/**
 * Extract ticket number from QR code verification URL
 * 
 * @param {string} qrData - QR code data (verification URL)
 * @returns {string|null} - Ticket number or null if invalid
 */
function getTicketNumberFromQR(qrData) {
  if (!qrData.startsWith(VERIFICATION_BASE_URL)) {
    return null;
  }
  
  const parts = qrData.split('/');
  const ticketNumber = parts[parts.length - 1];
  
  // Validate format: XXX-NNNNNN
  const regex = /^[A-Z]{3}-\d{6}$/;
  if (regex.test(ticketNumber)) {
    return ticketNumber;
  }
  
  return null;
}

module.exports = {
  generateVerificationURL,
  generateQRCodeImage,
  generateQRCodeDataURL,
  generateTicketQRCode,
  generateTicketQRCodeDataURL,
  isValidQRData,
  getTicketNumberFromQR
};
