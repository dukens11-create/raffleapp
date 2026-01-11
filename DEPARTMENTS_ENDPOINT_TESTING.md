# Testing Instructions: Public Departments API Endpoint

## Overview
This document provides testing instructions for the new `GET /api/public/departments` endpoint that returns all Haiti departments from the database.

## Endpoint Details
- **URL**: `/api/public/departments`
- **Method**: `GET`
- **Authentication**: None required (public endpoint)
- **Description**: Returns all Haiti departments ordered alphabetically by name

## Expected Response Format

### Success Response (200 OK)
```json
[
  {
    "id": 1,
    "name": "Artibonite",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 2,
    "name": "Centre",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 3,
    "name": "Grand'Anse",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 4,
    "name": "Nippes",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 5,
    "name": "Nord",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 6,
    "name": "Nord-Est",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 7,
    "name": "Nord-Ouest",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 8,
    "name": "Ouest",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 9,
    "name": "Sud",
    "created_at": "2026-01-11 07:29:24"
  },
  {
    "id": 10,
    "name": "Sud-Est",
    "created_at": "2026-01-11 07:29:24"
  }
]
```

### Error Response (500 Internal Server Error)
```json
{
  "error": "Could not fetch departments"
}
```

## Testing with curl

### Basic Test
Test the endpoint after the server is running:

```bash
curl http://localhost:10000/api/public/departments
```

### Test with Pretty-Print (jq)
If you have `jq` installed, you can pretty-print the JSON response:

```bash
curl -s http://localhost:10000/api/public/departments | jq .
```

### Test with Headers
To see the full HTTP response including headers:

```bash
curl -i http://localhost:10000/api/public/departments
```

### Test on Production (Render)
Replace `YOUR_DOMAIN` with your actual Render domain:

```bash
curl https://YOUR_DOMAIN.onrender.com/api/public/departments
```

## Verification Checklist

After running the endpoint, verify the following:

- [ ] Response returns an array of 10 departments
- [ ] Departments are ordered alphabetically (Artibonite first, Sud-Est last)
- [ ] Each department object has: `id`, `name`, and `created_at` fields
- [ ] All 10 Haiti departments are present:
  - Artibonite
  - Centre
  - Grand'Anse
  - Nippes
  - Nord
  - Nord-Est
  - Nord-Ouest
  - Ouest
  - Sud
  - Sud-Est
- [ ] Response content-type is `application/json`
- [ ] No authentication is required to access the endpoint
- [ ] Error handling works (test by stopping database connection)

## Database Verification

### Check Database Contents (SQLite)
```bash
cd raffle-app
sqlite3 raffle.db "SELECT * FROM departments ORDER BY name;"
```

### Check Database Contents (PostgreSQL)
```bash
psql $DATABASE_URL -c "SELECT * FROM departments ORDER BY name;"
```

## Integration Testing

### Test with Buyer Portal
1. Open the buyer portal in your browser
2. Navigate to the department dropdown field
3. Verify that all 10 departments appear in alphabetical order
4. Verify selecting a department works correctly

### Test Department Selection
1. Select a department from the dropdown
2. Complete a test purchase
3. Verify the department is saved correctly in the database:
   ```sql
   SELECT customer_department FROM tickets WHERE buyer_phone = 'YOUR_TEST_PHONE';
   ```

## Restart Instructions

⚠️ **IMPORTANT**: After merging this PR, you must restart the Node.js backend for changes to take effect.

### On Render
Changes are automatically deployed when pushed to the main branch. The service will restart automatically.

### Local Development
Stop and restart your Node.js server:
```bash
# Stop the server (Ctrl+C)
# Start again
cd raffle-app
npm start
```

### Docker
```bash
docker-compose restart backend
```

## Troubleshooting

### Issue: Empty Array Returned
**Cause**: Departments table is empty  
**Solution**: The database initialization should auto-populate the table. If not, manually run:
```sql
INSERT INTO departments (name) VALUES 
  ('Artibonite'),
  ('Centre'),
  ('Grand''Anse'),
  ('Nippes'),
  ('Nord'),
  ('Nord-Est'),
  ('Nord-Ouest'),
  ('Ouest'),
  ('Sud'),
  ('Sud-Est');
```

### Issue: 500 Error Returned
**Cause**: Database connection issues  
**Solution**: 
1. Check DATABASE_URL is set correctly
2. Verify database is running
3. Check server logs for detailed error messages

### Issue: 404 Not Found
**Cause**: Server not running or incorrect URL  
**Solution**:
1. Verify server is running: `curl http://localhost:10000/health`
2. Check you're using the correct URL: `/api/public/departments` (not `/api/departments`)

### Issue: CORS Error (Browser)
**Cause**: Frontend domain not in allowed origins  
**Solution**: Add your domain to ALLOWED_ORIGINS environment variable

## Performance Notes

- This endpoint is lightweight and returns a small, fixed dataset (10 rows)
- No pagination is needed as the result set is always 10 departments
- Results are not cached as they are static and quick to query
- Query uses an index on the `name` column for sorting

## Security Notes

- ✅ Endpoint is public (no authentication required) - this is intentional
- ✅ No sensitive data is exposed (only department names)
- ✅ SQL injection is prevented by using parameterized queries
- ✅ Error messages don't leak sensitive information
- ✅ Endpoint is included in public API paths whitelist for request validation
