# Buyer Available Tickets API

## Endpoint

```
GET /api/buyer/available-tickets
```

## Description

Returns the last 100,000 available tickets per category that are available for online purchase. Tickets are grouped by category and ordered by most recent (created_at DESC).

## Authentication

This is a public endpoint and does not require authentication.

## Query Parameters

None required.

## Response Format

### Success Response (200 OK)

```json
{
  "categories": {
    "ABC": [
      {
        "ticket_number": "ABC-375000",
        "barcode": "12345678",
        "category": "ABC",
        "price": 100.00,
        "status": "AVAILABLE",
        "created_at": "2024-01-15T10:30:00Z"
      },
      ...
    ],
    "EFG": [...],
    "JKL": [...],
    "XYZ": [...]
  },
  "timestamp": "2024-01-15T12:00:00Z"
}
```

### Error Responses

#### No Active Raffle (404 Not Found)

```json
{
  "error": "No active raffle found",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

#### No Tickets Available (200 OK)

```json
{
  "message": "No tickets available for online purchase",
  "categories": {},
  "timestamp": "2024-01-15T12:00:00Z"
}
```

#### Server Error (500 Internal Server Error)

```json
{
  "error": "Failed to fetch available tickets",
  "message": "Database connection error",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

## Filters Applied

The endpoint automatically filters tickets based on:
- `status = 'AVAILABLE'` - Only available tickets
- `available_online = true` - Only tickets marked for online sale
- Active raffle only - Tickets from the currently active raffle

## Limits

- Maximum 100,000 tickets per category
- Tickets are ordered by `created_at DESC` (most recent first)

## Example Usage

### cURL

```bash
curl -X GET http://localhost:10000/api/buyer/available-tickets
```

### JavaScript (Fetch API)

```javascript
fetch('http://localhost:10000/api/buyer/available-tickets')
  .then(response => response.json())
  .then(data => {
    console.log('Categories:', Object.keys(data.categories));
    console.log('ABC tickets:', data.categories.ABC?.length || 0);
    console.log('EFG tickets:', data.categories.EFG?.length || 0);
    console.log('JKL tickets:', data.categories.JKL?.length || 0);
    console.log('XYZ tickets:', data.categories.XYZ?.length || 0);
  })
  .catch(error => console.error('Error:', error));
```

### Python (requests)

```python
import requests

response = requests.get('http://localhost:10000/api/buyer/available-tickets')
data = response.json()

if 'categories' in data:
    for category, tickets in data['categories'].items():
        print(f"{category}: {len(tickets)} tickets available")
```

## Implementation Details

- **Database Support**: Works with both PostgreSQL and SQLite
- **Performance**: Uses indexed queries with LIMIT for efficient data retrieval
- **Security**: Parameterized queries prevent SQL injection
- **Error Handling**: Comprehensive error handling with clear diagnostic messages
- **Logging**: Request and response logging for debugging

## Related Endpoints

- `GET /api/public/available-tickets` - Paginated list of available tickets
- `GET /api/public/ticket-availability` - Ticket counts by category
- `POST /api/public/purchase/initiate` - Initiate ticket purchase

## Notes

- The endpoint returns up to 100,000 tickets per category to prevent large response sizes
- Tickets are ordered by most recent first (created_at DESC)
- Only tickets from the active raffle are returned
- The endpoint is rate-limited along with other API endpoints (100 requests per 15 minutes by default)
