/**
 * SMS Notification Service
 * 
 * Handles sending SMS notifications via configured providers:
 * - Twilio (recommended for international use)
 * - Custom SMS Gateway (for local providers)
 * 
 * SETUP INSTRUCTIONS:
 * 
 * 1. For Twilio (Recommended):
 *    - Sign up at https://www.twilio.com
 *    - Get your Account SID and Auth Token from console
 *    - Purchase a phone number
 *    - Set in .env:
 *      TWILIO_ACCOUNT_SID=your_account_sid
 *      TWILIO_AUTH_TOKEN=your_auth_token
 *      TWILIO_PHONE_NUMBER=+1234567890
 *      SMS_PROVIDER=twilio
 * 
 * 2. For Custom SMS Gateway:
 *    - Configure your SMS gateway URL and API key
 *    - Set in .env:
 *      CUSTOM_SMS_GATEWAY_URL=https://your-gateway.com/send
 *      CUSTOM_SMS_GATEWAY_API_KEY=your_api_key
 *      CUSTOM_SMS_GATEWAY_SENDER=YourBusiness
 *      SMS_PROVIDER=custom
 * 
 * 3. Admin Notifications:
 *    - Set admin phone numbers (comma-separated):
 *      ADMIN_NOTIFICATION_PHONES=509-1111-2222,509-3333-4444
 */

require('dotenv').config();

// Load node-fetch if needed for custom gateway
let fetch;
try {
  fetch = require('node-fetch');
} catch (error) {
  // node-fetch not installed, will fail gracefully if custom gateway is used
  console.warn('⚠️  node-fetch not installed, custom SMS gateway will not work');
}

// SMS Provider configuration
const SMS_PROVIDER = process.env.SMS_PROVIDER || 'disabled';

// Twilio configuration
let twilioClient = null;
if (SMS_PROVIDER === 'twilio') {
  try {
    const twilio = require('twilio');
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    
    if (accountSid && authToken) {
      twilioClient = twilio(accountSid, authToken);
      console.log('✅ Twilio SMS service initialized');
    } else {
      console.warn('⚠️  Twilio credentials not configured');
    }
  } catch (error) {
    console.error('❌ Failed to initialize Twilio:', error.message);
    console.log('💡 Install Twilio: npm install twilio');
  }
}

// Custom SMS Gateway configuration
const CUSTOM_SMS_CONFIG = {
  url: process.env.CUSTOM_SMS_GATEWAY_URL,
  apiKey: process.env.CUSTOM_SMS_GATEWAY_API_KEY,
  sender: process.env.CUSTOM_SMS_GATEWAY_SENDER || 'RaffleApp'
};

// Admin notification phone numbers
const ADMIN_PHONES = process.env.ADMIN_NOTIFICATION_PHONES 
  ? process.env.ADMIN_NOTIFICATION_PHONES.split(',').map(p => p.trim())
  : [];

/**
 * Format phone number to E.164 format (for Twilio)
 * Converts formats like:
 * - "509-1234-5678" -> "+5091234567"
 * - "1234567890" -> "+1234567890"
 * - "+1234567890" -> "+1234567890"
 */
function formatPhoneNumber(phone) {
  if (!phone) return null;
  
  // Remove all non-digit characters
  let cleaned = phone.replace(/\D/g, '');
  
  // Add + prefix if not already present in original
  return '+' + cleaned;
}

/**
 * Send SMS via Twilio
 */
async function sendViaTwilio(to, message) {
  if (!twilioClient) {
    throw new Error('Twilio client not initialized');
  }
  
  const fromNumber = process.env.TWILIO_PHONE_NUMBER;
  if (!fromNumber) {
    throw new Error('TWILIO_PHONE_NUMBER not configured');
  }
  
  try {
    const formattedTo = formatPhoneNumber(to);
    const result = await twilioClient.messages.create({
      body: message,
      from: fromNumber,
      to: formattedTo
    });
    
    return {
      success: true,
      messageId: result.sid,
      provider: 'twilio'
    };
  } catch (error) {
    console.error('Twilio SMS error:', error.message);
    throw error;
  }
}

/**
 * Send SMS via Custom Gateway
 */
async function sendViaCustomGateway(to, message) {
  if (!CUSTOM_SMS_CONFIG.url || !CUSTOM_SMS_CONFIG.apiKey) {
    throw new Error('Custom SMS gateway not configured');
  }
  
  if (!fetch) {
    throw new Error('node-fetch not installed, cannot use custom SMS gateway');
  }
  
  try {
    // This is a generic implementation - adjust based on your SMS provider's API
    const response = await fetch(CUSTOM_SMS_CONFIG.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${CUSTOM_SMS_CONFIG.apiKey}`
      },
      body: JSON.stringify({
        to: to,
        from: CUSTOM_SMS_CONFIG.sender,
        message: message
      })
    });
    
    if (!response.ok) {
      throw new Error(`SMS gateway responded with status ${response.status}`);
    }
    
    const data = await response.json();
    
    return {
      success: true,
      messageId: data.id || data.messageId || 'unknown',
      provider: 'custom'
    };
  } catch (error) {
    console.error('Custom SMS gateway error:', error.message);
    throw error;
  }
}

/**
 * Send SMS - Main function
 * 
 * @param {string} to - Phone number to send to
 * @param {string} message - SMS message content
 * @returns {Promise<Object>} Result object with success status
 */
async function sendSMS(to, message) {
  if (!to || !message) {
    throw new Error('Phone number and message are required');
  }
  
  if (SMS_PROVIDER === 'disabled') {
    console.log('📱 SMS (simulated):', { to, message });
    return {
      success: true,
      simulated: true,
      message: 'SMS provider is disabled'
    };
  }
  
  try {
    let result;
    
    if (SMS_PROVIDER === 'twilio') {
      result = await sendViaTwilio(to, message);
    } else if (SMS_PROVIDER === 'custom') {
      result = await sendViaCustomGateway(to, message);
    } else {
      throw new Error(`Unknown SMS provider: ${SMS_PROVIDER}`);
    }
    
    console.log('✅ SMS sent successfully:', { to, provider: result.provider, messageId: result.messageId });
    return result;
  } catch (error) {
    console.error('❌ Failed to send SMS:', error.message);
    
    // Don't throw - log the error but allow the application to continue
    // SMS is a nice-to-have, not critical functionality
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Send payment confirmation SMS to buyer
 * 
 * @param {Object} payment - Payment details
 * @param {string} payment.buyer_phone - Buyer's phone number
 * @param {string} payment.buyer_name - Buyer's name
 * @param {number} payment.amount - Payment amount
 * @param {string} payment.payment_method - Payment method (MonCash, NatCash, Manual)
 * @param {string} payment.reference - Payment reference number
 */
async function sendPaymentConfirmation(payment) {
  const { buyer_phone, buyer_name, amount, payment_method, reference } = payment;
  
  if (!buyer_phone) {
    console.warn('⚠️  Cannot send SMS: buyer phone number not provided');
    return { success: false, error: 'No phone number provided' };
  }
  
  const message = `Hello ${buyer_name || 'Valued Customer'},

Your payment of $${amount.toFixed(2)} via ${payment_method} has been received!

Reference: ${reference}
Status: Payment Confirmed

Your raffle ticket(s) will be assigned shortly.

Thank you for participating!`;
  
  return await sendSMS(buyer_phone, message);
}

/**
 * Send payment pending SMS to buyer (for manual payments)
 * 
 * @param {Object} payment - Payment details
 */
async function sendPaymentPending(payment) {
  const { buyer_phone, buyer_name, amount, payment_method, reference } = payment;
  
  if (!buyer_phone) {
    console.warn('⚠️  Cannot send SMS: buyer phone number not provided');
    return { success: false, error: 'No phone number provided' };
  }
  
  const message = `Hello ${buyer_name || 'Valued Customer'},

We have received your manual payment submission.

Amount: $${amount.toFixed(2)}
Method: ${payment_method}
Reference: ${reference}

Status: Pending Admin Verification

You will receive a confirmation SMS once your payment is verified.

Thank you!`;
  
  return await sendSMS(buyer_phone, message);
}

/**
 * Send payment approved SMS to buyer
 * 
 * @param {Object} payment - Payment details
 */
async function sendPaymentApproved(payment) {
  const { buyer_phone, buyer_name, amount, payment_method, reference, ticket_numbers } = payment;
  
  if (!buyer_phone) {
    console.warn('⚠️  Cannot send SMS: buyer phone number not provided');
    return { success: false, error: 'No phone number provided' };
  }
  
  const ticketInfo = ticket_numbers ? `\nTickets: ${ticket_numbers}` : '';
  
  const message = `Hello ${buyer_name || 'Valued Customer'},

Great news! Your payment has been approved!

Amount: $${amount.toFixed(2)}
Method: ${payment_method}
Reference: ${reference}${ticketInfo}

Status: APPROVED ✓

Good luck in the raffle!`;
  
  return await sendSMS(buyer_phone, message);
}

/**
 * Send payment rejected SMS to buyer
 * 
 * @param {Object} payment - Payment details
 */
async function sendPaymentRejected(payment) {
  const { buyer_phone, buyer_name, amount, payment_method, reference, rejection_reason } = payment;
  
  if (!buyer_phone) {
    console.warn('⚠️  Cannot send SMS: buyer phone number not provided');
    return { success: false, error: 'No phone number provided' };
  }
  
  const reasonText = rejection_reason ? `\nReason: ${rejection_reason}` : '';
  
  const message = `Hello ${buyer_name || 'Valued Customer'},

Unfortunately, we could not verify your payment.

Amount: $${amount.toFixed(2)}
Method: ${payment_method}
Reference: ${reference}${reasonText}

Please contact us for assistance or try again.`;
  
  return await sendSMS(buyer_phone, message);
}

/**
 * Send notification to admins about new payment
 * 
 * @param {Object} payment - Payment details
 */
async function notifyAdminsNewPayment(payment) {
  if (ADMIN_PHONES.length === 0) {
    console.warn('⚠️  No admin phones configured for notifications');
    return { success: false, error: 'No admin phones configured' };
  }
  
  const { buyer_name, amount, payment_method, reference, payment_status } = payment;
  
  const message = `🎫 NEW PAYMENT ${payment_status === 'pending' ? '(NEEDS APPROVAL)' : 'RECEIVED'}

From: ${buyer_name || 'Unknown'}
Amount: $${amount.toFixed(2)}
Method: ${payment_method}
Reference: ${reference}

${payment_status === 'pending' ? 'Action: Please review and approve in admin panel.' : 'Status: Automatically confirmed'}`;
  
  // Send to all admin phones
  const results = await Promise.all(
    ADMIN_PHONES.map(phone => sendSMS(phone, message))
  );
  
  return {
    success: results.some(r => r.success),
    results: results
  };
}

/**
 * Send fraud alert SMS to admins
 * 
 * @param {Object} fraudData - Fraud attempt details
 * @param {string} fraudData.txn_id - Transaction ID involved
 * @param {string} fraudData.seller_name - Seller who attempted fraud
 * @param {string} fraudData.seller_phone - Seller's phone number
 * @param {string} fraudData.fraud_type - Type of fraud detected
 * @param {Object} fraudData.details - Additional fraud details
 */
async function sendFraudAlert(fraudData) {
  const adminPhones = process.env.ADMIN_NOTIFICATION_PHONES?.split(',') || [];
  
  if (adminPhones.length === 0) {
    console.warn('⚠️  No admin phones configured for fraud alerts');
    return { success: false, error: 'No admin phones configured' };
  }
  
  const message = `🚨 FRAUD ALERT

Type: ${fraudData.fraud_type}
Txn ID: ${fraudData.txn_id}
Seller: ${fraudData.seller_name}
Phone: ${fraudData.seller_phone}

Details: ${JSON.stringify(fraudData.details)}

Review admin panel immediately.`;
  
  const results = [];
  for (const phone of adminPhones) {
    if (phone.trim()) {
      try {
        const result = await sendSMS(phone.trim(), message);
        results.push(result);
      } catch (error) {
        console.error(`Failed to send fraud alert to ${phone}:`, error.message);
        results.push({ success: false, error: error.message });
      }
    }
  }
  
  return {
    success: results.some(r => r.success),
    results: results
  };
}

/**
 * Check if SMS service is configured
 */
function isConfigured() {
  if (SMS_PROVIDER === 'disabled') {
    return false;
  }
  
  if (SMS_PROVIDER === 'twilio') {
    return !!(twilioClient && process.env.TWILIO_PHONE_NUMBER);
  }
  
  if (SMS_PROVIDER === 'custom') {
    return !!(CUSTOM_SMS_CONFIG.url && CUSTOM_SMS_CONFIG.apiKey);
  }
  
  return false;
}

module.exports = {
  sendSMS,
  sendPaymentConfirmation,
  sendPaymentPending,
  sendPaymentApproved,
  sendPaymentRejected,
  notifyAdminsNewPayment,
  sendFraudAlert,
  isConfigured
};
