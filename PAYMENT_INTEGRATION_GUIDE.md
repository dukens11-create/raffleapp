# Payment Integration Guide

This document provides comprehensive setup instructions for the payment integration features, including MonCash, NatCash, and SMS notifications.

## Table of Contents

1. [Overview](#overview)
2. [Payment Methods](#payment-methods)
3. [Setup Instructions](#setup-instructions)
4. [Testing](#testing)
5. [Admin Workflow](#admin-workflow)
6. [Troubleshooting](#troubleshooting)

## Overview

The raffle application now supports three payment integration options:

### Automated Payments
- **MonCash API**: Automated payments through MonCash (Haiti's mobile money service)
- **NatCash API**: Automated payments through NatCash

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

#### E. Disable SMS (Optional)

If you want to disable SMS notifications temporarily:

```env
SMS_PROVIDER=disabled
```

SMS sending will be simulated (logged to console only).

### Step 3: Database Migration

The payments table is automatically created when you start the server. No manual migration needed.

### Step 4: Start the Server

```bash
npm start
```

Check the console output for:
- ✅ SMS service initialization
- ✅ Payment methods configured
- ✅ Database tables created

### Step 5: Verify Setup

1. **Check Payment Methods:**
   Visit: `http://localhost:3000/buyers.html`
   - Click "Purchase Tickets" tab
   - You should see available payment methods

2. **Check Admin Interface:**
   Visit: `http://localhost:3000/payments-admin.html`
   - Login with admin credentials
   - Should see payment management dashboard

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

---

## Seller Workflow: MonCash Transaction ID Verification

### 🎯 Critical Business Rule

**ONE TRANSACTION ID = ONE TICKET**

Each MonCash Transaction ID (Txn ID) can only be used for **exactly ONE ticket**. This is a core fraud prevention measure.

### Overview

The Transaction ID verification system ensures that:
- Each 12-digit MonCash Txn ID is unique to a single ticket
- Sellers must verify a unique Txn ID for each ticket before assignment
- Duplicate Txn ID attempts are blocked with fraud alerts
- All verification attempts are logged for audit purposes
- Admin receives SMS alerts for suspicious activity

### Seller Registration Process

#### Step 1: Customer Payment
Customer makes payment via MonCash:
- USSD: Dial `*202#` and complete transaction
- Mobile App: Use MonCash mobile app to pay
- **Result**: Customer receives 12-digit Transaction ID (e.g., `123456789012`)

#### Step 2: Seller Records Transaction
Seller enters BOTH pieces of information:
1. **MonCash Transaction ID** (12 digits) - from customer's payment receipt
2. **Ticket Number** - either scanned via camera or entered manually

#### Step 3: System Verification
The system performs multiple checks:
1. ✅ **Format Validation**: Txn ID must be exactly 12 digits
2. ✅ **Duplicate Check**: Txn ID has not been used before
3. ✅ **Ticket Validation**: Ticket is available and valid
4. ✅ **Payment Verification**: If payment record exists, verify it's approved

#### Step 4: Registration or Alert
- **If all checks pass**: Ticket is registered and assigned to customer
- **If Txn ID already used**: 🚨 FRAUD ALERT is displayed and logged

### Example Scenarios

#### ✅ Scenario 1: Customer Buying 3 Tickets (Correct)

Customer makes **3 separate MonCash payments**:

```
Payment 1: Txn ID 123456789012 → $10
Payment 2: Txn ID 234567890123 → $10  
Payment 3: Txn ID 345678901234 → $10
```

Seller registers each separately:

```
1. Enter 123456789012 + Scan Ticket 001 → ✅ Success
2. Enter 234567890123 + Scan Ticket 002 → ✅ Success
3. Enter 345678901234 + Scan Ticket 003 → ✅ Success
```

**Result**: All 3 tickets registered successfully.

#### ❌ Scenario 2: Reusing Transaction ID (Fraud Attempt)

Seller tries to register multiple tickets with same Txn ID:

```
1. Enter 123456789012 + Scan Ticket 001 → ✅ Success
2. Enter 123456789012 + Scan Ticket 002 → ❌ FRAUD ALERT
```

**Result**: 
- Second attempt is **BLOCKED**
- Fraud alert displayed to seller
- Admin receives SMS notification
- Attempt logged in database

### User Interface

![Seller Transaction ID UI](https://github.com/user-attachments/assets/83e96199-e7d5-46c2-bdec-f5d947bb8c0b)

The seller dashboard includes:

1. **Registration Form**
   - MonCash Transaction ID input (12 digits, numeric only)
   - Ticket Number input (manual or scanned)
   - Register button
   - Camera scanner button

2. **Session Counter**
   - Displays tickets registered in current session
   - Helps sellers track their progress

3. **Success Feedback**
   - Green alert showing registered ticket details
   - Txn ID confirmation
   - Ticket category display

4. **Fraud Alerts**
   - Red alert with warning icon
   - Shows original ticket that used the Txn ID
   - Displays who assigned it and when
   - Notes that admin has been notified

### Camera Scanner Integration

The camera scanner has been updated to support the new workflow:

1. Seller clicks "📷 Use Camera"
2. Camera opens and scans ticket barcode
3. **Ticket number is populated in the form** (not auto-submitted)
4. Seller must still enter Transaction ID
5. Seller clicks "Register Ticket" to complete

This ensures sellers cannot bypass the Txn ID requirement.

### Multi-Language Support

The interface supports three languages:
- 🇺🇸 **English**: "One Transaction ID per ticket"
- 🇭🇹 **Haitian Creole**: "Yon Nimewo Tranzaksyon pou chak tikè"
- 🇫🇷 **French**: "Un ID de transaction par billet"

Sellers can switch languages using the dropdown in the header.

### Fraud Prevention Features

#### 1. Duplicate Transaction ID Detection
- System checks if Txn ID has been used before
- Shows which ticket it was used for
- Displays original seller and timestamp

#### 2. Ticket Already Assigned Detection
- Prevents assigning Txn ID to already-sold ticket
- Shows existing Txn ID on the ticket

#### 3. Audit Logging
All verification attempts are logged with:
- Transaction ID
- Ticket number (if applicable)
- Seller information
- Timestamp
- Status (success/fraud_attempt)
- Fraud type and details (if applicable)

#### 4. SMS Fraud Alerts
When fraud is detected, admin receives SMS:
```
🚨 FRAUD ALERT

Type: DUPLICATE_TXN
Txn ID: 123456789012
Seller: John Doe
Phone: 509-1234-5678

Details: {"attempted_ticket":"002","original_ticket":"001"}

Review admin panel immediately.
```

### Error Messages

| Error Code | Message | Meaning |
|------------|---------|---------|
| `INVALID_TXN_FORMAT` | "Transaction ID must be exactly 12 digits" | Txn ID is not 12 numeric digits |
| `TICKET_REQUIRED` | "Ticket number is required" | Ticket field is empty |
| `TXN_ALREADY_USED` | "This Transaction ID has already been used for ticket X" | Txn ID was used for another ticket |
| `TICKET_ALREADY_ASSIGNED` | "This ticket is already assigned to Txn ID: X" | Ticket already has a Txn ID |
| `PAYMENT_NOT_APPROVED` | "Payment status is 'pending'. Only approved payments can be used." | Associated payment not approved yet |
| `PAYMENT_ALREADY_USED` | "This payment already has ticket X assigned" | Payment record already linked |

### Best Practices for Sellers

1. **Always Get Transaction ID First**
   - Ask customer for their MonCash Transaction ID
   - Verify it's 12 digits before scanning ticket

2. **One Txn ID Per Ticket**
   - Never reuse a Transaction ID
   - Each customer payment = unique Txn ID

3. **Verify Customer Payment**
   - Ask customer to show payment confirmation
   - Check the Txn ID on their phone

4. **Handle Errors Properly**
   - If fraud alert appears, **DO NOT OVERRIDE**
   - Contact admin immediately
   - Do not complete the sale

5. **Keep Records**
   - Session counter shows your daily progress
   - Take note of successful registrations

### Admin Monitoring

Admins can monitor seller activity through:

1. **Fraud Log Dashboard** (Future feature)
   - View all fraud attempts
   - Filter by seller, date, type
   - Export to CSV

2. **SMS Alerts**
   - Real-time notifications of fraud attempts
   - Configure admin phone numbers in `.env`:
     ```
     ADMIN_NOTIFICATION_PHONES=509-1111-2222,509-3333-4444
     ```

3. **Database Queries**
   Query the verification log:
   ```sql
   -- View all fraud attempts
   SELECT * FROM txn_verification_log 
   WHERE status = 'fraud_attempt'
   ORDER BY verification_time DESC;
   
   -- View fraud attempts by seller
   SELECT seller_name, COUNT(*) as attempts
   FROM txn_verification_log 
   WHERE status = 'fraud_attempt'
   GROUP BY seller_name
   ORDER BY attempts DESC;
   ```

### Security Considerations

1. **Txn ID Uniqueness**
   - Database enforces unique constraint on `txn_id` column
   - Index created for fast lookup
   - Prevents race conditions

2. **Audit Trail**
   - All attempts logged permanently
   - Cannot be deleted or modified
   - Includes fraud details for investigation

3. **SMS Alerts**
   - Real-time notification to admins
   - Configurable recipient list
   - Works even if email is down

4. **Session Tracking**
   - Each seller's session tracked separately
   - Counter resets on logout
   - Helps identify suspicious patterns

### Troubleshooting

**Q: Seller says customer paid but Txn ID shows as already used**

A: This could be:
- Customer gave wrong Txn ID (check their phone)
- Customer trying to reuse old Txn ID (ask for new payment)
- Seller made typo (verify Txn ID carefully)

**Q: Fraud alert appears but seller claims it's legitimate**

A: **NEVER override fraud alert**. Contact admin who can:
- Review the original transaction
- Check with original seller
- Investigate in database
- Clear false positive if confirmed

**Q: Camera scanner doesn't populate ticket field**

A: 
- Ensure camera permissions are granted
- Try manual entry instead
- Check scanner library loaded (see console)

**Q: SMS fraud alerts not being sent**

A: Verify configuration:
```bash
# Check .env file
SMS_PROVIDER=twilio  # or 'custom'
ADMIN_NOTIFICATION_PHONES=509-1111-2222,509-3333-4444

# For Twilio
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=+1234567890
```

### API Reference

For developers integrating with the system:

**Endpoint**: `POST /api/tickets/register-with-txn`

**Request**:
```json
{
  "txn_id": "123456789012",
  "ticket_barcode": "ABC-001234"
}
```

**Success Response** (200):
```json
{
  "success": true,
  "message": "Ticket registered successfully",
  "ticket": {
    "ticket_number": "ABC-001234",
    "txn_id": "123456789012",
    "seller": "John Doe",
    "category": "Bronze",
    "registered_at": "2026-01-05T12:30:00.000Z"
  }
}
```

**Fraud Alert Response** (400):
```json
{
  "error": "TXN_ALREADY_USED",
  "message": "This Transaction ID has already been used for ticket ABC-001234",
  "fraud_alert": true,
  "details": {
    "original_ticket": "ABC-001234",
    "assigned_by": "Jane Seller",
    "assigned_at": "2026-01-05T10:00:00.000Z",
    "customer": "John Customer"
  }
}
```

**Error Response** (400):
```json
{
  "error": "INVALID_TXN_FORMAT",
  "message": "Transaction ID must be exactly 12 digits"
}
```

### Database Schema

**Tickets Table** (updated):
```sql
ALTER TABLE tickets ADD COLUMN txn_id TEXT UNIQUE;
CREATE INDEX idx_tickets_txn_id ON tickets(txn_id);
```

**Transaction Verification Log** (new):
```sql
CREATE TABLE txn_verification_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  txn_id TEXT NOT NULL,
  ticket_number TEXT,
  seller_phone TEXT NOT NULL,
  seller_name TEXT NOT NULL,
  verification_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  status TEXT NOT NULL,
  fraud_type TEXT,
  fraud_details TEXT
);

CREATE INDEX idx_txn_log_txn_id ON txn_verification_log(txn_id);
CREATE INDEX idx_txn_log_status ON txn_verification_log(status);
```

### Support

For technical issues:
- Check server logs: `journalctl -u raffle-app -f`
- Review database logs: Query `txn_verification_log` table
- Contact development team

For seller training:
- Provide this guide to all sellers
- Conduct hands-on training session
- Monitor first few days closely

---

**Last Updated**: January 5, 2026  
**Version**: 2.0 - MonCash Transaction ID Verification System
