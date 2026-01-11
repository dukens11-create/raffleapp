/**
 * QR Code Service - DISABLED
 * QR codes have been removed from the system. All functions return null/empty values.
 * This file is kept for backward compatibility during migration.
 */

// NOTE: QR code generation has been disabled as per system requirements.
// All tickets now use 8-digit barcodes only.

/**
 * Generate verification URL for a ticket (DISABLED - returns empty string)
 */
function generateVerificationURL(ticketNumber) {
  return '';
}

/**
 * Generate QR code image as PNG buffer (DISABLED - returns null)
 */
async function generateQRCodeImage(data, options = {}) {
  return null;
}

/**
 * Generate QR code for ticket verification (DISABLED - returns null values)
 */
async function generateTicketQRCode(ticketNumber) {
  return {
    verificationURL: '',
    mainQRCode: null,
    stubQRCode: null
  };
}

/**
 * Generate QR code as data URL (DISABLED - returns empty string)
 */
async function generateQRCodeDataURL(data, options = {}) {
  return '';
}

/**
 * Validate verification URL format (DISABLED - always returns false)
 */
function validateVerificationURL(url) {
  return false;
}

/**
 * Extract ticket number from verification URL (DISABLED - returns null)
 */
function extractTicketNumberFromURL(url) {
  return null;
}

/**
 * Generate QR code data with full ticket information (DISABLED - returns empty string)
 */
function generateQRCodeData(ticket) {
  return '';
}

/**
 * Generate QR code buffer for printing (DISABLED - returns null)
 */
async function generateQRCodeBuffer(ticket, options = {}) {
  return null;
}

/**
 * Generate QR code as data URL with full ticket data (DISABLED - returns empty string)
 */
async function generateQRCode(ticket, options = {}) {
  return '';
}

const VERIFICATION_BASE_URL = ''; // Disabled

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
