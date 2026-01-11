# `/api/public/raffle-info` Endpoint Documentation

## Overview

The `/api/public/raffle-info` endpoint returns information about the current active raffle, including categories, pricing, and ticket statistics.

## Endpoint Details

- **URL:** `/api/public/raffle-info`
- **Method:** `GET`
- **Authentication:** None required (public endpoint)
- **Location:** `raffle-app/server.js:4763`

## Implementation

### Database Query
```sql
SELECT id, name, description, start_date, draw_date, status, total_tickets
FROM raffles 
WHERE status = 'active'
ORDER BY created_at DESC 
LIMIT 1
```

### Code Implementation
```javascript
app.get('/api/public/raffle-info', async (req, res) => {
  try {
    // Get the active raffle
    const raffle = await db.get(`
      SELECT id, name, description, start_date, draw_date, status, total_tickets
      FROM raffles 
      WHERE status = 'active'
      ORDER BY created_at DESC 
      LIMIT 1
    `);
    
    if (!raffle) {
      return res.status(404).json({ error: 'No active raffle found' });
    }
    
    // Get ticket categories and statistics
    // ... additional queries for categories and stats
    
    res.json({
      raffle: { /* raffle data */ },
      categories: [ /* categories array */ ],
      stats: { /* statistics */ }
    });
  } catch (error) {
    console.error('Error fetching raffle info:', error);
    res.status(500).json({ error: 'Failed to fetch raffle information' });
  }
});
```

## Response Examples

### Success Response (HTTP 200)

```json
{
  "raffle": {
    "name": "Default Raffle 2024",
    "description": "Official raffle with 4 ticket categories",
    "start_date": "2024-01-01",
    "draw_date": "2024-12-31",
    "status": "active"
  },
  "categories": [
    {
      "category_code": "ABC",
      "category_name": "Bronze",
      "price": 50,
      "color": "#CD7F32",
      "description": "Bronze tier tickets",
      "online_available": 10000,
      "online_total": 100000
    },
    {
      "category_code": "EFG",
      "category_name": "Silver",
      "price": 100,
      "color": "#C0C0C0",
      "description": "Silver tier tickets",
      "online_available": 8000,
      "online_total": 100000
    }
  ],
  "stats": {
    "total_tickets": 1500000,
    "sold_tickets": 50000,
    "available_tickets": 1450000,
    "online_available_total": 400000,
    "online_available_now": 380000
  }
}
```

### No Active Raffle (HTTP 404)

```json
{
  "error": "No active raffle found"
}
```

### Database Error (HTTP 500)

```json
{
  "error": "Failed to fetch raffle information"
}
```

## Testing Examples

### Using cURL

```bash
# Get active raffle info
curl http://localhost:3000/api/public/raffle-info

# Get with formatted output
curl http://localhost:3000/api/public/raffle-info | jq .

# Check HTTP status
curl -w "\nHTTP Status: %{http_code}\n" http://localhost:3000/api/public/raffle-info
```

### Using JavaScript (Fetch API)

```javascript
// Fetch raffle info
fetch('/api/public/raffle-info')
  .then(response => {
    if (response.status === 404) {
      console.log('No active raffle found');
      return null;
    }
    if (!response.ok) {
      throw new Error('Failed to fetch raffle info');
    }
    return response.json();
  })
  .then(data => {
    if (data) {
      console.log('Raffle:', data.raffle);
      console.log('Categories:', data.categories);
      console.log('Stats:', data.stats);
    }
  })
  .catch(error => {
    console.error('Error:', error);
  });
```

### Using Python (requests)

```python
import requests

response = requests.get('http://localhost:3000/api/public/raffle-info')

if response.status_code == 404:
    print('No active raffle found')
elif response.status_code == 200:
    data = response.json()
    print('Raffle:', data['raffle'])
    print('Categories:', data['categories'])
    print('Stats:', data['stats'])
else:
    print(f'Error: {response.status_code}')
```

## Error Handling

The endpoint implements comprehensive error handling:

1. **No Active Raffle (404):** Returns when no raffle with `status = 'active'` exists
2. **Database Error (500):** Returns when database query fails, error logged to console
3. **Malformed Request:** Returns 500 with generic error message

All errors are logged to the server console for debugging:

```
Error fetching raffle info: Error: SQLITE_ERROR: no such table: raffles
```

## Database Schema

### Raffles Table

```sql
CREATE TABLE raffles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  start_date TEXT,
  draw_date TEXT,
  status TEXT DEFAULT 'draft',
  total_tickets INTEGER DEFAULT 1500000,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Required Status Values
- `active` - Currently active raffle (returned by endpoint)
- `draft` - Draft raffle (not returned)
- `completed` - Finished raffle (not returned)

## Security Considerations

1. **Public Access:** No authentication required (intended for public access)
2. **Read-Only:** GET method only, no modifications allowed
3. **Specific Columns:** Query selects specific columns instead of `SELECT *`
4. **Error Messages:** Generic error messages to avoid leaking database details
5. **Rate Limiting:** Protected by general API rate limiter (100 requests per 15 min)

## Integration Notes

### For Frontend Developers

The endpoint is located in the public API namespace and requires no authentication. Simply make a GET request to retrieve current raffle information for display to users.

### For Backend Developers

- Database connection: Uses `db` module which supports both SQLite and PostgreSQL
- Query pattern follows the existing codebase standards
- Error handling uses standard Express error response pattern
- Logging uses `console.error` for database errors

## Minimal Server Setup Example

If you need to run just this endpoint in isolation, here's a minimal setup:

```javascript
const express = require('express');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const db = new sqlite3.Database('./raffle.db');

// Helper to convert callback to promise
const dbGet = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row || null);
    });
  });
};

// Endpoint
app.get('/api/public/raffle-info', async (req, res) => {
  try {
    const raffle = await dbGet(
      `SELECT * FROM raffles WHERE status = "active" LIMIT 1`
    );
    
    if (!raffle) {
      return res.status(404).json({ error: 'No active raffle found' });
    }
    
    res.json({ raffle });
  } catch (error) {
    console.error('Error fetching raffle info:', error);
    res.status(500).json({ error: 'Failed to fetch raffle information' });
  }
});

// Start server
app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## Related Endpoints

- `GET /api/public/available-tickets` - Get list of available tickets
- `GET /api/public/ticket-availability` - Get ticket availability by category
- `GET /api/public/verify-ticket/:ticketNumber` - Verify a ticket

## Support

For issues or questions about this endpoint, refer to:
- Server logs: Check console output for error messages
- Database: Verify `raffles` table exists with `status` column
- Network: Ensure server is running on correct port
