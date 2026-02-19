# API Integration Guide

## Overview

This guide explains how to integrate with the Grate Genyen backend API.

## Base Configuration

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://api.grategenyen.com';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

## Authentication

### Login
```dart
POST /api/auth/login
Content-Type: application/json

{
  "phone": "1234567890",
  "password": "password123"
}

Response:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user123",
    "phone": "1234567890",
    "role": "buyer"
  }
}
```

### Token Management
All authenticated requests must include the Bearer token:
```dart
Authorization: Bearer <token>
```

## Ticket Endpoints

### Get Available Tickets
```dart
GET /api/tickets/available
Query Parameters:
  - category: string (optional)
  - limit: number (optional)
  - offset: number (optional)

Response:
{
  "tickets": [
    {
      "id": "ticket123",
      "category": "Premium",
      "price": 100,
      "available": true
    }
  ]
}
```

### Purchase Ticket
```dart
POST /api/tickets/purchase
Content-Type: application/json
Authorization: Bearer <token>

{
  "ticketId": "ticket123",
  "paymentMethod": "moncash",
  "transactionId": "txn123"
}

Response:
{
  "success": true,
  "ticketNumber": "RAFF-12345",
  "message": "Ticket purchased successfully"
}
```

## Payment Endpoints

### Initiate MonCash Payment
```dart
POST /api/payments/moncash/initiate
Authorization: Bearer <token>

{
  "amount": 100,
  "orderId": "order123"
}

Response:
{
  "paymentUrl": "https://moncash.com/payment/...",
  "transactionId": "txn123"
}
```

### Verify Payment
```dart
GET /api/payments/verify/{transactionId}
Authorization: Bearer <token>

Response:
{
  "success": true,
  "status": "completed",
  "amount": 100
}
```

## Error Handling

API errors follow this format:
```json
{
  "success": false,
  "error": {
    "code": "AUTH_ERROR",
    "message": "Invalid credentials"
  }
}
```

## Rate Limiting

- 100 requests per minute per user
- 429 status code when limit exceeded
- Retry-After header indicates wait time

## Best Practices

1. Always check response status codes
2. Implement exponential backoff for retries
3. Cache responses when appropriate
4. Handle network errors gracefully
5. Use request timeouts
