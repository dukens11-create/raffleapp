# Buyer Portal API Examples

This document provides example API calls for testing the buyer portal ticket purchase functionality.

## Overview

The buyer portal now supports purchasing tickets from the last 100,000 tickets of each category (ABC, EFG, JKL, XYZ) with atomic allocation during payment initiation.

### Key Features
- **Last 100K Restriction**: Only the last 100,000 tickets per category are available online
- **Atomic Allocation**: Tickets are reserved immediately upon payment initiation
- **Payment Integration**: Supports both MonCash and NatCash payment methods
- **Real-time Availability**: Shows live ticket counts per category

---

## API Endpoints

### 1. Get Ticket Availability

**Endpoint**: `GET /api/public/ticket-availability`

**Description**: Returns the number of available tickets for each category from the last 100K pool.

**Example Request**:
```bash
curl -X GET http://localhost:3000/api/public/ticket-availability
```

**Example Response**:
```json
{
  "success": true,
  "categories": [
    {
      "category": "ABC",
      "available": 95234,
      "total_online": 100000,
      "price": 10.00
    },
    {
      "category": "EFG",
      "available": 98756,
      "total_online": 100000,
      "price": 20.00
    },
    {
      "category": "JKL",
      "available": 87543,
      "total_online": 100000,
      "price": 50.00
    },
    {
      "category": "XYZ",
      "available": 99012,
      "total_online": 100000,
      "price": 100.00
    }
  ],
  "total_available": 380545
}
```

**Notes**:
- `available`: Number of tickets still available for purchase
- `total_online`: Total tickets allocated for online sales (always 100K per category)
- `price`: Price per ticket for this category

---

### 2. Initiate Purchase with MonCash

**Endpoint**: `POST /api/public/purchase/initiate`

**Description**: Initiates a ticket purchase with atomic allocation. Reserves the specified number of tickets and creates a MonCash payment.

**Example Request**:
```bash
curl -X POST http://localhost:3000/api/public/purchase/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "moncash",
    "buyer_name": "Jean Baptiste",
    "buyer_phone": "509-1234-5678",
    "buyer_email": "jean@example.com",
    "ticket_category": "ABC",
    "ticket_quantity": 5,
    "customer_department": "Ouest"
  }'
```

**Example Response**:
```json
{
  "success": true,
  "payment_reference": "MONCASH-20240115-ABC123",
  "tickets_allocated": [
    "ABC-275001",
    "ABC-275002",
    "ABC-275003",
    "ABC-275004",
    "ABC-275005"
  ],
  "quantity": 5,
  "category": "ABC",
  "amount": 50.00,
  "payment_details": {
    "success": true,
    "paymentToken": "mc_token_xyz789",
    "redirectUrl": "https://sandbox.moncashbutton.digicelgroup.com/Api/v1/Redirect?token=mc_token_xyz789",
    "mode": "sandbox"
  }
}
```

**What Happens**:
1. System checks if 5 ABC tickets are available
2. Locks the ticket generation mutex to prevent race conditions
3. Reserves 5 tickets and marks them with `status='RESERVED'` and `payment_reference`
4. Creates a payment record in the database
5. Initiates MonCash payment
6. Returns the payment redirect URL and allocated ticket numbers

**Next Steps**:
- Frontend redirects user to `payment_details.redirectUrl`
- User completes payment on MonCash
- MonCash redirects back to your callback URL
- Payment status is verified and tickets are marked as SOLD

---

### 3. Initiate Purchase with NatCash

**Endpoint**: `POST /api/public/purchase/initiate`

**Description**: Same as MonCash but uses NatCash payment provider.

**Example Request**:
```bash
curl -X POST http://localhost:3000/api/public/purchase/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "natcash",
    "buyer_name": "Marie Pierre",
    "buyer_phone": "509-8765-4321",
    "buyer_email": "marie@example.com",
    "ticket_category": "XYZ",
    "ticket_quantity": 2,
    "customer_department": "Nord"
  }'
```

**Example Response**:
```json
{
  "success": true,
  "payment_reference": "NATCASH-20240115-XYZ456",
  "tickets_allocated": [
    "XYZ-275001",
    "XYZ-275002"
  ],
  "quantity": 2,
  "category": "XYZ",
  "amount": 200.00,
  "payment_details": {
    "success": true,
    "paymentId": "nc_pay_abc123",
    "transactionRef": "NC-TXN-789456",
    "status": "pending",
    "mode": "sandbox"
  }
}
```

**What Happens**:
1. System checks if 2 XYZ tickets are available
2. Atomically reserves 2 tickets
3. Creates payment record
4. Initiates NatCash payment (sends push notification to buyer's phone)
5. Returns payment details

**Next Steps**:
- Buyer receives push notification on their NatCash app
- Buyer approves payment in app
- System receives webhook/callback from NatCash
- Payment status is verified and tickets are marked as SOLD

---

## Error Scenarios

### Insufficient Tickets Available

**Request**:
```bash
curl -X POST http://localhost:3000/api/public/purchase/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "moncash",
    "buyer_name": "Test User",
    "buyer_phone": "509-1111-2222",
    "ticket_category": "ABC",
    "ticket_quantity": 10,
    "customer_department": "Sud"
  }'
```

**Response** (when only 5 tickets available):
```json
{
  "error": "Insufficient tickets available",
  "requested": 10,
  "available": 5
}
```

### Invalid Category

**Request**:
```bash
curl -X POST http://localhost:3000/api/public/purchase/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "moncash",
    "buyer_name": "Test User",
    "buyer_phone": "509-1111-2222",
    "ticket_category": "INVALID",
    "ticket_quantity": 1,
    "customer_department": "Ouest"
  }'
```

**Response**:
```json
{
  "errors": [
    {
      "msg": "Valid ticket category required",
      "param": "ticket_category",
      "location": "body"
    }
  ]
}
```

### Quantity Out of Range

**Request**:
```bash
curl -X POST http://localhost:3000/api/public/purchase/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "moncash",
    "buyer_name": "Test User",
    "buyer_phone": "509-1111-2222",
    "ticket_category": "ABC",
    "ticket_quantity": 15,
    "customer_department": "Ouest"
  }'
```

**Response**:
```json
{
  "errors": [
    {
      "msg": "Quantity must be between 1 and 10",
      "param": "ticket_quantity",
      "location": "body"
    }
  ]
}
```

---

## Testing Workflow

### Complete Purchase Flow Test

1. **Check Availability**:
   ```bash
   curl http://localhost:3000/api/public/ticket-availability
   ```

2. **Initiate Purchase**:
   ```bash
   curl -X POST http://localhost:3000/api/public/purchase/initiate \
     -H "Content-Type: application/json" \
     -d '{
       "payment_method": "moncash",
       "buyer_name": "Test Buyer",
       "buyer_phone": "509-9999-8888",
       "buyer_email": "test@example.com",
       "ticket_category": "ABC",
       "ticket_quantity": 3,
       "customer_department": "Ouest"
     }'
   ```

3. **Note the Response**:
   - Save `payment_reference` for tracking
   - Save `tickets_allocated` to verify later
   - Save `payment_details.redirectUrl` for MonCash redirect

4. **Check Payment Status** (after completing payment):
   ```bash
   curl http://localhost:3000/api/payments/status/MONCASH-20240115-ABC123
   ```

5. **Verify Tickets Were Allocated**:
   ```bash
   # Check in admin dashboard or database
   # Tickets should have status='RESERVED' or 'SOLD' and payment_reference set
   ```

---

## Frontend Integration

### JavaScript Example

```javascript
// 1. Load available tickets
async function loadAvailability() {
  const response = await fetch('/api/public/ticket-availability');
  const data = await response.json();
  
  console.log('Available tickets:', data.categories);
  // Display in UI: ABC: 95,234 available, EFG: 98,756 available, etc.
}

// 2. Initiate purchase with MonCash
async function purchaseWithMonCash(purchaseData) {
  const response = await fetch('/api/public/purchase/initiate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      payment_method: 'moncash',
      buyer_name: purchaseData.name,
      buyer_phone: purchaseData.phone,
      buyer_email: purchaseData.email,
      ticket_category: purchaseData.category,
      ticket_quantity: purchaseData.quantity,
      customer_department: purchaseData.department
    })
  });
  
  const data = await response.json();
  
  if (data.success) {
    // Show success message with allocated tickets
    console.log(`${data.quantity} tickets reserved:`, data.tickets_allocated);
    
    // Redirect to MonCash
    window.location.href = data.payment_details.redirectUrl;
  } else {
    // Show error
    console.error('Purchase failed:', data.error);
  }
}

// 3. Initiate purchase with NatCash
async function purchaseWithNatCash(purchaseData) {
  const response = await fetch('/api/public/purchase/initiate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      payment_method: 'natcash',
      buyer_name: purchaseData.name,
      buyer_phone: purchaseData.phone,
      buyer_email: purchaseData.email,
      ticket_category: purchaseData.category,
      ticket_quantity: purchaseData.quantity,
      customer_department: purchaseData.department
    })
  });
  
  const data = await response.json();
  
  if (data.success) {
    // Show success message
    console.log(`${data.quantity} tickets reserved:`, data.tickets_allocated);
    console.log('Payment ID:', data.payment_details.paymentId);
    console.log('Please check your phone for NatCash payment request');
  } else {
    // Show error
    console.error('Purchase failed:', data.error);
  }
}
```

---

## Database Verification

After initiating a purchase, you can verify the ticket allocation in the database:

```sql
-- Check reserved tickets for a payment reference
SELECT 
  ticket_number, 
  category, 
  status, 
  payment_reference,
  created_at
FROM tickets 
WHERE payment_reference = 'MONCASH-20240115-ABC123'
ORDER BY ticket_number;

-- Check payment record
SELECT 
  payment_reference,
  payment_method,
  payment_status,
  buyer_name,
  buyer_phone,
  ticket_category,
  ticket_quantity,
  amount,
  created_at
FROM payments 
WHERE payment_reference = 'MONCASH-20240115-ABC123';

-- Verify tickets are from the last 100K pool
SELECT 
  category,
  MIN(ticket_number) as first_online_ticket,
  MAX(ticket_number) as last_online_ticket,
  COUNT(*) as total_online
FROM tickets 
WHERE available_online = TRUE
GROUP BY category;
```

---

## Notes

### Atomic Allocation
- The system uses a mutex to ensure thread-safe ticket allocation
- Multiple simultaneous purchases won't allocate the same tickets
- If payment initiation fails, reserved tickets are automatically rolled back

### Payment Flow
1. **Initiate**: Tickets reserved, payment created
2. **Pending**: User redirected to payment provider
3. **Approved**: Payment confirmed, tickets marked as SOLD
4. **Failed**: Tickets released back to pool (status back to AVAILABLE)

### Ticket Status States
- `AVAILABLE`: Ready to be purchased
- `RESERVED`: Allocated to a payment, awaiting confirmation
- `SOLD`: Payment confirmed, ticket assigned to buyer

### Valid Departments
```
Ouest, Sud, Nord, Artibonite, Centre, Grand'Anse, 
Nippes, Nord-Est, Nord-Ouest, Sud-Est
```

---

## Support

For questions or issues:
- Check server logs for detailed error messages
- Verify payment provider credentials are configured in `.env`
- Ensure the migration script has been run to mark last 100K tickets as available online
- Test in sandbox mode before production deployment
