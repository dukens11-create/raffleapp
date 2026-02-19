# Backend API Integration Guide for Phase 3 Features

This document describes the backend API endpoints required to support the Phase 3 offline support, push notifications, and background sync features.

## Table of Contents
1. [Sync Endpoints](#sync-endpoints)
2. [Notification Endpoints](#notification-endpoints)
3. [FCM Integration](#fcm-integration)
4. [Response Formats](#response-formats)
5. [Error Handling](#error-handling)
6. [Implementation Examples](#implementation-examples)

## Sync Endpoints

### 1. Bulk Ticket Sync
**Endpoint:** `POST /api/sync/tickets`

**Purpose:** Sync multiple tickets from mobile app to server (for offline-created tickets)

**Request Body:**
```json
{
  "tickets": [
    {
      "barcode": "TKT-001",
      "category": "BAS",
      "price": 50,
      "status": "available",
      "buyer_id": null,
      "seller_id": 123,
      "created_at": "2024-01-15T10:30:00Z",
      "client_timestamp": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "synced": 10,
  "conflicts": [],
  "tickets": [
    {
      "id": 1001,
      "barcode": "TKT-001",
      "category": "BAS",
      "price": 50,
      "status": "available",
      "buyer_id": null,
      "seller_id": 123,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Conflict Handling:**
- If ticket barcode already exists, return in `conflicts` array
- Server data always takes precedence (last-write-wins)

### 2. Bulk Payment Sync
**Endpoint:** `POST /api/sync/payments`

**Purpose:** Sync payment records from offline sales

**Request Body:**
```json
{
  "payments": [
    {
      "ticket_id": 1001,
      "amount": 50,
      "method": "cash",
      "status": "completed",
      "transaction_id": "PAY-12345",
      "created_at": "2024-01-15T11:00:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "synced": 5,
  "payments": [
    {
      "id": 501,
      "ticket_id": 1001,
      "amount": 50,
      "method": "cash",
      "status": "completed",
      "transaction_id": "PAY-12345",
      "created_at": "2024-01-15T11:00:00Z"
    }
  ]
}
```

### 3. Delta Updates
**Endpoint:** `GET /api/sync/updates`

**Purpose:** Get incremental updates since last sync

**Query Parameters:**
- `entity`: Entity type (tickets, payments, users, notifications)
- `since`: ISO 8601 timestamp of last sync

**Example:**
```
GET /api/sync/updates?entity=tickets&since=2024-01-15T10:00:00Z
```

**Response:**
```json
{
  "entity": "tickets",
  "since": "2024-01-15T10:00:00Z",
  "timestamp": "2024-01-15T12:00:00Z",
  "items": [
    {
      "id": 1001,
      "barcode": "TKT-001",
      "status": "sold",
      "updated_at": "2024-01-15T11:30:00Z"
    }
  ],
  "deleted_ids": [999]
}
```

## Notification Endpoints

### 1. Register FCM Token
**Endpoint:** `POST /api/fcm/register`

**Purpose:** Register device FCM token for push notifications

**Request Body:**
```json
{
  "token": "fcm-token-string",
  "platform": "android",
  "user_id": 123
}
```

**Response:**
```json
{
  "success": true,
  "message": "Token registered successfully"
}
```

**Implementation Notes:**
- Store token with user_id association
- Update if token changes for same user/device
- Mark old tokens as inactive

### 2. Send Push Notification
**Endpoint:** `POST /api/notifications/send`

**Purpose:** Send push notification to specific user or role

**Request Body:**
```json
{
  "user_id": 123,
  "type": "ticket_purchase",
  "title": "Ticket Purchase Confirmed",
  "body": "Your ticket TKT-001 has been purchased successfully",
  "data": {
    "ticket_id": 1001,
    "barcode": "TKT-001",
    "action": "view_ticket"
  }
}
```

**Response:**
```json
{
  "success": true,
  "notification_id": 5001,
  "sent_at": "2024-01-15T12:00:00Z"
}
```

### 3. Get Notifications
**Endpoint:** `GET /api/notifications`

**Purpose:** Fetch notifications for current user

**Query Parameters:**
- `since`: ISO 8601 timestamp (optional)
- `limit`: Number of results (default: 50)
- `offset`: Pagination offset (default: 0)

**Example:**
```
GET /api/notifications?since=2024-01-15T10:00:00Z&limit=20
```

**Response:**
```json
{
  "notifications": [
    {
      "id": 5001,
      "title": "Ticket Purchase Confirmed",
      "body": "Your ticket TKT-001 has been purchased",
      "type": "ticket_purchase",
      "data": {
        "ticket_id": 1001,
        "barcode": "TKT-001"
      },
      "read": false,
      "created_at": "2024-01-15T12:00:00Z"
    }
  ],
  "total": 45,
  "unread_count": 12
}
```

### 4. Mark Notification as Read
**Endpoint:** `PUT /api/notifications/:id/read`

**Purpose:** Mark single notification as read

**Response:**
```json
{
  "success": true
}
```

### 5. Bulk Mark as Read
**Endpoint:** `POST /api/notifications/mark-read`

**Purpose:** Mark multiple notifications as read

**Request Body:**
```json
{
  "notification_ids": [5001, 5002, 5003]
}
```

**Response:**
```json
{
  "success": true,
  "marked_count": 3
}
```

## FCM Integration

### Server-Side FCM Setup

Install Firebase Admin SDK:
```bash
npm install firebase-admin
```

Initialize in your Node.js server:
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
```

### Send Notification Function
```javascript
async function sendPushNotification(fcmToken, title, body, data) {
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: data, // Must be strings
    android: {
      priority: 'high',
      notification: {
        channelId: 'default',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
}
```

### Send to Role/Topic
```javascript
async function sendToTopic(topic, title, body, data) {
  const message = {
    topic: topic, // e.g., 'buyers', 'sellers', 'admins'
    notification: { title, body },
    data: data,
  };

  return await admin.messaging().send(message);
}
```

## Response Formats

### Success Response
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation completed successfully"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "SYNC_CONFLICT",
    "message": "Data conflict detected",
    "details": {
      "conflicting_items": [1001, 1002]
    }
  }
}
```

### Conflict Response (409)
```json
{
  "success": false,
  "error": {
    "code": "CONFLICT",
    "message": "Resource has been modified",
    "current_version": {
      /* current server data */
    },
    "your_version": {
      /* client data */
    }
  }
}
```

## Error Handling

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (data mismatch)
- `500` - Internal Server Error

### Retry Logic
Mobile app implements exponential backoff:
- Initial delay: 1 second
- Max delay: 10 seconds
- Max retries: 3
- Retry on: Network errors, 5xx errors

## Implementation Examples

### Example 1: Ticket Sync Endpoint (Node.js/Express)

```javascript
app.post('/api/sync/tickets', authenticateToken, async (req, res) => {
  try {
    const { tickets } = req.body;
    const userId = req.user.id;

    const synced = [];
    const conflicts = [];

    for (const ticket of tickets) {
      // Check if barcode exists
      const existing = await db.query(
        'SELECT * FROM tickets WHERE barcode = $1',
        [ticket.barcode]
      );

      if (existing.rows.length > 0) {
        conflicts.push({
          barcode: ticket.barcode,
          reason: 'Barcode already exists',
          existing: existing.rows[0]
        });
        continue;
      }

      // Insert ticket
      const result = await db.query(
        `INSERT INTO tickets 
        (barcode, category, price, status, buyer_id, seller_id, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
        RETURNING *`,
        [
          ticket.barcode,
          ticket.category,
          ticket.price,
          ticket.status,
          ticket.buyer_id,
          ticket.seller_id,
          ticket.created_at
        ]
      );

      synced.push(result.rows[0]);
    }

    res.json({
      success: true,
      synced: synced.length,
      conflicts: conflicts,
      tickets: synced
    });
  } catch (error) {
    console.error('Sync error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Sync failed', details: error.message }
    });
  }
});
```

### Example 2: FCM Token Registration

```javascript
app.post('/api/fcm/register', authenticateToken, async (req, res) => {
  try {
    const { token, platform } = req.body;
    const userId = req.user.id;

    // Deactivate old tokens for this user/device
    await db.query(
      'UPDATE fcm_tokens SET active = false WHERE user_id = $1',
      [userId]
    );

    // Insert new token
    await db.query(
      `INSERT INTO fcm_tokens (user_id, token, platform, active, created_at)
      VALUES ($1, $2, $3, true, NOW())
      ON CONFLICT (token) DO UPDATE SET 
        user_id = $1, 
        platform = $2, 
        active = true, 
        updated_at = NOW()`,
      [userId, token, platform]
    );

    // Subscribe to role-based topic
    const userRole = req.user.role;
    await admin.messaging().subscribeToTopic(token, userRole.toLowerCase());
    await admin.messaging().subscribeToTopic(token, 'all_users');

    res.json({
      success: true,
      message: 'Token registered successfully'
    });
  } catch (error) {
    console.error('Token registration error:', error);
    res.status(500).json({
      success: false,
      error: { message: 'Token registration failed' }
    });
  }
});
```

### Example 3: Send Notification on Ticket Purchase

```javascript
async function notifyTicketPurchase(ticketId, buyerId) {
  // Get buyer's FCM token
  const tokens = await db.query(
    'SELECT token FROM fcm_tokens WHERE user_id = $1 AND active = true',
    [buyerId]
  );

  if (tokens.rows.length === 0) {
    console.log('No active tokens for user', buyerId);
    return;
  }

  // Get ticket details
  const ticket = await db.query(
    'SELECT * FROM tickets WHERE id = $1',
    [ticketId]
  );

  // Save notification to database
  const notification = await db.query(
    `INSERT INTO notifications (user_id, type, title, body, data, created_at)
    VALUES ($1, $2, $3, $4, $5, NOW())
    RETURNING *`,
    [
      buyerId,
      'ticket_purchase',
      'Ticket Purchase Confirmed',
      `Your ticket ${ticket.rows[0].barcode} has been purchased successfully`,
      JSON.stringify({ ticket_id: ticketId, barcode: ticket.rows[0].barcode })
    ]
  );

  // Send FCM notification
  for (const tokenRow of tokens.rows) {
    try {
      await sendPushNotification(
        tokenRow.token,
        'Ticket Purchase Confirmed',
        `Your ticket ${ticket.rows[0].barcode} has been purchased`,
        {
          type: 'ticket_purchase',
          ticket_id: ticketId.toString(),
          barcode: ticket.rows[0].barcode,
          notification_id: notification.rows[0].id.toString()
        }
      );
    } catch (error) {
      console.error('Failed to send to token:', tokenRow.token, error);
      // Mark token as inactive if expired
      if (error.code === 'messaging/registration-token-not-registered') {
        await db.query(
          'UPDATE fcm_tokens SET active = false WHERE token = $1',
          [tokenRow.token]
        );
      }
    }
  }
}
```

## Database Schema

### FCM Tokens Table
```sql
CREATE TABLE fcm_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  platform VARCHAR(10) CHECK (platform IN ('ios', 'android')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX idx_fcm_tokens_active ON fcm_tokens(active);
```

### Notifications Table
```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
```

## Testing

### Test Sync Endpoint
```bash
curl -X POST http://localhost:3000/api/sync/tickets \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tickets": [
      {
        "barcode": "TEST-001",
        "category": "BAS",
        "price": 50,
        "status": "available",
        "seller_id": 1,
        "created_at": "2024-01-15T10:00:00Z"
      }
    ]
  }'
```

### Test FCM Token Registration
```bash
curl -X POST http://localhost:3000/api/fcm/register \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "test-fcm-token",
    "platform": "android"
  }'
```

## Security Checklist

- [ ] All endpoints require authentication
- [ ] Validate user permissions (sellers can only sync their tickets)
- [ ] Sanitize input data
- [ ] Rate limit sync endpoints
- [ ] Validate FCM tokens
- [ ] Encrypt sensitive data in transit (HTTPS)
- [ ] Log sync operations for audit
- [ ] Handle token expiration gracefully

## Monitoring

Track these metrics:
- Sync request rate and latency
- Conflict rate
- FCM delivery rate
- Failed notification deliveries
- Token expiration rate

## Support

For backend implementation questions:
- Review existing API endpoints in `raffle-app/server.js`
- Check Firebase Admin SDK documentation
- Test with Postman or curl
