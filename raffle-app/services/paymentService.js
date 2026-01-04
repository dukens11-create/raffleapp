/**
 * Payment Service
 * 
 * Handles payment integrations for:
 * - MonCash (Haiti mobile money)
 * - NatCash (Haiti mobile money)
 * - Manual/USSD payments (with admin verification)
 * 
 * SETUP INSTRUCTIONS:
 * 
 * 1. MonCash Integration:
 *    - Sign up at https://moncashbutton.digicelgroup.com/
 *    - Get your Client ID and Secret Key
 *    - Set mode to 'sandbox' for testing or 'production' for live
 *    - Configure in .env:
 *      MONCASH_CLIENT_ID=your_client_id
 *      MONCASH_SECRET_KEY=your_secret_key
 *      MONCASH_MODE=sandbox
 *      MONCASH_WALLET_NUMBER=509-1234-5678
 * 
 * 2. NatCash Integration:
 *    - Contact NatCash for API credentials
 *    - Configure in .env:
 *      NATCASH_API_KEY=your_api_key
 *      NATCASH_MERCHANT_ID=your_merchant_id
 *      NATCASH_MODE=sandbox
 *      NATCASH_WALLET_NUMBER=509-8765-4321
 * 
 * 3. Manual Payments:
 *    - Set your business phone numbers in .env
 *    - Payments will require admin approval
 */

require('dotenv').config();
const crypto = require('crypto');

// MonCash Configuration
const MONCASH_CONFIG = {
  clientId: process.env.MONCASH_CLIENT_ID,
  secretKey: process.env.MONCASH_SECRET_KEY,
  mode: process.env.MONCASH_MODE || 'sandbox',
  walletNumber: process.env.MONCASH_WALLET_NUMBER,
  // Sandbox and production endpoints
  endpoints: {
    sandbox: 'https://sandbox.moncashbutton.digicelgroup.com/Api',
    production: 'https://moncashbutton.digicelgroup.com/Api'
  }
};

// NatCash Configuration
const NATCASH_CONFIG = {
  apiKey: process.env.NATCASH_API_KEY,
  merchantId: process.env.NATCASH_MERCHANT_ID,
  mode: process.env.NATCASH_MODE || 'sandbox',
  walletNumber: process.env.NATCASH_WALLET_NUMBER,
  // Note: Update these endpoints with actual NatCash API endpoints when available
  endpoints: {
    sandbox: 'https://sandbox.natcash.ht/api',
    production: 'https://api.natcash.ht'
  }
};

// Manual Payment Configuration
const MANUAL_PAYMENT_CONFIG = {
  moncashWallet: process.env.MONCASH_WALLET_NUMBER,
  natcashWallet: process.env.NATCASH_WALLET_NUMBER,
  businessPhone: process.env.BUSINESS_PHONE_NUMBER
};

/**
 * MonCash: Get OAuth Token
 * MonCash uses OAuth 2.0 for authentication
 */
async function getMonCashToken() {
  if (!MONCASH_CONFIG.clientId || !MONCASH_CONFIG.secretKey) {
    throw new Error('MonCash credentials not configured');
  }
  
  try {
    const fetch = require('node-fetch');
    const endpoint = MONCASH_CONFIG.endpoints[MONCASH_CONFIG.mode];
    
    // Create Basic Auth header
    const auth = Buffer.from(`${MONCASH_CONFIG.clientId}:${MONCASH_CONFIG.secretKey}`).toString('base64');
    
    const response = await fetch(`${endpoint}/oauth/token`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: 'grant_type=client_credentials&scope=read,write'
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`MonCash auth failed: ${error}`);
    }
    
    const data = await response.json();
    return data.access_token;
  } catch (error) {
    console.error('MonCash token error:', error.message);
    throw error;
  }
}

/**
 * MonCash: Create Payment
 * 
 * @param {Object} paymentData
 * @param {number} paymentData.amount - Amount to charge
 * @param {string} paymentData.orderId - Unique order ID
 * @returns {Promise<Object>} Payment creation result
 */
async function createMonCashPayment(paymentData) {
  const { amount, orderId } = paymentData;
  
  try {
    const token = await getMonCashToken();
    const fetch = require('node-fetch');
    const endpoint = MONCASH_CONFIG.endpoints[MONCASH_CONFIG.mode];
    
    const response = await fetch(`${endpoint}/v1/CreatePayment`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        amount: amount,
        orderId: orderId
      })
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`MonCash payment creation failed: ${error}`);
    }
    
    const data = await response.json();
    
    return {
      success: true,
      paymentToken: data.payment_token,
      redirectUrl: `${endpoint}/v1/Redirect?token=${data.payment_token}`,
      mode: MONCASH_CONFIG.mode
    };
  } catch (error) {
    console.error('MonCash payment error:', error.message);
    throw error;
  }
}

/**
 * MonCash: Verify Payment Status
 * 
 * @param {string} transactionId - MonCash transaction ID
 * @returns {Promise<Object>} Payment status
 */
async function verifyMonCashPayment(transactionId) {
  try {
    const token = await getMonCashToken();
    const fetch = require('node-fetch');
    const endpoint = MONCASH_CONFIG.endpoints[MONCASH_CONFIG.mode];
    
    const response = await fetch(`${endpoint}/v1/RetrieveTransactionPayment?transactionId=${transactionId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`MonCash verification failed: ${error}`);
    }
    
    const data = await response.json();
    
    return {
      success: true,
      status: data.payment.status,
      transactionId: data.payment.transaction_id,
      amount: data.payment.cost,
      payer: data.payment.payer
    };
  } catch (error) {
    console.error('MonCash verification error:', error.message);
    throw error;
  }
}

/**
 * NatCash: Create Payment
 * Note: This is a generic implementation. Adjust based on actual NatCash API documentation
 * 
 * @param {Object} paymentData
 * @param {number} paymentData.amount - Amount to charge
 * @param {string} paymentData.orderId - Unique order ID
 * @returns {Promise<Object>} Payment creation result
 */
async function createNatCashPayment(paymentData) {
  if (!NATCASH_CONFIG.apiKey || !NATCASH_CONFIG.merchantId) {
    throw new Error('NatCash credentials not configured');
  }
  
  const { amount, orderId, buyer_phone } = paymentData;
  
  try {
    const fetch = require('node-fetch');
    const endpoint = NATCASH_CONFIG.endpoints[NATCASH_CONFIG.mode];
    
    // ⚠️ IMPORTANT: This is a placeholder endpoint structure
    // TODO: Update this with actual NatCash API documentation before production use
    // Contact NatCash support for the correct API endpoint and request format
    // Current implementation is based on common API patterns and may not work
    const response = await fetch(`${endpoint}/payments/create`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${NATCASH_CONFIG.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        merchant_id: NATCASH_CONFIG.merchantId,
        amount: amount,
        order_id: orderId,
        phone_number: buyer_phone,
        currency: 'HTG' // Haitian Gourde
      })
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`NatCash payment creation failed: ${error}`);
    }
    
    const data = await response.json();
    
    return {
      success: true,
      paymentId: data.payment_id || data.id,
      transactionRef: data.transaction_ref || data.reference,
      status: data.status,
      mode: NATCASH_CONFIG.mode
    };
  } catch (error) {
    console.error('NatCash payment error:', error.message);
    
    // Graceful degradation in sandbox mode for development/testing
    // In sandbox: Return simulated response to allow testing without real API
    // In production: Throw error to alert admin of API issues
    if (NATCASH_CONFIG.mode === 'sandbox') {
      console.warn('⚠️  NatCash API error in sandbox mode');
      console.warn('   Using simulated response for testing purposes');
      console.warn('   Update NatCash API endpoints before production deployment');
      return {
        success: true,
        paymentId: `NATCASH_SIM_${Date.now()}`,
        transactionRef: `SIMULATED_${orderId}`,
        status: 'pending',
        mode: 'sandbox',
        simulated: true
      };
    }
    
    // In production, throw the error so it can be handled by the caller
    // This ensures the admin is aware of API issues
    throw new Error(`NatCash API unavailable: ${error.message}`);
  }
}

/**
 * NatCash: Verify Payment Status
 * 
 * @param {string} paymentId - NatCash payment ID
 * @returns {Promise<Object>} Payment status
 */
async function verifyNatCashPayment(paymentId) {
  if (!NATCASH_CONFIG.apiKey) {
    throw new Error('NatCash API key not configured');
  }
  
  try {
    const fetch = require('node-fetch');
    const endpoint = NATCASH_CONFIG.endpoints[NATCASH_CONFIG.mode];
    
    // ⚠️ IMPORTANT: This is a placeholder endpoint structure
    // TODO: Update this with actual NatCash API documentation before production use
    // Contact NatCash support for the correct API endpoint and request format
    const response = await fetch(`${endpoint}/payments/${paymentId}/status`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${NATCASH_CONFIG.apiKey}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`NatCash verification failed: ${error}`);
    }
    
    const data = await response.json();
    
    return {
      success: true,
      status: data.status,
      paymentId: data.payment_id || data.id,
      amount: data.amount,
      transactionRef: data.transaction_ref
    };
  } catch (error) {
    console.error('NatCash verification error:', error.message);
    throw error;
  }
}

/**
 * Generate a unique payment reference
 */
function generatePaymentReference(prefix = 'PAY') {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `${prefix}-${timestamp}-${random}`;
}

/**
 * Get manual payment instructions
 */
function getManualPaymentInstructions(method) {
  const instructions = {
    moncash: {
      method: 'MonCash',
      walletNumber: MANUAL_PAYMENT_CONFIG.moncashWallet,
      steps: [
        'Dial *202# on your Digicel phone',
        'Select "Send Money"',
        `Enter wallet number: ${MANUAL_PAYMENT_CONFIG.moncashWallet}`,
        'Enter the exact amount shown',
        'Complete the transaction with your PIN',
        'Save your transaction reference number',
        'Submit the reference number below for verification'
      ],
      note: 'Your payment will be verified by our admin team within 24 hours'
    },
    natcash: {
      method: 'NatCash',
      walletNumber: MANUAL_PAYMENT_CONFIG.natcashWallet,
      steps: [
        'Open your NatCash mobile app',
        'Select "Transfer Money"',
        `Enter wallet number: ${MANUAL_PAYMENT_CONFIG.natcashWallet}`,
        'Enter the exact amount shown',
        'Complete the transaction',
        'Take a screenshot or note the reference number',
        'Submit the reference number below for verification'
      ],
      note: 'Your payment will be verified by our admin team within 24 hours'
    }
  };
  
  return instructions[method] || null;
}

/**
 * Check if payment methods are configured
 */
function getAvailablePaymentMethods() {
  const methods = [];
  
  // MonCash API
  if (MONCASH_CONFIG.clientId && MONCASH_CONFIG.secretKey) {
    methods.push({
      id: 'moncash_api',
      name: 'MonCash (Automated)',
      type: 'automated',
      enabled: true
    });
  }
  
  // NatCash API
  if (NATCASH_CONFIG.apiKey && NATCASH_CONFIG.merchantId) {
    methods.push({
      id: 'natcash_api',
      name: 'NatCash (Automated)',
      type: 'automated',
      enabled: true
    });
  }
  
  // Manual MonCash
  if (MANUAL_PAYMENT_CONFIG.moncashWallet) {
    methods.push({
      id: 'moncash_manual',
      name: 'MonCash (USSD/Manual)',
      type: 'manual',
      enabled: true
    });
  }
  
  // Manual NatCash
  if (MANUAL_PAYMENT_CONFIG.natcashWallet) {
    methods.push({
      id: 'natcash_manual',
      name: 'NatCash (Manual)',
      type: 'manual',
      enabled: true
    });
  }
  
  return methods;
}

module.exports = {
  // MonCash
  createMonCashPayment,
  verifyMonCashPayment,
  
  // NatCash
  createNatCashPayment,
  verifyNatCashPayment,
  
  // Manual payments
  getManualPaymentInstructions,
  generatePaymentReference,
  
  // Configuration
  getAvailablePaymentMethods,
  MONCASH_CONFIG,
  NATCASH_CONFIG,
  MANUAL_PAYMENT_CONFIG
};
