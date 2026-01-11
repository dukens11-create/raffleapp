# MonCash Payment Integration Guide

Complete guide for integrating MonCash and NatCash payment methods into your raffle ticket purchasing flow.

## Table of Contents

1. [Overview](#overview)
2. [Backend Setup](#backend-setup)
3. [Frontend Integration](#frontend-integration)
4. [Payment Flow](#payment-flow)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Overview

This integration supports:
- **Automated MonCash payments** via MonCash API (redirect-based flow)
- **Automated NatCash payments** via NatCash API (push notification flow)
- **Manual MonCash payments** via USSD (*202#) with admin verification
- **Manual NatCash payments** with admin verification

### Merchant Account Details
- **MonCash**: +509 3666 2371
- **NatCash**: +509 3220 4333

---

## Backend Setup

### Step 1: Environment Variables

Add the following environment variables to your `.env` file:

```env
# MonCash API Credentials (Required for automated payments)
MONCASH_CLIENT_ID=your_moncash_client_id_here
MONCASH_CLIENT_SECRET=your_moncash_client_secret_here
MONCASH_MODE=sandbox

# MonCash Merchant Wallet (Required for manual payments)
MONCASH_WALLET_NUMBER=+509 3666 2371

# NatCash API Credentials (Optional)
NATCASH_API_KEY=your_natcash_api_key_here
NATCASH_MERCHANT_ID=your_natcash_merchant_id_here
NATCASH_MODE=sandbox
NATCASH_WALLET_NUMBER=+509 3220 4333
```

### Step 2: Get MonCash API Credentials

1. Visit [https://moncashbutton.digicelgroup.com/](https://moncashbutton.digicelgroup.com/)
2. Create a merchant account
3. Complete KYC verification
4. Navigate to your dashboard
5. Copy your **Client ID** and **Client Secret**
6. **Configure Return URL**: Set your callback URL to `https://yourdomain.com/api/payments/callback`
7. Set `MONCASH_MODE=sandbox` for testing
8. Once approved for production, set `MONCASH_MODE=production`

### Step 3: Available API Endpoints

The backend provides these endpoints:

#### 1. Initiate Purchase (Recommended)
```
POST /api/public/purchase/initiate
```
Atomically allocates tickets and initiates payment in one call.

#### 2. Payment Callback/Return URL
```
GET /api/payments/callback?transactionId={id}
```
MonCash redirects users here after payment completion. Automatically verifies and confirms payment.

#### 3. Manually Verify Payment
```
POST /api/payments/verify/:reference
```
Manually check and update payment status with provider.

#### 4. Check Available Payment Methods
```
GET /api/payments/methods
```
Returns which payment methods are configured and available.

#### 5. Get Payment Status
```
GET /api/payments/status/:reference
```
Check the status of a payment using its reference.

#### 6. Submit Manual Payment
```
POST /api/payments/manual/submit
```
Submit a manual payment reference for admin verification.

#### 7. Get Manual Payment Instructions
```
GET /api/payments/manual-instructions/:method
```
Get step-by-step instructions for manual payments (moncash or natcash).

---

## Frontend Integration

### JavaScript/Vanilla Frontend

Here's a complete example for integrating MonCash payments:

```javascript
/**
 * Complete MonCash Payment Integration Example
 * Works with any JavaScript framework (vanilla, React, Vue, Angular, etc.)
 */

class RafflePaymentIntegration {
  constructor(apiBaseUrl = '') {
    this.apiBaseUrl = apiBaseUrl; // e.g., 'https://your-domain.com' or '' for same origin
  }

  /**
   * Step 1: Check what payment methods are available
   */
  async getAvailablePaymentMethods() {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/payments/methods`);
      const data = await response.json();
      
      if (data.success) {
        console.log('Available payment methods:', data.methods);
        // data.methods = [
        //   { id: 'moncash_api', name: 'MonCash (Automated)', type: 'automated', enabled: true },
        //   { id: 'natcash_api', name: 'NatCash (Automated)', type: 'automated', enabled: true },
        //   { id: 'moncash_manual', name: 'MonCash (USSD/Manual)', type: 'manual', enabled: true },
        //   { id: 'natcash_manual', name: 'NatCash (Manual)', type: 'manual', enabled: true }
        // ]
        return data.methods;
      }
      throw new Error('Failed to get payment methods');
    } catch (error) {
      console.error('Error getting payment methods:', error);
      return [];
    }
  }

  /**
   * Step 2: Check ticket availability
   */
  async getTicketAvailability() {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/public/ticket-availability`);
      const data = await response.json();
      
      if (data.success) {
        console.log('Ticket availability:', data.categories);
        // data.categories = [
        //   { category: 'ABC', available: 95234, total_online: 100000, price: 10.00 },
        //   { category: 'EFG', available: 98756, total_online: 100000, price: 20.00 },
        //   ...
        // ]
        return data.categories;
      }
      throw new Error('Failed to get ticket availability');
    } catch (error) {
      console.error('Error getting ticket availability:', error);
      return [];
    }
  }

  /**
   * Step 3: Initiate purchase with MonCash (Automated)
   */
  async purchaseWithMonCash(purchaseData) {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/public/purchase/initiate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          payment_method: 'moncash',
          buyer_name: purchaseData.buyer_name,
          buyer_phone: purchaseData.buyer_phone,
          buyer_email: purchaseData.buyer_email,
          ticket_category: purchaseData.ticket_category, // ABC, EFG, JKL, or XYZ
          ticket_quantity: purchaseData.ticket_quantity, // 1-10
          customer_department: purchaseData.customer_department // Haitian department
        })
      });

      const data = await response.json();

      if (data.success) {
        console.log('Purchase initiated successfully!');
        console.log('Payment reference:', data.payment_reference);
        console.log('Tickets allocated:', data.tickets_allocated);
        console.log('Amount:', data.amount);
        
        // Redirect user to MonCash payment gateway
        window.location.href = data.payment_details.redirectUrl;
        
        return data;
      } else {
        throw new Error(data.error || 'Purchase failed');
      }
    } catch (error) {
      console.error('Error initiating purchase:', error);
      throw error;
    }
  }

  /**
   * Step 3 (Alternative): Initiate purchase with NatCash (Automated)
   */
  async purchaseWithNatCash(purchaseData) {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/public/purchase/initiate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          payment_method: 'natcash',
          buyer_name: purchaseData.buyer_name,
          buyer_phone: purchaseData.buyer_phone,
          buyer_email: purchaseData.buyer_email,
          ticket_category: purchaseData.ticket_category,
          ticket_quantity: purchaseData.ticket_quantity,
          customer_department: purchaseData.customer_department
        })
      });

      const data = await response.json();

      if (data.success) {
        console.log('Purchase initiated successfully!');
        console.log('Payment reference:', data.payment_reference);
        console.log('Tickets allocated:', data.tickets_allocated);
        console.log('Payment ID:', data.payment_details.paymentId);
        
        // Show success message - user will receive push notification on their phone
        return {
          success: true,
          message: 'Please check your NatCash app for payment request',
          ...data
        };
      } else {
        throw new Error(data.error || 'Purchase failed');
      }
    } catch (error) {
      console.error('Error initiating purchase:', error);
      throw error;
    }
  }

  /**
   * Step 3 (Alternative): Submit manual MonCash payment
   */
  async getManualPaymentInstructions(method = 'moncash') {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/payments/manual-instructions/${method}`);
      const data = await response.json();
      
      if (data.success) {
        console.log('Manual payment instructions:', data.instructions);
        // data.instructions = {
        //   method: 'MonCash',
        //   walletNumber: '+509 3666 2371',
        //   steps: [...],
        //   note: 'Your payment will be verified by our admin team within 24 hours'
        // }
        return data.instructions;
      }
      throw new Error('Failed to get instructions');
    } catch (error) {
      console.error('Error getting instructions:', error);
      return null;
    }
  }

  async submitManualPayment(paymentData) {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/payments/manual/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          payment_method: paymentData.payment_method, // 'moncash' or 'natcash'
          amount: paymentData.amount,
          buyer_name: paymentData.buyer_name,
          buyer_phone: paymentData.buyer_phone,
          buyer_email: paymentData.buyer_email,
          ticket_category: paymentData.ticket_category,
          ticket_quantity: paymentData.ticket_quantity,
          transaction_reference: paymentData.transaction_reference, // User's payment reference
          customer_department: paymentData.customer_department,
          notes: paymentData.notes // Optional notes
        })
      });

      const data = await response.json();

      if (data.success) {
        console.log('Manual payment submitted!');
        console.log('Payment reference:', data.paymentReference);
        console.log('Status:', data.status);
        console.log('Message:', data.message);
        return data;
      } else {
        throw new Error(data.error || 'Failed to submit payment');
      }
    } catch (error) {
      console.error('Error submitting manual payment:', error);
      throw error;
    }
  }

  /**
   * Step 4: Check payment status
   */
  async checkPaymentStatus(paymentReference) {
    try {
      const response = await fetch(`${this.apiBaseUrl}/api/payments/status/${paymentReference}`);
      const data = await response.json();
      
      if (data.success) {
        console.log('Payment status:', data.payment.payment_status);
        // payment_status can be: 'pending', 'approved', 'rejected', 'failed'
        return data.payment;
      }
      throw new Error('Failed to get payment status');
    } catch (error) {
      console.error('Error checking payment status:', error);
      return null;
    }
  }
}

// Usage Example
async function exampleUsage() {
  const payment = new RafflePaymentIntegration('https://your-api.com');
  
  // 1. Check available payment methods
  const methods = await payment.getAvailablePaymentMethods();
  console.log('Payment methods:', methods);
  
  // 2. Check ticket availability
  const availability = await payment.getTicketAvailability();
  console.log('Available tickets:', availability);
  
  // 3. Purchase with MonCash (Automated)
  try {
    await payment.purchaseWithMonCash({
      buyer_name: 'Jean Baptiste',
      buyer_phone: '+509 1234 5678',
      buyer_email: 'jean@example.com',
      ticket_category: 'ABC',
      ticket_quantity: 3,
      customer_department: 'Ouest'
    });
    // User will be redirected to MonCash payment page
  } catch (error) {
    console.error('Purchase failed:', error);
  }
  
  // OR: Submit manual payment
  const instructions = await payment.getManualPaymentInstructions('moncash');
  console.log('Manual payment instructions:', instructions);
  
  await payment.submitManualPayment({
    payment_method: 'moncash',
    amount: 30.00,
    buyer_name: 'Marie Pierre',
    buyer_phone: '+509 8765 4321',
    buyer_email: 'marie@example.com',
    ticket_category: 'ABC',
    ticket_quantity: 3,
    transaction_reference: 'MC123456789', // User's MonCash reference
    customer_department: 'Nord'
  });
}
```

### React Integration Example

```jsx
import React, { useState, useEffect } from 'react';

function TicketPurchaseForm() {
  const [availability, setAvailability] = useState([]);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    buyer_name: '',
    buyer_phone: '',
    buyer_email: '',
    ticket_category: 'ABC',
    ticket_quantity: 1,
    customer_department: 'Ouest',
    payment_method: 'moncash'
  });

  useEffect(() => {
    loadAvailability();
  }, []);

  const loadAvailability = async () => {
    try {
      const response = await fetch('/api/public/ticket-availability');
      const data = await response.json();
      if (data.success) {
        setAvailability(data.categories);
      }
    } catch (error) {
      console.error('Error loading availability:', error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await fetch('/api/public/purchase/initiate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        // Store payment reference for later
        localStorage.setItem('payment_reference', data.payment_reference);
        
        // Redirect to MonCash
        if (data.payment_details.redirectUrl) {
          window.location.href = data.payment_details.redirectUrl;
        } else {
          alert(`Payment submitted! Reference: ${data.payment_reference}`);
        }
      } else {
        alert('Error: ' + (data.error || 'Purchase failed'));
      }
    } catch (error) {
      console.error('Purchase error:', error);
      alert('Failed to initiate purchase');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <h2>Purchase Raffle Tickets</h2>
      
      <div>
        <label>Your Name:</label>
        <input
          type="text"
          value={formData.buyer_name}
          onChange={(e) => setFormData({...formData, buyer_name: e.target.value})}
          required
        />
      </div>

      <div>
        <label>Phone Number:</label>
        <input
          type="tel"
          value={formData.buyer_phone}
          onChange={(e) => setFormData({...formData, buyer_phone: e.target.value})}
          placeholder="+509 1234 5678"
          required
        />
      </div>

      <div>
        <label>Email:</label>
        <input
          type="email"
          value={formData.buyer_email}
          onChange={(e) => setFormData({...formData, buyer_email: e.target.value})}
        />
      </div>

      <div>
        <label>Ticket Category:</label>
        <select
          value={formData.ticket_category}
          onChange={(e) => setFormData({...formData, ticket_category: e.target.value})}
        >
          {availability.map(cat => (
            <option key={cat.category} value={cat.category}>
              {cat.category} - {cat.available} available - ${cat.price} each
            </option>
          ))}
        </select>
      </div>

      <div>
        <label>Quantity (1-10):</label>
        <input
          type="number"
          min="1"
          max="10"
          value={formData.ticket_quantity}
          onChange={(e) => setFormData({...formData, ticket_quantity: parseInt(e.target.value)})}
          required
        />
      </div>

      <div>
        <label>Department:</label>
        <select
          value={formData.customer_department}
          onChange={(e) => setFormData({...formData, customer_department: e.target.value})}
        >
          <option value="Ouest">Ouest</option>
          <option value="Sud">Sud</option>
          <option value="Nord">Nord</option>
          <option value="Artibonite">Artibonite</option>
          <option value="Centre">Centre</option>
          <option value="Grand'Anse">Grand'Anse</option>
          <option value="Nippes">Nippes</option>
          <option value="Nord-Est">Nord-Est</option>
          <option value="Nord-Ouest">Nord-Ouest</option>
          <option value="Sud-Est">Sud-Est</option>
        </select>
      </div>

      <div>
        <label>Payment Method:</label>
        <select
          value={formData.payment_method}
          onChange={(e) => setFormData({...formData, payment_method: e.target.value})}
        >
          <option value="moncash">MonCash (Automated)</option>
          <option value="natcash">NatCash (Automated)</option>
        </select>
      </div>

      <button type="submit" disabled={loading}>
        {loading ? 'Processing...' : 'Purchase Tickets'}
      </button>
    </form>
  );
}

export default TicketPurchaseForm;
```

### Vue.js Integration Example

```vue
<template>
  <div class="ticket-purchase">
    <h2>Purchase Raffle Tickets</h2>
    
    <form @submit.prevent="purchaseTickets">
      <div class="form-group">
        <label>Your Name:</label>
        <input v-model="formData.buyer_name" type="text" required />
      </div>

      <div class="form-group">
        <label>Phone Number:</label>
        <input v-model="formData.buyer_phone" type="tel" placeholder="+509 1234 5678" required />
      </div>

      <div class="form-group">
        <label>Email:</label>
        <input v-model="formData.buyer_email" type="email" />
      </div>

      <div class="form-group">
        <label>Ticket Category:</label>
        <select v-model="formData.ticket_category">
          <option v-for="cat in availability" :key="cat.category" :value="cat.category">
            {{ cat.category }} - {{ cat.available }} available - ${{ cat.price }} each
          </option>
        </select>
      </div>

      <div class="form-group">
        <label>Quantity (1-10):</label>
        <input v-model.number="formData.ticket_quantity" type="number" min="1" max="10" required />
      </div>

      <div class="form-group">
        <label>Department:</label>
        <select v-model="formData.customer_department">
          <option value="Ouest">Ouest</option>
          <option value="Sud">Sud</option>
          <option value="Nord">Nord</option>
          <!-- Add other departments -->
        </select>
      </div>

      <div class="form-group">
        <label>Payment Method:</label>
        <select v-model="formData.payment_method">
          <option value="moncash">MonCash (Automated)</option>
          <option value="natcash">NatCash (Automated)</option>
        </select>
      </div>

      <button type="submit" :disabled="loading">
        {{ loading ? 'Processing...' : 'Purchase Tickets' }}
      </button>
    </form>
  </div>
</template>

<script>
export default {
  name: 'TicketPurchase',
  data() {
    return {
      availability: [],
      loading: false,
      formData: {
        buyer_name: '',
        buyer_phone: '',
        buyer_email: '',
        ticket_category: 'ABC',
        ticket_quantity: 1,
        customer_department: 'Ouest',
        payment_method: 'moncash'
      }
    };
  },
  mounted() {
    this.loadAvailability();
  },
  methods: {
    async loadAvailability() {
      try {
        const response = await fetch('/api/public/ticket-availability');
        const data = await response.json();
        if (data.success) {
          this.availability = data.categories;
        }
      } catch (error) {
        console.error('Error loading availability:', error);
      }
    },
    async purchaseTickets() {
      this.loading = true;
      
      try {
        const response = await fetch('/api/public/purchase/initiate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(this.formData)
        });

        const data = await response.json();

        if (data.success) {
          localStorage.setItem('payment_reference', data.payment_reference);
          
          if (data.payment_details.redirectUrl) {
            window.location.href = data.payment_details.redirectUrl;
          } else {
            alert(`Payment submitted! Reference: ${data.payment_reference}`);
          }
        } else {
          alert('Error: ' + (data.error || 'Purchase failed'));
        }
      } catch (error) {
        console.error('Purchase error:', error);
        alert('Failed to initiate purchase');
      } finally {
        this.loading = false;
      }
    }
  }
};
</script>
```

---

## Payment Flow

### Automated MonCash Payment Flow

1. **User fills out purchase form** with their details and ticket selection
2. **Frontend calls** `POST /api/public/purchase/initiate`
3. **Backend atomically**:
   - Checks ticket availability
   - Reserves tickets (marks as RESERVED)
   - Creates payment record in database
   - Initiates MonCash payment via API
   - Returns payment redirect URL
4. **Frontend redirects user** to MonCash payment gateway
5. **User completes payment** on MonCash website
6. **MonCash redirects back** to your callback URL
7. **Backend verifies payment** with MonCash API
8. **Backend updates**:
   - Payment status → 'approved'
   - Ticket status → 'SOLD'
   - Assigns ticket numbers to buyer
9. **User receives confirmation** via SMS/email

### Manual MonCash Payment Flow

1. **User fills out form** and selects "Manual Payment"
2. **Frontend shows instructions**:
   - Dial *202# on Digicel phone
   - Send money to +509 3666 2371
   - Enter exact amount
   - Save transaction reference
3. **User submits** transaction reference via frontend
4. **Backend creates** payment record with status 'pending'
5. **SMS notifications** sent to:
   - Buyer: "Payment submitted for verification"
   - Admin: "New payment pending approval"
6. **Admin verifies** payment in MonCash account
7. **Admin approves/rejects** payment in admin dashboard
8. **Backend updates** ticket status and sends SMS to buyer

### Manual NatCash Payment Flow

Instructions for NatCash manual payments:

1. **User opens NatCash mobile app**
2. **User transfers money** to +509 3220 4333
3. **User submits** transaction reference via your website
4. **Admin verifies** and approves payment
5. **Backend updates** tickets and sends SMS confirmation

---

## Testing

### Test in Sandbox Mode

1. Set `MONCASH_MODE=sandbox` in `.env`
2. Use MonCash test credentials from their developer portal
3. Test MonCash provides test cards for sandbox

### Test Endpoints

```bash
# 1. Check ticket availability
curl http://localhost:3000/api/public/ticket-availability

# 2. Check payment methods
curl http://localhost:3000/api/payments/methods

# 3. Initiate purchase
curl -X POST http://localhost:3000/api/public/purchase/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "moncash",
    "buyer_name": "Test User",
    "buyer_phone": "+509 1234 5678",
    "buyer_email": "test@example.com",
    "ticket_category": "ABC",
    "ticket_quantity": 2,
    "customer_department": "Ouest"
  }'

# 4. Check payment status
curl http://localhost:3000/api/payments/status/MONCASH-12345-ABC
```

### Production Deployment

Before going live:

1. ✅ Set `MONCASH_MODE=production`
2. ✅ Update to production API credentials
3. ✅ Verify merchant wallet numbers are correct
4. ✅ Test the complete flow with real small amounts
5. ✅ Set up monitoring and logging
6. ✅ Configure SMS notifications
7. ✅ Train admin staff on payment verification

---

## Troubleshooting

### Common Issues

#### "MonCash credentials not configured"
- **Solution**: Verify `MONCASH_CLIENT_ID` and `MONCASH_CLIENT_SECRET` are set in `.env`
- Restart your server after updating `.env`

#### "Insufficient tickets available"
- **Solution**: Check ticket availability with `/api/public/ticket-availability`
- Run database migration to mark last 100K tickets as available online

#### Payment stuck in "pending" status
- **Solution**: Check MonCash transaction status manually
- Verify webhook/callback URL is configured correctly
- Check server logs for API errors

#### User redirected but payment not confirmed
- **Solution**: Implement payment verification endpoint
- Call MonCash verification API after redirect
- Handle pending/failed payment states

### Support

For additional help:
- MonCash Developer Portal: https://moncashbutton.digicelgroup.com/
- Check server logs for detailed error messages
- Contact MonCash support for API issues

---

## Security Notes

⚠️ **Important Security Practices:**

1. ✅ **Never expose API credentials** in frontend code
2. ✅ **Always validate** payment status on backend
3. ✅ **Use HTTPS** in production
4. ✅ **Verify payment amounts** match ticket prices
5. ✅ **Implement rate limiting** on payment endpoints
6. ✅ **Log all payment transactions** for audit trail
7. ✅ **Use environment variables** for all credentials

---

## Additional Resources

- [MonCash API Documentation](https://moncashbutton.digicelgroup.com/)
- [BUYER_PORTAL_API_EXAMPLES.md](./BUYER_PORTAL_API_EXAMPLES.md) - Detailed API examples
- [PAYMENT_INTEGRATION_GUIDE.md](./PAYMENT_INTEGRATION_GUIDE.md) - Comprehensive payment guide
- [.env.example](./.env.example) - Environment variable template

---

Last Updated: January 2026
