# Quick Start Guide - Payment Integration Testing

This guide helps you quickly test the new payment features.

## Prerequisites

1. Node.js installed
2. Repository cloned
3. Dependencies installed: `npm install`

## Quick Test Setup (5 Minutes)

### Option 1: Test Without External Services (Fastest)

This tests the UI and basic flow without requiring API credentials.

1. **Set SMS to disabled mode:**
```bash
echo "SMS_PROVIDER=disabled" >> raffle-app/.env
```

2. **Set manual payment wallet numbers:**
```bash
echo "MONCASH_WALLET_NUMBER=509-1234-5678" >> raffle-app/.env
echo "NATCASH_WALLET_NUMBER=509-8765-4321" >> raffle-app/.env
```

3. **Start the server:**
```bash
cd raffle-app
npm start
```

4. **Test the Buyers Dashboard:**
   - Open: http://localhost:3000/buyers.html
   - Click "Purchase Tickets" tab
   - Fill in buyer information
   - See available payment methods
   - Select "Manual" payment option
   - View payment instructions
   - Submit a test transaction reference

5. **Test Admin Approval:**
   - Login as admin (phone: 1234567890, password: admin123)
   - Open: http://localhost:3000/payments-admin.html
   - View pending payment
   - Approve or reject the payment
   - Check SMS logs in console (simulated)

### Option 2: Test With Twilio SMS (10 Minutes)

1. **Get Twilio free trial:**
   - Sign up at https://www.twilio.com
   - Get $15 free credit
   - Copy Account SID, Auth Token, and Phone Number

2. **Configure .env:**
```bash
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=+1234567890
ADMIN_NOTIFICATION_PHONES=+your_phone_number
```

3. **Test SMS flow:**
   - Submit a manual payment on buyers dashboard
   - Check your phone for SMS notification
   - Approve in admin panel
   - Check for approval SMS

### Option 3: Full Integration Test (30+ Minutes)

Follow the complete setup guide in `PAYMENT_INTEGRATION_GUIDE.md`

## Quick Feature Tour

### Buyers Dashboard (`/buyers.html`)

1. **Purchase Tickets Tab** - New payment interface
   - Step 1: Enter buyer information
   - Step 2: Choose payment method
   - Step 3: Complete payment or submit reference

2. **Payment Methods Shown:**
   - MonCash (Automated) - if API configured
   - NatCash (Automated) - if API configured
   - MonCash (Manual) - if wallet number configured
   - NatCash (Manual) - if wallet number configured

3. **Manual Payment Instructions:**
   - Shows wallet number prominently
   - Step-by-step USSD/app instructions
   - Reference submission form
   - Status tracking

### Admin Interface (`/payments-admin.html`)

1. **Dashboard Stats:**
   - Pending payments count
   - Approved today
   - Rejected count
   - Total revenue

2. **Pending Approval Tab:**
   - List of all manual payments awaiting approval
   - Payment details (buyer, amount, category, etc.)
   - Approve/Reject actions

3. **Approval Process:**
   - Click "Approve" → Review details → Confirm
   - Automatic ticket assignment
   - SMS notification sent to buyer

4. **Rejection Process:**
   - Click "Reject" → Enter reason → Confirm
   - SMS notification sent with reason
   - Payment marked as rejected

## API Endpoints Quick Reference

### Public (No Auth Required)

```bash
# Get available payment methods
GET http://localhost:3000/api/payments/methods

# Get manual payment instructions
GET http://localhost:3000/api/payments/manual-instructions/moncash

# Check payment status
GET http://localhost:3000/api/payments/status/PAY-123456

# Submit manual payment
POST http://localhost:3000/api/payments/manual/submit
Content-Type: application/json
{
  "payment_method": "moncash",
  "amount": 50.00,
  "buyer_name": "John Doe",
  "buyer_phone": "509-1234-5678",
  "buyer_email": "john@example.com",
  "ticket_category": "A",
  "ticket_quantity": 1,
  "transaction_reference": "MC123456789"
}
```

### Admin (Auth Required)

```bash
# Get pending payments
GET http://localhost:3000/api/admin/payments/pending

# Approve payment
POST http://localhost:3000/api/admin/payments/approve
Content-Type: application/json
{
  "payment_reference": "PAY-123456"
}

# Reject payment
POST http://localhost:3000/api/admin/payments/reject
Content-Type: application/json
{
  "payment_reference": "PAY-123456",
  "rejection_reason": "Invalid transaction reference"
}
```

## Common Test Scenarios

### Scenario 1: Happy Path - Manual Payment

1. Buyer submits payment with reference "TEST123"
2. Check pending payments in admin panel
3. Approve the payment
4. Verify tickets are assigned
5. Check buyer receives SMS (if SMS enabled)

### Scenario 2: Rejection Flow

1. Buyer submits invalid payment reference
2. Admin reviews and rejects with reason
3. Verify rejection SMS sent to buyer
4. Payment status updated to "rejected"

### Scenario 3: Multiple Tickets

1. Buyer requests 5 tickets
2. Verify correct total amount calculated
3. Submit payment
4. Approve in admin panel
5. Verify 5 tickets assigned from correct category

### Scenario 4: Insufficient Tickets

1. Buyer requests more tickets than available
2. Submit payment
3. Admin tries to approve
4. System shows error: "Not enough tickets available"

## Troubleshooting Quick Fixes

### Issue: Payment methods not showing
```bash
# Check environment variables
cat raffle-app/.env | grep -E "MONCASH|NATCASH"

# Restart server
npm start
```

### Issue: SMS not sending
```bash
# Check SMS provider setting
echo $SMS_PROVIDER

# Try disabled mode first
SMS_PROVIDER=disabled npm start
```

### Issue: Admin panel not loading
```bash
# Check if logged in as admin
# Default: phone 1234567890, password admin123

# Access directly
open http://localhost:3000/payments-admin.html
```

### Issue: Database errors
```bash
# Restart server to recreate tables
npm start

# Check database connection
# Look for "✅ Database schema initialized" in logs
```

## Environment Variable Checklist

Minimum required for testing:

```bash
# Database (required)
DATABASE_URL=sqlite:./raffle.db  # or PostgreSQL URL

# Session (auto-generated if missing)
SESSION_SECRET=any-random-string

# Manual payments (minimum for testing)
MONCASH_WALLET_NUMBER=509-1234-5678
NATCASH_WALLET_NUMBER=509-8765-4321

# SMS (optional, can use 'disabled')
SMS_PROVIDER=disabled
```

## Next Steps After Testing

1. ✅ Verify all features work as expected
2. ✅ Test on mobile devices (UI is responsive)
3. ✅ Review admin workflow with team
4. ✅ Set up production API credentials
5. ✅ Configure production SMS provider
6. ✅ Deploy to staging environment
7. ✅ Conduct user acceptance testing
8. ✅ Deploy to production

## Support

- Full documentation: `PAYMENT_INTEGRATION_GUIDE.md`
- Code review: All issues resolved
- Syntax check: ✅ Passed
- Dependencies: ✅ Installed

## Quick Command Reference

```bash
# Install dependencies
npm install

# Start development server
npm start

# Check syntax
node -c raffle-app/server.js
node -c raffle-app/services/paymentService.js
node -c raffle-app/services/smsService.js

# View logs
# Check console output for SMS simulation and payment logs
```

Happy testing! 🚀
