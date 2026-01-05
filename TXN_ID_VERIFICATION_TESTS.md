# MonCash Transaction ID Verification System - Test Documentation

## Overview
This document outlines the test scenarios for the ONE TXN ID = ONE TICKET verification system implemented in the raffle application.

## Test Scenarios

### 1. Valid Registration Flow ✅

**Test Case**: Register a ticket with a valid, unique transaction ID
- **Input**: 
  - Txn ID: `123456789012` (12 digits, not previously used)
  - Ticket Number: `ABC12345678` (valid, available ticket)
- **Expected Result**: 
  - ✅ Success message displayed
  - Ticket marked as SOLD in database
  - Txn ID linked to ticket in database
  - Entry added to `txn_log` table
  - Session counter incremented
  - Form cleared and ready for next entry
- **API Endpoint**: `POST /api/tickets/register-with-txn`

### 2. Duplicate Transaction ID Detection 🚨

**Test Case**: Attempt to use an already-used transaction ID
- **Input**:
  - Txn ID: `123456789012` (already used for another ticket)
  - Ticket Number: `XYZ98765432`
- **Expected Result**:
  - ❌ Fraud alert displayed with details:
    - Original ticket number
    - Original seller name
    - Original sale date
  - Request blocked (HTTP 400)
  - Entry logged in `fraud_log` table with `fraud_type = 'DUPLICATE_TXN'`
  - SMS alert sent to admin (if configured)
  - Form NOT cleared

### 3. Ticket Already Assigned 🚨

**Test Case**: Attempt to assign a transaction ID to a ticket that already has one
- **Input**:
  - Txn ID: `987654321098` (new, valid)
  - Ticket Number: `ABC12345678` (already assigned to Txn ID `123456789012`)
- **Expected Result**:
  - ❌ Error message: "Ticket ABC12345678 is already registered with Txn ID: 123456789012"
  - Request blocked (HTTP 400)
  - Entry logged in `fraud_log` table with `fraud_type = 'TICKET_ALREADY_ASSIGNED'`
  - Form NOT cleared

### 4. Invalid Transaction ID Format ❌

**Test Cases**: Various invalid formats

#### 4a. Too Short
- **Input**: `12345678901` (11 digits)
- **Expected**: Validation error - "Transaction ID must be exactly 12 digits"

#### 4b. Too Long
- **Input**: `1234567890123` (13 digits)
- **Expected**: HTML5 validation prevents submission (maxlength=12)

#### 4c. Non-numeric Characters
- **Input**: `12345678901a`
- **Expected**: HTML5 validation prevents submission (pattern="[0-9]{12}")

#### 4d. Empty Field
- **Input**: (empty)
- **Expected**: HTML5 required validation prevents submission

### 5. Invalid Ticket Number ❌

**Test Case**: Use an invalid or non-existent ticket number
- **Input**:
  - Txn ID: `111222333444` (valid format)
  - Ticket Number: `INVALID123`
- **Expected Result**:
  - ❌ Error message from `validateTicketForSale`: "Ticket not found" or "Invalid format"
  - Request blocked (HTTP 400)
  - No database changes

### 6. Ticket Already Sold (Different Flow) ❌

**Test Case**: Attempt to register a ticket that's already sold (status = 'SOLD')
- **Input**:
  - Txn ID: `222333444555` (valid, new)
  - Ticket Number: `DEF87654321` (valid but status = 'SOLD')
- **Expected Result**:
  - ❌ Error from `validateTicketForSale`: "This ticket has already been sold"
  - Request blocked (HTTP 400)

### 7. Camera Scanner Integration 📷

**Test Case**: Use camera to scan barcode, then enter Txn ID
- **Steps**:
  1. Click "📷 Scan Barcode" button
  2. Camera opens
  3. Scan valid ticket barcode `ABC12345678`
  4. Scanner closes, ticket number populates in form
  5. Focus moves to Txn ID field (if empty) or Register button
  6. Enter Txn ID: `333444555666`
  7. Click "✅ Register Ticket"
- **Expected Result**:
  - Ticket number auto-populated
  - Smooth workflow
  - Successful registration

### 8. Multi-Language Support 🌍

**Test Cases**: Test in all three languages

#### 8a. English (en)
- UI shows: "Register Ticket Sale", "Customer's MonCash Transaction ID", etc.

#### 8b. Haitian Creole (ht)
- UI shows: "Anrejistre Vant Tikè", "Nimewo Tranzaksyon MonCash Kliyant", etc.

#### 8c. French (fr)
- UI shows: "Enregistrer Vente de Billet", "ID Transaction MonCash du Client", etc.

### 9. Session Counter 📊

**Test Case**: Verify session counter increments correctly
- **Steps**:
  1. Note initial count: 0
  2. Successfully register ticket 1 → Count: 1
  3. Successfully register ticket 2 → Count: 2
  4. Attempt fraud (duplicate Txn) → Count stays: 2
  5. Successfully register ticket 3 → Count: 3
- **Expected**: Counter only increments on successful registrations

### 10. Form Auto-Clear 🔄

**Test Case**: Verify form clears after success
- **Steps**:
  1. Enter Txn ID: `444555666777`
  2. Enter Ticket: `JKL11223344`
  3. Submit successfully
- **Expected**:
  - Success message shows for 3 seconds
  - Both input fields cleared
  - Focus returns to Txn ID field
  - Ready for next registration

## Database Verification Tests

### Table: `tickets`
- **Check**: `txn_id` column exists with UNIQUE constraint
- **Verify**: Can insert ticket with txn_id
- **Verify**: Cannot insert two tickets with same txn_id

### Table: `txn_log`
- **Check**: Table exists with correct schema
- **Verify**: Successful registrations create log entries
- **Verify**: Log contains: txn_id, ticket_number, seller_phone, seller_name, logged_at

### Table: `fraud_log`
- **Check**: Table exists with correct schema
- **Verify**: Fraud attempts create log entries
- **Verify**: Log contains: txn_id, seller_phone, seller_name, fraud_type, original_ticket, attempted_ticket, logged_at

### Indexes
- **Verify**: `idx_tickets_txn_id` exists on tickets(txn_id)
- **Verify**: `idx_txn_log_txn` exists on txn_log(txn_id)
- **Verify**: `idx_fraud_log_txn` exists on fraud_log(txn_id)
- **Verify**: `idx_fraud_log_seller` exists on fraud_log(seller_phone)

## API Endpoint Tests

### Endpoint: `POST /api/tickets/register-with-txn`

#### Authentication
- **Test**: Call without authentication
- **Expected**: HTTP 401 Unauthorized

#### Request Body Validation
```json
{
  "txn_id": "123456789012",
  "ticket_barcode": "ABC12345678"
}
```

#### Response: Success (HTTP 200)
```json
{
  "success": true,
  "message": "Ticket registered successfully",
  "ticket": {
    "number": "ABC12345678",
    "category": "ABC",
    "txn_id": "123456789012"
  }
}
```

#### Response: Duplicate Txn (HTTP 400)
```json
{
  "error": "TXN_ALREADY_USED",
  "message": "This Transaction ID was already used for ticket XYZ98765432",
  "fraud_alert": true,
  "details": {
    "original_ticket": "XYZ98765432",
    "seller": "John Doe",
    "date": "2026-01-05T06:45:00.000Z"
  }
}
```

#### Response: Invalid Format (HTTP 400)
```json
{
  "error": "INVALID_TXN_FORMAT",
  "message": "Transaction ID must be exactly 12 digits"
}
```

## SMS Alert Tests (If Configured)

### Fraud Alert SMS
- **Trigger**: Duplicate Txn ID attempt
- **Recipient**: Admin phone(s) from `ADMIN_NOTIFICATION_PHONES` env var
- **Message Format**:
```
🚨 FRAUD ALERT

Type: DUPLICATE_TXN
Txn ID: 123456789012
Seller: John Doe (509-1234-5678)
Original: XYZ98765432
Attempted: ABC12345678

Review admin panel.
```

## Security Tests

### 1. SQL Injection
- **Test**: Enter `' OR '1'='1` in Txn ID or Ticket fields
- **Expected**: Parameterized queries prevent injection

### 2. XSS
- **Test**: Enter `<script>alert('xss')</script>` in fields
- **Expected**: Input validation rejects non-digit characters in Txn ID

### 3. Race Condition
- **Test**: Submit same Txn ID from two sellers simultaneously
- **Expected**: Database UNIQUE constraint prevents both from succeeding

## Performance Tests

### Response Time
- **Test**: Measure API response time for registration
- **Expected**: < 500ms for database queries + validation

### Concurrent Registrations
- **Test**: Multiple sellers registering different tickets simultaneously
- **Expected**: All succeed, no conflicts, proper logging

## Edge Cases

### 1. Leading/Trailing Spaces
- **Input**: `  123456789012  ` (spaces before/after)
- **Expected**: Trimmed and processed correctly

### 2. Very First Registration
- **Test**: First ever ticket registration in clean database
- **Expected**: Works without errors

### 3. Database Connection Lost
- **Test**: Simulate database disconnect during registration
- **Expected**: Graceful error message, no partial data corruption

## Manual Testing Checklist

- [ ] Install dependencies: `npm install`
- [ ] Set up test database
- [ ] Create test seller account
- [ ] Test valid registration flow
- [ ] Test duplicate Txn ID (should show fraud alert)
- [ ] Test invalid Txn ID formats (11, 13 digits, letters)
- [ ] Test camera scanner (populate ticket field)
- [ ] Test manual entry
- [ ] Switch language to Haitian Creole - verify translations
- [ ] Switch language to French - verify translations
- [ ] Verify session counter increments
- [ ] Check database: tickets table has txn_id column
- [ ] Check database: txn_log table has entries
- [ ] Check database: fraud_log table has fraud attempts
- [ ] Test SMS alert (if configured)
- [ ] Test on mobile device (responsive design)

## Known Limitations

1. SMS alerts require proper `ADMIN_NOTIFICATION_PHONES` configuration
2. Camera scanner requires HTTPS or localhost (browser security)
3. Database migration runs automatically on server start
4. Session counter resets on page refresh (by design)

## Success Criteria

✅ Each Txn ID can only register ONE ticket
✅ Duplicate Txn ID blocked immediately with fraud alert
✅ Fraud alerts logged in database
✅ Admin notified via SMS (when configured)
✅ Complete audit trail in txn_log and fraud_log
✅ Multi-language support (EN, HT, FR)
✅ Works with camera scanner and manual entry
✅ Fast workflow for legitimate transactions
✅ Session counter tracks registrations accurately
✅ Form auto-clears after successful registration
