# Payment Integration Guide

This document provides comprehensive setup instructions for the payment integration features, including MonCash, NatCash, SMS notifications, and **automated webhook processing**.

## Table of Contents

1. [Overview](#overview)
2. [Payment Methods](#payment-methods)
3. [Setup Instructions](#setup-instructions)
4. [Webhook Integration](#webhook-integration)
5. [Testing](#testing)
6. [Admin Workflow](#admin-workflow)
7. [Troubleshooting](#troubleshooting)
8. [Security Considerations](#security-considerations)
9. [Production Checklist](#production-checklist)

## Overview

The raffle application now supports **automated payment processing with webhooks** for seamless ticket sales:

### Automated Payments with Webhooks ✨ NEW
- **MonCash API**: Automated payments with webhook callbacks for instant confirmation
- **NatCash API**: Automated payments with webhook callbacks for instant confirmation
- **Zero Manual Intervention**: Payments are automatically verified and tickets assigned
- **Real-time Processing**: Webhook notifications trigger immediate ticket assignment
- **SMS Confirmations**: Buyers receive instant confirmation messages

### Manual Payments
- **MonCash USSD/Manual**: Buyers make payments via USSD (*202#) or mobile app and submit reference for admin verification
- **NatCash Manual**: Buyers make payments via NatCash app and submit reference for admin verification

All payment methods include **SMS notifications** to keep buyers and admins informed.

## Payment Methods

### 1. MonCash Integration

#### Automated (API-based)
- Instant payment processing
- Redirects buyers to MonCash payment gateway
- Automatic confirmation and ticket assignment
- Real-time status updates

#### Manual/USSD
- Buyers use USSD code (*202#) or MonCash app
- Submit transaction reference for verification
- Admin approves/rejects within 24 hours
- SMS notifications on approval

### 2. NatCash Integration

#### Automated (API-based)
- Instant payment processing
- Payment request sent to buyer's phone
- Automatic confirmation and ticket assignment

#### Manual
- Buyers use NatCash mobile app
- Submit transaction reference for verification
- Admin approves/rejects within 24 hours
- SMS notifications on approval

### 3. SMS Notifications

SMS notifications are sent for:
- Payment submission confirmation
- Payment approval
- Payment rejection (with reason)
- Admin alerts for new payments

## Webhook Integration

### How Webhooks Work

Webhooks enable **automated payment processing** without admin intervention:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTOMATED PAYMENT FLOW                        │
└─────────────────────────────────────────────────────────────────┘

1. Buyer initiates payment
   ↓
2. App creates payment record (status: pending)
   ↓
3. Buyer redirected to MonCash/NatCash gateway
   ↓
4. Buyer completes payment
   ↓
5. Payment gateway sends webhook to app ← AUTOMATIC
   ↓
6. App verifies webhook signature
   ↓
7. App checks payment status
   ↓
8. If successful:
   - Update payment status to "approved"
   - Assign tickets automatically
   - Send SMS confirmation to buyer
   ↓
9. Return 200 OK to gateway
   ↓
✓ Complete - No admin action needed!
```

### Webhook Security

Webhooks use **HMAC-SHA256 signatures** to ensure authenticity:

1. **Payment Provider Signs Webhook:**
   - Creates HMAC signature of payload using shared secret
   - Includes signature in HTTP header

2. **Your App Verifies Signature:**
   - Recreates HMAC signature using same secret
   - Compares signatures to verify authenticity
   - Rejects webhooks with invalid signatures

3. **Idempotency Protection:**
   - Checks payment status before processing
   - Prevents duplicate ticket assignments
   - Logs all webhook attempts for auditing

### Webhook Endpoints

- **MonCash:** `POST /api/webhooks/moncash`
- **NatCash:** `POST /api/webhooks/natcash`

Both endpoints:
- Accept JSON payloads
- Verify signatures
- Process payments automatically
- Always return 200 OK (prevents retries)
- Log all events comprehensively

### Key Features

✅ **Automatic Verification** - No admin approval needed
✅ **Instant Ticket Assignment** - Tickets assigned in seconds
✅ **Duplicate Prevention** - Idempotent processing
✅ **SMS Notifications** - Buyers notified immediately
✅ **Comprehensive Logging** - Full audit trail
✅ **Error Handling** - Graceful failure recovery
✅ **Security** - Signature verification required

## Setup Instructions

### Step 1: Install Dependencies

```bash
cd raffle-app
npm install node-fetch@2.7.0 twilio@5.4.0
```

### Step 2: Configure Environment Variables

Copy the `.env.example` file to create your `.env`:

```bash
cp .env.example .env
```

Edit `.env` and configure the following sections:

#### A. MonCash Configuration

```env
# Get credentials from https://moncashbutton.digicelgroup.com/
MONCASH_CLIENT_ID=your-moncash-client-id
MONCASH_SECRET_KEY=your-moncash-secret-key
MONCASH_MODE=sandbox
# Use 'sandbox' for testing, 'production' for live

# Your business MonCash wallet number (for manual payments)
MONCASH_WALLET_NUMBER=509-1234-5678
```

**How to Get MonCash Credentials:**
1. Visit https://moncashbutton.digicelgroup.com/
2. Create a merchant account
3. Complete KYC verification
4. Navigate to API section in dashboard
5. Copy your Client ID and Secret Key
6. Start with sandbox mode for testing

#### B. NatCash Configuration

```env
# Contact NatCash for API credentials
NATCASH_API_KEY=your-natcash-api-key
NATCASH_MERCHANT_ID=your-natcash-merchant-id
NATCASH_MODE=sandbox

# Your business NatCash wallet number (for manual payments)
NATCASH_WALLET_NUMBER=509-8765-4321
```

**How to Get NatCash Credentials:**
1. Contact NatCash directly for merchant account
2. Request API access
3. Complete merchant verification
4. Receive API credentials via email
5. Configure in your environment

#### C. SMS Notifications (Twilio)

```env
# Get from https://www.twilio.com/console
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# Which SMS provider to use: twilio, custom, or disabled
SMS_PROVIDER=twilio

# Admin phones for notifications (comma-separated)
ADMIN_NOTIFICATION_PHONES=509-1111-2222,509-3333-4444
```

**How to Set Up Twilio:**
1. Sign up at https://www.twilio.com
2. Verify your account (free trial available)
3. Get a phone number from Twilio Console
4. Navigate to Account > API keys & tokens
5. Copy Account SID and Auth Token
6. Add credit to your account for production use

**Free Trial Notes:**
- Twilio offers $15 free credit for testing
- You can send SMS to verified numbers during trial
- Upgrade for full production access

#### D. Alternative SMS Provider (Custom Gateway)

If you're using a local SMS provider instead of Twilio:

```env
SMS_PROVIDER=custom
CUSTOM_SMS_GATEWAY_URL=https://your-sms-gateway.com/send
CUSTOM_SMS_GATEWAY_API_KEY=your-api-key
CUSTOM_SMS_GATEWAY_SENDER=RaffleApp
```

**Note:** The custom gateway implementation assumes a REST API. You may need to modify `raffle-app/services/smsService.js` to match your provider's API format.

#### E. Webhook Configuration (For Automated Payments)

```env
# Base URL for webhook callbacks - your deployed server URL
WEBHOOK_BASE_URL=https://yourdomain.com

# Webhook Secrets for signature verification
# Generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
MONCASH_WEBHOOK_SECRET=your-moncash-webhook-secret
NATCASH_WEBHOOK_SECRET=your-natcash-webhook-secret
```

**How to Set Up Webhooks:**

1. **Generate Webhook Secrets:**
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
   Generate two secrets - one for MonCash, one for NatCash

2. **Configure Base URL:**
   - For local testing: `http://localhost:10000` (or use ngrok)
   - For production: `https://yourdomain.com` or `https://your-app.onrender.com`

3. **Register Webhook URLs with Payment Providers:**
   - **MonCash Webhook URL:** `https://yourdomain.com/api/webhooks/moncash`
   - **NatCash Webhook URL:** `https://yourdomain.com/api/webhooks/natcash`
   
   Register these URLs in your MonCash and NatCash merchant dashboards
   
4. **Configure Webhook Secrets:**
   - Share your webhook secrets with MonCash and NatCash support
   - They will use these to sign webhook payloads
   - Keep these secrets confidential!

**Local Testing with ngrok:**

For local webhook testing before deployment:

```bash
# Install ngrok
npm install -g ngrok

# Start your server
npm start

# In another terminal, expose your local server
ngrok http 10000
```

Copy the HTTPS URL from ngrok (e.g., `https://abc123.ngrok.io`) and use it as your `WEBHOOK_BASE_URL`.

#### F. Disable SMS (Optional)

If you want to disable SMS notifications temporarily:

```env
SMS_PROVIDER=disabled
```

SMS sending will be simulated (logged to console only).

### Step 3: Database Migration

The payments table with webhook tracking columns is automatically created when you start the server. No manual migration needed.

### Step 4: Start the Server

```bash
npm start
```

Check the console output for:
- ✅ SMS service initialization
- ✅ Payment methods configured
- ✅ Database tables created
- ✅ Webhook tracking columns added

### Step 5: Verify Setup

1. **Check Payment Methods:**
   Visit: `http://localhost:3000/buyers.html`
   - Click "Purchase Tickets" tab
   - You should see available payment methods

2. **Check Admin Interface:**
   Visit: `http://localhost:3000/payments-admin.html`
   - Login with admin credentials
   - Should see payment management dashboard

3. **Test Webhook Endpoints:**
   ```bash
   # Test MonCash webhook (should respond with error about missing signature)
   curl -X POST http://localhost:10000/api/webhooks/moncash \
        -H "Content-Type: application/json" \
        -d '{"test": "ping"}'
   
   # Should return: {"success":false,"error":"Missing order_id"}
   ```

## Testing

### Test MonCash Sandbox

1. Use sandbox credentials from MonCash developer portal
2. Go to Buyers Dashboard → Purchase Tickets
3. Fill in buyer information
4. Select "MonCash (Automated)"
5. Complete payment on sandbox gateway
6. Verify ticket assignment

### Test Manual Payment Flow

1. Go to Buyers Dashboard → Purchase Tickets
2. Select "MonCash (USSD/Manual)" or "NatCash (Manual)"
3. Note the wallet number displayed
4. **Make a real test payment** to your wallet (small amount)
5. Submit the transaction reference
6. Check admin panel at `/payments-admin.html`
7. Approve the payment
8. Verify SMS notifications (if configured)
9. Verify ticket assignment

### Test SMS Notifications

**Option 1: Using Twilio (Recommended)**
1. Configure Twilio credentials
2. Add your phone number to `ADMIN_NOTIFICATION_PHONES`
3. Submit a test payment
4. Check for SMS on your phone

**Option 2: Simulation Mode**
1. Set `SMS_PROVIDER=disabled`
2. Submit a test payment
3. Check server console logs for simulated SMS

### Test Webhook Processing

#### Test MonCash Webhook (Local)

1. **Start your server with webhook configuration:**
   ```bash
   # In .env
   WEBHOOK_BASE_URL=http://localhost:10000
   MONCASH_WEBHOOK_SECRET=test_secret_12345
   ```

2. **Create a test payment:**
   - Use the MonCash payment initiation endpoint
   - Note the payment reference (orderId)

3. **Simulate webhook callback:**
   ```bash
   # Create HMAC signature
   node -e "
   const crypto = require('crypto');
   const payload = JSON.stringify({
     orderId: 'PAY-XXX-YYY',
     transactionId: 'MONCASH-12345',
   amount: 100.00,
     status: 'success'
   });
   const signature = crypto.createHmac('sha256', 'test_secret_12345')
     .update(payload)
     .digest('hex');
   console.log('Signature:', signature);
   console.log('Payload:', payload);
   "
   
   # Send webhook with signature
   curl -X POST http://localhost:10000/api/webhooks/moncash \
        -H "Content-Type: application/json" \
        -H "X-MonCash-Signature: YOUR_SIGNATURE_HERE" \
        -d '{
          "orderId": "PAY-XXX-YYY",
          "transactionId": "MONCASH-12345",
          "amount": 100.00,
          "status": "success"
        }'
   ```

4. **Verify Processing:**
   - Check server console for webhook logs
   - Verify payment status changed to "approved"
   - Verify tickets were assigned
   - Check for SMS notifications

#### Test NatCash Webhook (Local)

Same process as MonCash, but use:
- Endpoint: `/api/webhooks/natcash`
- Header: `X-NatCash-Signature`
- Secret: `NATCASH_WEBHOOK_SECRET`

#### Test Webhook with ngrok (Production-like)

1. **Start ngrok:**
   ```bash
   ngrok http 10000
   ```

2. **Update webhook URL:**
   ```env
   WEBHOOK_BASE_URL=https://abc123.ngrok.io
   ```

3. **Register webhook with provider:**
   - Go to MonCash/NatCash merchant dashboard
   - Register: `https://abc123.ngrok.io/api/webhooks/moncash`
   - Configure webhook secret

4. **Make real test payment:**
   - Use sandbox credentials
   - Complete payment through gateway
   - Provider will automatically call your webhook
   - Monitor ngrok dashboard for incoming requests

5. **Monitor logs:**
   ```bash
   # Terminal 1: Server logs
   npm start
   
   # Terminal 2: ngrok dashboard
   # Visit: http://localhost:4040
   ```

### Webhook Payload Examples

#### MonCash Webhook Payload (Success)

```json
{
  "transactionId": "MONCASH-TXN-123456789",
  "orderId": "PAY-123ABC456",
  "amount": 100.00,
  "status": "success",
  "payer": "50912345678",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### MonCash Webhook Payload (Failed)

```json
{
  "transactionId": "MONCASH-TXN-987654321",
  "orderId": "PAY-789XYZ012",
  "amount": 100.00,
  "status": "failed",
  "payer": "50912345678",
  "timestamp": "2024-01-15T10:35:00Z",
  "error": "Insufficient funds"
}
```

#### NatCash Webhook Payload (Success)

```json
{
  "paymentId": "NATCASH-PAY-123456",
  "orderId": "PAY-456DEF789",
  "amount": 100.00,
  "status": "completed",
  "transactionRef": "NATCASH-REF-789",
  "phone": "50998765432",
  "timestamp": "2024-01-15T11:00:00Z"
}
```

#### NatCash Webhook Payload (Failed)

```json
{
  "paymentId": "NATCASH-PAY-654321",
  "orderId": "PAY-321GHI654",
  "amount": 100.00,
  "status": "cancelled",
  "transactionRef": "NATCASH-REF-456",
  "phone": "50998765432",
  "timestamp": "2024-01-15T11:05:00Z",
  "reason": "User cancelled"
}
```


## Admin Workflow

### Accessing Payment Management

1. Login to admin dashboard
2. Visit: `http://your-domain.com/payments-admin.html`
3. Or add a link to your admin.html navigation

### Reviewing Pending Payments

1. **Pending Approval Tab** shows all unverified manual payments
2. Each payment displays:
   - Payment reference
   - Buyer name and contact
   - Payment method and amount
   - Ticket category and quantity
   - Submission date

### Approving Payments

1. Click "✅ Approve" on a pending payment
2. Review payment details in modal
3. Click "Confirm Approval"
4. System automatically:
   - Assigns available tickets to buyer
   - Updates payment status to "approved"
   - Sends SMS confirmation to buyer
   - Records admin who approved

### Rejecting Payments

1. Click "❌ Reject" on a pending payment
2. Enter rejection reason (required)
3. Click "Confirm Rejection"
4. System automatically:
   - Updates payment status to "rejected"
   - Sends SMS to buyer with reason
   - Records admin who rejected

### Best Practices

- **Verify transaction references** with your payment provider before approving
- **Check ticket availability** before approving (system checks automatically)
- **Provide clear rejection reasons** to help buyers understand issues
- **Process payments within 24 hours** to maintain buyer satisfaction
- **Keep records** of unusual transactions for auditing

## Payment Flow Diagrams

### Automated Payment Flow

```
Buyer fills form → Selects automated method (MonCash/NatCash API)
    ↓
Payment initiated → Redirect to payment gateway
    ↓
Buyer completes payment → Payment confirmed
    ↓
System auto-assigns tickets → SMS sent to buyer
    ↓
Complete ✓
```

### Manual Payment Flow

```
Buyer fills form → Selects manual method
    ↓
System shows wallet number + instructions
    ↓
Buyer makes payment via USSD/App
    ↓
Buyer submits transaction reference → Payment stored as "pending"
    ↓
SMS sent to buyer: "Pending verification"
SMS sent to admins: "New payment awaits approval"
    ↓
Admin reviews payment → Approves/Rejects
    ↓
If Approved:
  - Tickets assigned
  - SMS: "Payment approved + ticket numbers"
If Rejected:
  - SMS: "Payment rejected + reason"
    ↓
Complete ✓
```

## API Endpoints

### Public Endpoints

- `GET /api/payments/methods` - Get available payment methods
- `POST /api/payments/moncash/initiate` - Initiate MonCash payment
- `POST /api/payments/natcash/initiate` - Initiate NatCash payment
- `POST /api/payments/manual/submit` - Submit manual payment
- `GET /api/payments/status/:reference` - Check payment status
- `GET /api/payments/manual-instructions/:method` - Get payment instructions

### Admin Endpoints (Require Authentication)

- `GET /api/admin/payments/pending` - List pending payments
- `POST /api/admin/payments/approve` - Approve a payment
- `POST /api/admin/payments/reject` - Reject a payment

## Troubleshooting

### Issue: Payment methods not showing

**Solution:**
1. Check environment variables are set correctly
2. Verify at least one payment method is configured
3. Check console for errors on page load
4. Restart server after changing .env

### Issue: MonCash redirects failing

**Solution:**
1. Verify MONCASH_CLIENT_ID and MONCASH_SECRET_KEY are correct
2. Check MONCASH_MODE is set to "sandbox" for testing
3. Ensure your server is accessible (not localhost for production)
4. Check MonCash dashboard for API logs

### Issue: SMS not sending

**Solution:**
1. Verify SMS_PROVIDER is set correctly
2. Check Twilio credentials if using Twilio
3. Verify phone numbers are in correct format (+509...)
4. Check Twilio account balance
5. Review console logs for error messages
6. Test with `SMS_PROVIDER=disabled` to isolate issue

### Issue: Admin approval failing

**Solution:**
1. Check if enough tickets are available in category
2. Verify admin is logged in
3. Check browser console for JavaScript errors
4. Check server logs for database errors

### Issue: Database table not created

**Solution:**
1. Restart the server to trigger schema initialization
2. Check database connection is working
3. Check server logs for SQL errors
4. Verify DATABASE_URL is set correctly

### Issue: Webhooks not receiving callbacks

**Solution:**
1. **Check Webhook URL Configuration:**
   - Verify `WEBHOOK_BASE_URL` is set correctly in .env
   - URL must be publicly accessible (not localhost)
   - Use ngrok for local testing

2. **Verify Webhook Registration:**
   - Confirm webhook URLs are registered with MonCash/NatCash
   - Check merchant dashboard for webhook settings
   - Verify webhook URLs are correct (no typos)

3. **Check Server Accessibility:**
   ```bash
   # Test if webhook endpoint is reachable
   curl -X POST https://yourdomain.com/api/webhooks/moncash \
        -H "Content-Type: application/json" \
        -d '{"test": "ping"}'
   ```

4. **Review Firewall/Security Settings:**
   - Ensure port 443/80 is open
   - Check if hosting provider blocks incoming webhooks
   - Whitelist payment gateway IPs if needed

### Issue: Webhook signature verification failing

**Solution:**
1. **Check Webhook Secrets:**
   - Verify secrets are configured correctly in .env
   - Confirm secrets match what's registered with provider
   - Ensure no extra spaces or quotes in .env

2. **Review Signature Headers:**
   - Check server logs for incoming signature header
   - Verify header name matches expectations
   - MonCash typically uses: `X-MonCash-Signature`
   - NatCash typically uses: `X-NatCash-Signature`

3. **Validate Payload Format:**
   ```bash
   # Test signature generation
   node -e "
   const crypto = require('crypto');
   const secret = 'your-webhook-secret';
   const payload = JSON.stringify({test: 'data'});
   const sig = crypto.createHmac('sha256', secret).update(payload).digest('hex');
   console.log('Signature:', sig);
   "
   ```

4. **Temporarily Disable Verification:**
   - For debugging only, comment out secret in .env
   - Check if webhook processes successfully
   - Re-enable verification after debugging

### Issue: Payment processed but tickets not assigned

**Solution:**
1. **Check Ticket Availability:**
   - Verify tickets exist for requested category
   - Check if tickets are marked as AVAILABLE
   - Review `tickets` table in database

2. **Review Server Logs:**
   ```bash
   # Check for errors during ticket assignment
   grep "webhook" server.log | tail -50
   grep "Payment processed" server.log | tail -20
   ```

3. **Verify Payment Status:**
   - Check `payments` table for payment record
   - Verify `payment_status` is 'approved'
   - Check `ticket_numbers` field is populated

4. **Check Webhook Processing:**
   - Look for errors in `processWebhookPayment` function
   - Verify database transaction completed
   - Check for race conditions (multiple webhooks)

### Issue: Duplicate webhook deliveries

**Solution:**
1. **Idempotency Built-in:**
   - System automatically detects duplicate payments
   - Checks `payment_status` before processing
   - Logs duplicate attempts

2. **Verify Duplicate Detection:**
   ```sql
   -- Check payment status
   SELECT payment_reference, payment_status, webhook_attempts, webhook_received_at
   FROM payments
   WHERE payment_reference = 'PAY-XXX-YYY';
   ```

3. **Review Webhook Logs:**
   - Check `webhook_attempts` counter in database
   - Review `webhook_payload` for differences
   - Confirm no tickets were assigned twice

### Issue: Webhooks work in sandbox but not production

**Solution:**
1. **Update Credentials:**
   - Switch to production API credentials
   - Update `MONCASH_MODE` to 'production'
   - Update `NATCASH_MODE` to 'production'

2. **Re-register Webhooks:**
   - Register production webhook URLs
   - Use production webhook secrets
   - Test with small real payment

3. **Check Production Environment:**
   - Verify SSL certificate is valid
   - Ensure HTTPS is enabled
   - Check production server logs

4. **Monitor Gateway Dashboard:**
   - Check payment provider's dashboard
   - Look for webhook delivery failures
   - Review error messages from provider

## Security Considerations

1. **Never commit API keys** to version control
2. **Use environment variables** for all sensitive credentials
3. **Enable HTTPS** in production
4. **Validate payment amounts** match ticket prices
5. **Log all transactions** for audit trails
6. **Implement rate limiting** on payment endpoints
7. **Verify webhook signatures** from payment providers
8. **Use strong admin passwords**
9. **Regularly backup** payment database

## Production Checklist

Before going live:

- [ ] All API credentials configured for production
- [ ] SMS provider configured and tested
- [ ] Payment methods tested with real transactions
- [ ] Admin approval workflow tested
- [ ] HTTPS enabled on server
- [ ] Database properly configured (PostgreSQL recommended)
- [ ] **Webhook URLs registered with payment providers**
- [ ] **Webhook secrets configured and shared with providers**
- [ ] **Webhook endpoints tested with sandbox**
- [ ] **WEBHOOK_BASE_URL set to production domain**
- [ ] **Webhook signature verification tested**
- [ ] **Automated payment flow tested end-to-end**
- [ ] Backup strategy in place
- [ ] Monitoring and logging configured
- [ ] Admin team trained on approval process
- [ ] Error handling tested
- [ ] Phone numbers in correct international format
- [ ] **Webhook failure alerts configured**
- [ ] Backup strategy in place
- [ ] Monitoring and logging configured
- [ ] Admin team trained on approval process
- [ ] Error handling tested
- [ ] Phone numbers in correct international format

## Support

For issues or questions:

1. Check this documentation first
2. Review console logs for errors
3. Test in sandbox/disabled mode
4. Contact payment provider support for API issues
5. Open a GitHub issue with details

## Additional Resources

- [MonCash API Documentation](https://moncashbutton.digicelgroup.com/docs)
- [Twilio SMS Documentation](https://www.twilio.com/docs/sms)
- [Node-Fetch Documentation](https://github.com/node-fetch/node-fetch)

## Version History

- v1.0 - Initial payment integration with MonCash, NatCash, and SMS notifications
