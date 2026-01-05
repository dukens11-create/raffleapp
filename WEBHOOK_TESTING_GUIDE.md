# Webhook Testing Guide

This guide provides step-by-step instructions for testing the webhook integration for MonCash and NatCash payment gateways.

## Quick Start

### 1. Install Dependencies

```bash
cd raffle-app
npm install
```

### 2. Configure Environment

Create `.env` file (copy from `.env.example`):

```env
# Webhook Configuration
WEBHOOK_BASE_URL=http://localhost:10000
MONCASH_WEBHOOK_SECRET=test_moncash_secret_12345
NATCASH_WEBHOOK_SECRET=test_natcash_secret_67890

# Payment Gateway (Sandbox Mode)
MONCASH_CLIENT_ID=your-sandbox-client-id
MONCASH_SECRET_KEY=your-sandbox-secret-key
MONCASH_MODE=sandbox

# SMS (Optional - can be disabled for testing)
SMS_PROVIDER=disabled
```

### 3. Start the Server

```bash
npm start
```

Expected output:
```
✅ Database schema initialized successfully
✅ Webhook tracking columns verified for payments table
Server is running on port 10000
```

## Local Testing (Without Payment Gateway)

### Test 1: Verify Endpoints are Accessible

```bash
# Test MonCash webhook endpoint
curl -X POST http://localhost:10000/api/webhooks/moncash \
     -H "Content-Type: application/json" \
     -d '{"test": "ping"}'

# Expected: {"success":false,"error":"Missing order_id"}
```

```bash
# Test NatCash webhook endpoint
curl -X POST http://localhost:10000/api/webhooks/natcash \
     -H "Content-Type: application/json" \
     -d '{"test": "ping"}'

# Expected: {"success":false,"error":"Missing order_id"}
```

### Test 2: Signature Verification

Generate a valid signature:

```bash
node -e "
const crypto = require('crypto');
const payload = JSON.stringify({
  orderId: 'PAY-TEST-123',
  transactionId: 'MONCASH-TXN-456',
  amount: 100.00,
  status: 'success'
});
const signature = crypto.createHmac('sha256', 'test_moncash_secret_12345')
  .update(payload)
  .digest('hex');
console.log('Payload:', payload);
console.log('Signature:', signature);
"
```

Send webhook with signature:

```bash
curl -X POST http://localhost:10000/api/webhooks/moncash \
     -H "Content-Type: application/json" \
     -H "X-MonCash-Signature: YOUR_SIGNATURE_HERE" \
     -d '{
       "orderId": "PAY-TEST-123",
       "transactionId": "MONCASH-TXN-456",
       "amount": 100.00,
       "status": "success"
     }'
```

Check server logs for:
```
✅ MonCash webhook signature verified
```

### Test 3: End-to-End Payment Flow

1. **Create a test payment in the database:**

```bash
# Connect to your database and insert a test payment
# SQLite example:
sqlite3 raffle-app/raffle.db

INSERT INTO payments (
  raffle_id, payment_reference, payment_method, payment_type,
  amount, buyer_name, buyer_email, buyer_phone,
  ticket_category, ticket_quantity, payment_status
) VALUES (
  1, 'PAY-TEST-E2E', 'MonCash', 'automated',
  100.00, 'Test Buyer', 'test@example.com', '50912345678',
  'ABC', 2, 'pending'
);
```

2. **Ensure available tickets exist:**

```sql
-- Check available tickets
SELECT COUNT(*) FROM tickets 
WHERE category = 'ABC' AND status = 'AVAILABLE';

-- If none, create some test tickets
INSERT INTO tickets (raffle_id, ticket_number, category, price, status)
VALUES 
  (1, 'ABC-TEST-001', 'ABC', 50.00, 'AVAILABLE'),
  (1, 'ABC-TEST-002', 'ABC', 50.00, 'AVAILABLE');
```

3. **Send webhook for the payment:**

```bash
# Generate signature
node -e "
const crypto = require('crypto');
const payload = JSON.stringify({
  orderId: 'PAY-TEST-E2E',
  transactionId: 'MONCASH-E2E-789',
  amount: 100.00,
  status: 'success'
});
const sig = crypto.createHmac('sha256', 'test_moncash_secret_12345').update(payload).digest('hex');
console.log('curl -X POST http://localhost:10000/api/webhooks/moncash \\\\');
console.log('     -H \"Content-Type: application/json\" \\\\');
console.log('     -H \"X-MonCash-Signature: ' + sig + '\" \\\\');
console.log('     -d \\'' + payload + '\\'');
"
```

4. **Verify results:**

```sql
-- Check payment status
SELECT payment_reference, payment_status, ticket_numbers, webhook_attempts
FROM payments 
WHERE payment_reference = 'PAY-TEST-E2E';

-- Should show: payment_status = 'approved', ticket_numbers populated

-- Check tickets assigned
SELECT ticket_number, status, buyer_name, buyer_phone
FROM tickets 
WHERE ticket_number IN ('ABC-TEST-001', 'ABC-TEST-002');

-- Should show: status = 'SOLD', buyer info populated
```

## Testing with ngrok (Production-like)

### Setup

1. **Install ngrok:**

```bash
npm install -g ngrok
```

2. **Start your server:**

```bash
npm start
```

3. **Start ngrok in another terminal:**

```bash
ngrok http 10000
```

4. **Update WEBHOOK_BASE_URL:**

Copy the HTTPS URL from ngrok (e.g., `https://abc123.ngrok.io`) and update `.env`:

```env
WEBHOOK_BASE_URL=https://abc123.ngrok.io
```

5. **Restart server** to pick up new URL.

### Monitor Webhooks

1. **ngrok dashboard:** Visit `http://localhost:4040` to see incoming requests

2. **Server logs:** Watch your server terminal for webhook processing logs

### Test with External Webhook Sender

Use a webhook testing tool like webhook.site:

1. Visit https://webhook.site
2. Note your unique URL
3. Send a test webhook manually
4. Verify the payload format

Then send the same webhook to your ngrok URL:

```bash
curl -X POST https://YOUR-NGROK-URL.ngrok.io/api/webhooks/moncash \
     -H "Content-Type: application/json" \
     -H "X-MonCash-Signature: SIGNATURE" \
     -d '{"orderId": "PAY-XXX", "amount": 100, "status": "success"}'
```

## Testing with Sandbox Payment Gateway

### MonCash Sandbox

1. **Configure sandbox credentials** in `.env`:

```env
MONCASH_CLIENT_ID=your-sandbox-client-id
MONCASH_SECRET_KEY=your-sandbox-secret-key
MONCASH_MODE=sandbox
WEBHOOK_BASE_URL=https://your-ngrok-url.ngrok.io
```

2. **Register webhook in MonCash dashboard:**
   - Login to https://sandbox.moncashbutton.digicelgroup.com
   - Navigate to Webhooks section
   - Add: `https://your-ngrok-url.ngrok.io/api/webhooks/moncash`
   - Configure webhook secret

3. **Test payment flow:**
   - Use the app to initiate a payment
   - Complete payment in sandbox
   - Watch webhook arrive automatically

### NatCash Sandbox

1. **Configure sandbox credentials** in `.env`

2. **Register webhook URL with NatCash**

3. **Test payment flow**

## Common Issues and Solutions

### Issue: Signature verification failing

**Solution:**
```bash
# Verify your secret matches
echo $MONCASH_WEBHOOK_SECRET

# Test signature generation
node -e "
const crypto = require('crypto');
const secret = 'your-secret-here';
const data = JSON.stringify({test: 'data'});
console.log(crypto.createHmac('sha256', secret).update(data).digest('hex'));
"
```

### Issue: Payment not found

**Solution:**
```sql
-- Verify payment exists
SELECT * FROM payments WHERE payment_reference = 'PAY-XXX';

-- Check exact reference in webhook payload
```

### Issue: Not enough tickets available

**Solution:**
```sql
-- Check available tickets
SELECT COUNT(*) FROM tickets 
WHERE category = 'ABC' AND status = 'AVAILABLE';

-- Generate more tickets if needed
```

### Issue: Webhook not reaching server

**Solution:**
1. Check ngrok is running: `curl https://your-url.ngrok.io/health`
2. Verify firewall allows incoming connections
3. Check webhook URL registered with gateway
4. Review ngrok dashboard for blocked requests

## Verification Checklist

After testing, verify:

- [ ] Webhook endpoints respond to POST requests
- [ ] Signature verification works correctly
- [ ] Invalid signatures are rejected
- [ ] Payment status updates to 'approved'
- [ ] Tickets are assigned correctly
- [ ] Buyer information is saved
- [ ] SMS notifications sent (if enabled)
- [ ] Webhook attempts are logged
- [ ] Duplicate webhooks are handled
- [ ] Server logs show complete processing flow
- [ ] Database has all webhook tracking data

## Debug Commands

View recent webhook attempts:

```sql
SELECT 
  payment_reference,
  payment_status,
  webhook_attempts,
  webhook_received_at,
  ticket_numbers
FROM payments
WHERE payment_type = 'automated'
ORDER BY webhook_received_at DESC
LIMIT 10;
```

Check server logs:

```bash
# If using PM2
pm2 logs

# If running directly
# Check your terminal output
```

Enable verbose logging:

```env
DEBUG_MODE=true
```

## Success Indicators

You'll know webhooks are working when you see:

```
═══════════════════════════════════════
📥 MONCASH WEBHOOK RECEIVED
═══════════════════════════════════════
✅ MonCash webhook signature verified
📝 Normalized payment data: {...}
📥 Processing webhook payment: PAY-XXX-YYY from moncash
✅ Payment successful: PAY-XXX-YYY
✅ Tickets assigned: ABC-001, ABC-002
✅ SMS confirmation sent to buyer
✅ MonCash webhook processed
═══════════════════════════════════════
```

## Next Steps

Once local testing is complete:

1. Test with sandbox payment gateway
2. Verify end-to-end flow with real sandbox payments
3. Configure production credentials
4. Register production webhook URLs
5. Test with small real payments
6. Monitor production webhooks closely
7. Set up alerting for webhook failures

## Support

If you encounter issues:

1. Check server logs for errors
2. Verify environment variables are set
3. Review this guide's troubleshooting section
4. Check the PAYMENT_INTEGRATION_GUIDE.md
5. Verify database schema is up to date
