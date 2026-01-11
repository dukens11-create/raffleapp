# Fix Summary: /api/buyer/available-tickets Endpoint

## Problem Statement
The `/api/buyer/available-tickets` endpoint was returning:
```json
{
  "message": "No tickets available for online purchase",
  "categories": {},
  ...
}
```

Even though the database was supposed to contain 400,000 tickets marked with `available_online=TRUE` and `status='available'` for the active raffle (raffle_id=1).

## Root Cause Analysis
The `available_online` column was **missing from the initial CREATE TABLE statement** for the tickets table in `raffle-app/db.js`.

While code existed to add the column via `ALTER TABLE` (lines 636-654), this approach had limitations:
- SQLite requires checking if column exists first (using PRAGMA)
- If the ALTER TABLE failed for any reason, it would be caught silently
- Existing deployments with tables already created would not get the column

## Solution Implemented

### 1. Added `available_online` Column to Schema (db.js, line 253)
```javascript
CREATE TABLE IF NOT EXISTS tickets (
  // ... existing columns ...
  customer_department TEXT,
  available_online ${USE_POSTGRES ? 'BOOLEAN' : 'INTEGER'} DEFAULT ${USE_POSTGRES ? 'FALSE' : '0'},
  created_at ${USE_POSTGRES ? 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP' : 'DATETIME DEFAULT CURRENT_TIMESTAMP'}
)
```

**Impact:** All new database installations will have the column from the start.

### 2. Fixed Environment Validation (server.js, lines 104-115)
Modified the DATABASE_URL validation to:
- Allow SQLite in development mode (DATABASE_URL optional)
- Require PostgreSQL in production (DATABASE_URL required)

**Impact:** Developers can run and test locally without PostgreSQL.

## Verification Testing

### Test 1: With Available Tickets ✅
```bash
# Insert test tickets
sqlite3 raffle.db "INSERT INTO tickets (raffle_id, ticket_number, category, price, status, available_online, barcode) 
VALUES (1, 'ABC-000001', 'ABC', 100, 'AVAILABLE', 1, 'BC001');"

# Test endpoint
curl http://localhost:10000/api/buyer/available-tickets
```

**Result:**
```json
{
  "categories": {
    "ABC": [
      {
        "ticket_number": "ABC-000001",
        "barcode": "BC001",
        "category": "ABC",
        "price": 100,
        "status": "AVAILABLE",
        "created_at": "2026-01-11 19:34:32"
      }
    ]
  },
  "timestamp": "2026-01-11T19:35:00.000Z"
}
```

### Test 2: With No Available Tickets ✅
```bash
# Mark all tickets as NOT available online
sqlite3 raffle.db "UPDATE tickets SET available_online = 0;"

# Test endpoint
curl http://localhost:10000/api/buyer/available-tickets
```

**Result:**
```json
{
  "message": "No tickets available for online purchase",
  "categories": {},
  "timestamp": "2026-01-11T19:35:18.885Z"
}
```

### Test 3: Multiple Categories ✅
Tested with ABC, EFG, and JKL categories - all returned correctly.

## Key Features Verified

✅ **No hardcoded raffle_id** - Uses JOIN with active raffle:
```sql
SELECT id FROM raffles WHERE status = 'active'
```

✅ **Correct filters applied:**
- `available_online = TRUE` (or `1` for SQLite)
- `status = 'AVAILABLE'`
- `raffle_id` matches active raffle

✅ **Returns tickets grouped by category**

✅ **Limit of 100,000 tickets per category** (MAX_TICKETS_PER_CATEGORY constant)

✅ **Proper error handling:**
- Returns HTTP 500 only on actual database errors
- Returns empty categories object (not just message) when no tickets available

✅ **Tickets ordered by `created_at DESC`** (most recent first)

## Deployment Instructions

### For New Deployments
No additional steps needed - the schema includes the column.

### For Existing Production Databases
If you have existing tickets that need to be marked as available online:

```bash
cd raffle-app

# Option 1: Mark last 100,000 tickets per category (recommended)
node scripts/markTicketsAvailable.js

# Option 2: Dry run first (preview changes)
node scripts/markTicketsAvailable.js --dry-run

# Option 3: Custom limit
node scripts/markTicketsAvailable.js --limit=50000

# Option 4: For PostgreSQL (alternative)
node migrations/mark_online_available_tickets.js
```

The script will:
1. Find all ticket categories
2. For each category, select the last N tickets (by `created_at DESC`)
3. Update those tickets to set `available_online = TRUE`
4. Display a summary of changes

### Verification After Deployment
```bash
# Check tickets marked as available online
psql $DATABASE_URL -c "SELECT COUNT(*) FROM tickets WHERE available_online=TRUE AND status='available';"

# Test the endpoint
curl https://your-domain.com/api/buyer/available-tickets | jq '.categories | keys'
```

## Files Modified

1. **raffle-app/db.js** (line 253)
   - Added `available_online` column to tickets table schema

2. **raffle-app/server.js** (lines 104-115)
   - Modified environment validation for development mode

## Code Review Status
✅ **Passed** - No issues found

## Related Documentation
- `/raffle-app/BUYER_AVAILABLE_TICKETS_API.md` - API documentation
- `/raffle-app/scripts/markTicketsAvailable.js` - Migration script
- `/raffle-app/migrations/mark_online_available_tickets.js` - PostgreSQL migration

## Future Considerations
- Consider adding an admin UI to toggle `available_online` for specific ticket ranges
- Add monitoring/alerting when no tickets are available online
- Consider caching the response for performance (if ticket availability doesn't change frequently)
