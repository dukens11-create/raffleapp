# Available Tickets Display Feature - Implementation Guide

## Overview

This feature enables buyers to browse and view the last 100,000 available tickets for each category in the raffle buyer portal. The implementation includes both backend API enhancements and frontend UI improvements.

## Features Implemented

### Backend (API)

#### Enhanced `/api/public/available-tickets` Endpoint

**URL**: `GET /api/public/available-tickets`

**Query Parameters**:
- `page` (integer, default: 1) - Page number for pagination
- `limit` (integer, default: 100, max: 100) - Number of tickets per page
- `category` (string, optional) - Filter by specific category code (e.g., "ABC", "EFG", "JKL", "XYZ")
- `search` (string, optional) - Search for specific ticket numbers (partial match)
- `groupByCategory` (boolean, default: false) - Include category statistics in response

**Response Format**:
```json
{
  "tickets": [
    {
      "ticket_number": "ABC-000250",
      "category": "ABC",
      "price": 50.00,
      "status": "AVAILABLE",
      "created_at": "2026-01-11T16:31:07.859Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 100,
    "total": 600,
    "total_pages": 6
  },
  "categoryGroups": [
    {
      "category": "ABC",
      "count": 150,
      "first_ticket": "ABC-000101",
      "last_ticket": "ABC-000250"
    }
  ]
}
```

**Key Features**:
- Returns tickets ordered by `created_at DESC` to show the most recently generated (last 100K)
- Only shows tickets with `status = 'AVAILABLE'` and `available_online = TRUE`
- Supports filtering by category
- Supports search by ticket number
- Includes category statistics when `groupByCategory=true`
- Efficient database queries with proper indexing

### Frontend (Buyer Portal UI)

#### Enhanced Available Tickets Tab

**Location**: `/buyers.html` - "Available Tickets" tab

**UI Components**:

1. **Category Filter Dropdown**
   - Filter tickets by specific category (ABC, EFG, JKL, XYZ)
   - Shows "All Categories" by default

2. **Search Box**
   - Search for specific ticket numbers
   - Uses debounced search (500ms delay) for performance
   - Supports partial matching

3. **Category Statistics Cards**
   - Displays available count for each category
   - Shows ticket number ranges (e.g., "ABC-000101 - ABC-000250")
   - Color-coded by category

4. **Tickets Grid Display**
   - Responsive grid layout (adapts to screen size)
   - Each ticket card shows:
     - Ticket number
     - Category code
     - Price
   - Clickable cards that pre-select the ticket in the purchase form

5. **Pagination Controls**
   - First, Previous, Next, Last buttons
   - Page indicator (e.g., "Page 1 of 6")
   - Disabled state for unavailable actions

**Features**:
- Displays 100 tickets per page by default
- Real-time filtering and search
- Smooth transitions and hover effects
- Mobile-responsive design

## Database Schema

### New Indexes Added

The following indexes were added to the `tickets` table for optimal performance:

```sql
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at);
CREATE INDEX IF NOT EXISTS idx_tickets_category_status ON tickets(category, status);
CREATE INDEX IF NOT EXISTS idx_tickets_status_available_online ON tickets(status, available_online);
```

### Required Column

The `available_online` column must exist in the `tickets` table:

```sql
-- For PostgreSQL
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS available_online BOOLEAN DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_tickets_available_online ON tickets(available_online);

-- For SQLite
ALTER TABLE tickets ADD COLUMN available_online INTEGER DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_tickets_available_online ON tickets(available_online);
```

## Setup Instructions

### 1. Database Preparation

1. Ensure the `available_online` column exists (already handled by `db.js` initialization)
2. Mark the last 100,000 tickets of each category as available online:

```sql
-- Example for marking last 100K tickets per category as available online
UPDATE tickets 
SET available_online = TRUE 
WHERE id IN (
  SELECT id FROM tickets 
  WHERE raffle_id = :raffle_id 
    AND category = :category_code
    AND status = 'AVAILABLE'
  ORDER BY created_at DESC 
  LIMIT 100000
);
```

Or use the migration script (if available):
```bash
node migrations/mark_online_available_tickets.js
```

### 2. Test the Feature

**Test API Endpoints**:
```bash
# Get all available tickets with category groups
curl http://localhost:10000/api/public/available-tickets?groupByCategory=true&limit=10

# Filter by category
curl http://localhost:10000/api/public/available-tickets?category=ABC&limit=20

# Search for specific tickets
curl http://localhost:10000/api/public/available-tickets?search=200&limit=10
```

**Test UI**:
1. Navigate to `http://localhost:10000/buyers.html`
2. Click on the "🎫 Available Tickets" tab
3. Test the category filter dropdown
4. Test the search box
5. Test pagination controls
6. Click on a ticket to see it pre-selected in the purchase form

## Technical Details

### Query Performance

The enhanced endpoint uses optimized PostgreSQL queries:

```sql
SELECT ticket_number, category, price, status, created_at
FROM tickets 
WHERE raffle_id = ? 
  AND status = 'AVAILABLE'
  AND available_online = TRUE
  [AND category = ?]  -- optional filter
  [AND ticket_number LIKE ?]  -- optional search
ORDER BY created_at DESC, ticket_number DESC 
LIMIT ? OFFSET ?
```

**Performance Optimizations**:
- Composite indexes on `(status, available_online)` and `(category, status)`
- Index on `created_at` for sorting
- Pagination to limit memory usage
- Default limit of 100 tickets per page

### Category System

The system supports 4 ticket categories:
- **ABC** - Bronze ($50.00)
- **EFG** - Silver ($100.00) 
- **JKL** - Gold ($250.00)
- **XYZ** - Platinum ($500.00)

Categories can be customized via the `ticket_categories` table.

## Files Modified

### Backend
- `/raffle-app/server.js` - Enhanced `/api/public/available-tickets` endpoint
- `/raffle-app/db.js` - Added new indexes for performance

### Frontend
- `/raffle-app/public/buyers.html` - Updated Available Tickets tab UI and JavaScript

### Documentation
- `/AVAILABLE_TICKETS_FEATURE.md` - This file

## Example Usage

### For Administrators

1. **Mark tickets as available online** (when generating new tickets):
```javascript
await db.run(`
  UPDATE tickets 
  SET available_online = TRUE 
  WHERE category = ? 
    AND created_at >= ?
  LIMIT 100000
`, [category, cutoffDate]);
```

2. **Verify counts**:
```bash
curl http://localhost:10000/api/public/available-tickets?groupByCategory=true
```

### For Buyers

1. Visit the Buyer Portal
2. Click "Available Tickets" tab
3. Browse available tickets
4. Filter by category if desired
5. Search for specific ticket numbers
6. Click a ticket to proceed to purchase

## Troubleshooting

### No tickets showing up

**Check**:
1. Are there tickets with `available_online = TRUE` in the database?
2. Is the raffle status `active`?
3. Are tickets marked as `AVAILABLE` (not SOLD or RESERVED)?

**Solution**:
```sql
SELECT category, COUNT(*) 
FROM tickets 
WHERE status = 'AVAILABLE' 
  AND available_online = 1 
GROUP BY category;
```

### Performance issues

**Check**:
1. Are the indexes created?
```sql
SHOW INDEX FROM tickets;  -- MySQL/PostgreSQL
PRAGMA index_list(tickets);  -- SQLite
```

2. Is pagination working correctly?

**Solution**: Ensure indexes exist and increase `limit` parameter cautiously.

### Search not working

**Check**:
1. Is the search query parameter being sent correctly?
2. Does the debounce delay need adjustment?

**Solution**: Check browser console for JavaScript errors.

## Future Enhancements

Potential improvements for this feature:
1. Add bulk ticket selection for purchase
2. Add ticket favoriting/bookmarking
3. Add real-time availability updates via WebSocket
4. Add advanced filtering (price range, specific number patterns)
5. Add ticket preview before purchase
6. Export visible tickets to CSV/PDF

## Support

For questions or issues, please refer to the main README.md or contact the development team.
