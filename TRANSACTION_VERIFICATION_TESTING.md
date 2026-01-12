# MonCash Transaction ID Verification System - Testing Guide

## Overview
This document provides comprehensive testing instructions for the MonCash Transaction ID verification system with fraud detection capabilities.

## Features Implemented

### 1. Database Schema Changes
- ✅ Added `txn_verification_log` table for audit trail
- ✅ Added `payment_reference` column to `tickets` table
- ✅ Added `seller_name` column to `payments` table
- ✅ Created indexes for performance optimization

### 2. Backend API Endpoints

#### `/api/payments/verify-txn` (POST)
**Purpose:** Verify MonCash Transaction ID before ticket scanning

**Request:**
```json
{
  "txn_id": "1234567890123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "payment": {
    "payment_reference": "PAY-2024-001",
    "txn_id": "123456789012",
    "buyer_name": "John Doe",
    "buyer_phone": "509-1234-5678",
    "amount": 100.00,
    "payment_method": "MonCash",
    "ticket_category": "ABC",
    "tickets_allowed": 2,
    "tickets_assigned": 0,
    "tickets_remaining": 2,
    "verified_at": "2024-01-05T12:00:00Z"
  }
}
```

**Error Responses:**
- `400 INVALID_FORMAT` - Transaction ID must be 13-15 digits
- `404 PAYMENT_NOT_FOUND` - No payment found with this Transaction ID
- `400 PAYMENT_NOT_APPROVED` - Payment status is not "approved"
- `400 TXN_ALREADY_USED` - All tickets already assigned (fraud alert)

#### `/api/tickets/scan` (POST) - Updated
**Purpose:** Scan ticket and link to verified payment

**Request:**
```json
{
  "barcode": "ABC12345",
  "payment_reference": "PAY-2024-001"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Ticket assigned successfully",
  "ticket": "ABC12345",
  "tickets_assigned": 1,
  "tickets_remaining": 1,
  "all_tickets_assigned": false
}
```

**Error Responses:**
- `400 PAYMENT_NOT_VERIFIED` - Please verify payment first
- `404 INVALID_PAYMENT` - Payment reference not found
- `400 TICKET_LIMIT_EXCEEDED` - All tickets already assigned (fraud alert)
- `400 TICKET_ALREADY_LINKED` - Ticket linked to different payment (fraud alert)

### 3. Frontend Updates (seller.html)

#### Step 1: Transaction ID Verification Section
- Input field for 13-15 digit MonCash Transaction ID
- Validation (13-15 digits)
- Verification button
- Success display showing:
  - Customer name and phone
  - Amount paid
  - Tickets allowed vs. already assigned
  - Remaining tickets to scan
- Fraud alert display for duplicate/reused transaction IDs

#### Step 2: Ticket Scanning Section
- Initially disabled (grayed out with lock icon)
- Enabled after successful payment verification
- Camera scanner integration
- Manual ticket entry option
- Real-time remaining ticket count
- Automatic reset after all tickets assigned

### 4. Multi-Language Support
All new UI elements translated to:
- 🇺🇸 English
- 🇭🇹 Haitian Creole (Kreyòl Ayisyen)
- 🇫🇷 French (Français)

### 5. Fraud Detection Features
1. **Duplicate Transaction ID Detection**
   - Checks if all tickets for a transaction ID have already been assigned
   - Displays fraud alert with original customer details
   - Sends SMS alert to admins

2. **Over-Assignment Prevention**
   - Prevents scanning more tickets than paid for
   - Real-time validation during scanning

3. **Cross-Payment Ticket Linking**
   - Prevents assigning same ticket to multiple payments
   - Fraud alert on attempt

4. **Audit Trail**
   - All verification attempts logged in `txn_verification_log` table
   - Includes seller info, timestamp, and tickets remaining

## Testing Instructions

### Prerequisites
1. Server running with database initialized
2. Test payment created with approved status
3. Test seller account created
4. SMS service configured (optional for fraud alerts)

### Test Case 1: Valid Transaction ID Verification

**Steps:**
1. Login as seller
2. Navigate to seller dashboard
3. In "Step 1: Verify Payment" section:
   - Enter a valid 13-15 digit transaction ID (e.g., "1234567890123")
   - Click "Verify Payment"

**Expected Result:**
- ✅ Payment Verified! message displays
- Customer details shown (name, phone, amount, tickets)
- Step 2 (Scan Tickets) section becomes enabled
- Manual entry section also enabled

### Test Case 2: Invalid Transaction ID Format

**Steps:**
1. Enter transaction ID with less than 13 digits (e.g., "123456789012")
2. Click "Verify Payment"

**Expected Result:**
- ❌ Error: "Transaction ID must be 13-15 digits"

### Test Case 3: Non-Existent Transaction ID

**Steps:**
1. Enter a 13-15 digit transaction ID that doesn't exist (e.g., "9999999999999")
2. Click "Verify Payment"

**Expected Result:**
- ❌ Error: "No payment found with this Transaction ID. Customer must complete payment first."

### Test Case 4: Duplicate Transaction ID (Fraud Detection)

**Setup:**
1. Create a test payment with transaction ID "1111111111111"
2. Assign all tickets for that payment

**Steps:**
1. Try to verify the same transaction ID again
2. Click "Verify Payment"

**Expected Result:**
- 🚨 FRAUD ALERT displayed
- Shows: "This Transaction ID has already been used. All X tickets have been assigned."
- Shows original customer details and assigned tickets
- SMS alert sent to admins (if configured)
- Attempt logged in `txn_verification_log` table

### Test Case 5: Ticket Scanning Flow

**Steps:**
1. Verify a valid transaction ID (tickets remaining: 2)
2. Open camera scanner or use manual entry
3. Scan/enter first ticket barcode
4. Scan/enter second ticket barcode

**Expected Result:**
- After first ticket: "✅ Ticket ABC12345 sold successfully! (1 remaining)"
- Tickets Remaining counter updates to 1
- After second ticket: "✅ Ticket ABC12346 sold successfully! (0 remaining)"
- Alert: "All 2 tickets assigned! Click OK to verify next payment."
- Form resets, scanning section disabled again

### Test Case 6: Over-Assignment Prevention

**Steps:**
1. Verify transaction ID with 2 tickets allowed
2. Scan 2 tickets successfully
3. Try to scan a third ticket

**Expected Result:**
- ❌ Error: "All 2 tickets for this payment have been assigned"
- 🚨 Fraud alert indicator
- Cannot assign more tickets

### Test Case 7: Multi-Language Support

**Steps:**
1. Change language selector to Haitian Creole
2. Verify that all UI text updates
3. Change to French
4. Verify translations

**Expected Result:**
- All labels, buttons, messages in selected language
- Verification section: "Verifye Peman" (HT) / "Vérifier le Paiement" (FR)
- Error messages translated appropriately

### Test Case 8: Scanning Without Verification

**Steps:**
1. Don't verify any transaction ID
2. Try to click "Open Camera Scanner"

**Expected Result:**
- Scanner section is disabled (grayed out)
- Shows: "🔒 Verify payment first to enable scanning"

### Test Case 9: Manual Entry Without Verification

**Steps:**
1. Don't verify any transaction ID
2. Try to enter ticket manually

**Expected Result:**
- Manual entry section is disabled (grayed out)
- Shows: "🔒 Verify payment first to enable manual entry"

### Test Case 10: Verify Different Payment Button

**Steps:**
1. Verify a transaction ID successfully
2. Click "Verify Different Payment" button

**Expected Result:**
- Verification section resets
- Transaction ID input cleared
- Scanning sections disabled again
- Tickets Remaining cleared

## Database Validation

### Check txn_verification_log Table
```sql
SELECT * FROM txn_verification_log ORDER BY verification_time DESC LIMIT 10;
```

**Expected:** All verification attempts logged with seller info and timestamp

### Check payment_reference in tickets
```sql
SELECT ticket_number, status, payment_reference, seller_name 
FROM tickets 
WHERE payment_reference IS NOT NULL 
ORDER BY sold_at DESC 
LIMIT 10;
```

**Expected:** Tickets linked to payment references

### Check seller_name in payments
```sql
SELECT payment_reference, buyer_name, seller_name, ticket_numbers 
FROM payments 
WHERE seller_name IS NOT NULL 
LIMIT 10;
```

**Expected:** Payments updated with seller who assigned tickets

## API Testing with cURL

### Test Transaction Verification
```bash
curl -X POST http://localhost:3000/api/payments/verify-txn \
  -H "Content-Type: application/json" \
  -b "connect.sid=YOUR_SESSION_COOKIE" \
  -d '{"txn_id": "1234567890123"}'
```

### Test Ticket Scanning with Payment Reference
```bash
curl -X POST http://localhost:3000/api/tickets/scan \
  -H "Content-Type: application/json" \
  -b "connect.sid=YOUR_SESSION_COOKIE" \
  -d '{"barcode": "ABC12345", "payment_reference": "PAY-2024-001"}'
```

## Fraud Alert Testing

### Simulate Fraud Attempt
1. Create payment with txn_id "5555555555555", 2 tickets
2. Assign both tickets
3. Try to verify same txn_id again

**Expected:**
- API returns 400 with `fraud_alert: true`
- Admin phones receive SMS alert (if configured)
- Alert contains: txn_id, seller attempting reuse, original customer details

## Performance Considerations

### Database Indexes Created
- `idx_payments_transaction_id` - Fast lookup by transaction ID
- `idx_tickets_payment_reference` - Fast lookup of tickets by payment
- `idx_txn_verification_txn_id` - Fast fraud detection queries
- `idx_txn_verification_payment_ref` - Audit trail queries

### Load Testing Recommendations
- Test with 100+ concurrent seller verifications
- Test with 1000+ verification log entries
- Monitor query performance for fraud checks

## Security Considerations

✅ **Implemented:**
- Transaction ID format validation (13-15 digits)
- Payment status verification (must be "approved")
- Seller authentication required (session-based)
- Audit logging of all verification attempts
- Fraud detection and admin alerts

⚠️ **Additional Recommendations:**
- Rate limiting on verification endpoint
- CAPTCHA for suspicious patterns
- Seller IP logging
- Dashboard for reviewing verification logs

## Troubleshooting

### Issue: "Payment not found" for valid transaction
- Check payment_status is "approved"
- Verify transaction_id column populated correctly
- Check raffle_id matches active raffle

### Issue: Scanning section not enabling
- Check browser console for JavaScript errors
- Verify verification API returned success
- Check `currentVerifiedPayment` global variable set

### Issue: SMS alerts not sending
- Check ADMIN_NOTIFICATION_PHONES environment variable
- Verify SMS_PROVIDER configured (twilio or custom)
- Check smsService.js logs

### Issue: Multi-language not working
- Clear browser localStorage
- Check translations object in seller.html
- Verify language selector onChange handler

## Success Metrics

After deployment, monitor:
1. ✅ Fraud attempts detected and blocked
2. ✅ Average verification time < 2 seconds
3. ✅ Zero successful duplicate transaction ID usage
4. ✅ Seller adoption rate of new flow
5. ✅ Admin fraud alert response time

## Next Steps / Future Enhancements

1. Admin dashboard to view fraud attempts
2. Export fraud log to CSV
3. Advanced fraud detection (pattern recognition)
4. Seller performance metrics (verifications per day)
5. Customer SMS notification on ticket assignment
6. QR code generation for verified payments
7. Offline mode with sync-on-reconnect
