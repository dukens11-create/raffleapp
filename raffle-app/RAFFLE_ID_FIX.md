# Database Schema Fix - raffle_id Column in Tickets Table

## Problem

The application was failing with the error:
```
Failed to generate ABC tickets: column "raffle_id" of relation "tickets" does not exist
```

## Root Cause

The `tickets` table in PostgreSQL was missing proper constraints on the `raffle_id` column:
- Missing NOT NULL constraint
- Missing foreign key constraint to `raffles(id)`
- Missing index for performance

## Solution Implemented

### 1. Migration File (`migrations/add_raffle_id_to_tickets.sql`)

Created an idempotent PostgreSQL migration that:
- ✅ Adds `raffle_id` column if it doesn't exist
- ✅ Sets default value (`raffle_id = 1`) for existing rows with NULL
- ✅ Adds NOT NULL constraint
- ✅ Adds foreign key constraint with CASCADE delete
- ✅ Creates performance index `idx_tickets_raffle_id`
- ✅ Safe to run multiple times (idempotent)

### 2. Schema Update (`db.js`)

Updated the `CREATE TABLE` statement for tickets:
```sql
-- Before:
raffle_id INTEGER,

-- After:
raffle_id INTEGER NOT NULL REFERENCES raffles(id) ON DELETE CASCADE,
```

This ensures new databases are created with the correct schema from the start.

### 3. Migration Runner (`server.js`)

Added automatic migration runner that:
- ✅ Runs after database schema initialization
- ✅ Only runs for PostgreSQL (skips SQLite)
- ✅ Executes migration SQL from file
- ✅ Safe - won't crash server on errors
- ✅ Logs migration results

## How It Works

### On Server Startup:

1. **Initialize Schema** - Creates tables if they don't exist
2. **Run Migrations** - Applies schema updates to existing tables
3. **Validate Setup** - Checks database configuration

### Migration Flow:

```
Server Start
    ↓
db.initializeSchema()
    ↓
runMigrations()
    ↓
validateDatabaseSetup()
    ↓
Server Ready
```

## Testing

Run the validation script:
```bash
cd raffle-app
node test-raffle-id-fix.js
```

Expected output:
- ✅ All checks pass
- ✅ Migration file exists with correct SQL
- ✅ Schema includes NOT NULL constraint
- ✅ Foreign key reference present
- ✅ Migration runner configured

## Deployment

### For Render (PostgreSQL):

The migration runs automatically on server startup:

1. Deploy the updated code to Render
2. Server starts and runs `db.initializeSchema()`
3. Migration executes: `runMigrations()`
4. Check logs for: `✅ Migrations completed successfully`
5. Ticket generation should now work without errors

### Manual Migration (if needed):

If you need to run the migration manually:

```bash
# Connect to PostgreSQL
psql $DATABASE_URL

# Run migration
\i raffle-app/migrations/add_raffle_id_to_tickets.sql

# Verify
\d tickets
```

## Verification

### Check Column Exists:
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tickets' AND column_name = 'raffle_id';
```

Expected result:
```
 column_name | data_type | is_nullable 
-------------+-----------+-------------
 raffle_id   | integer   | NO
```

### Check Foreign Key:
```sql
SELECT constraint_name, table_name 
FROM information_schema.table_constraints 
WHERE constraint_name = 'fk_tickets_raffle';
```

Expected result:
```
 constraint_name  | table_name 
------------------+------------
 fk_tickets_raffle| tickets
```

### Check Index:
```sql
SELECT indexname FROM pg_indexes 
WHERE tablename = 'tickets' AND indexname = 'idx_tickets_raffle_id';
```

Expected result:
```
      indexname       
----------------------
 idx_tickets_raffle_id
```

## Success Criteria

- ✅ `raffle_id` column exists with NOT NULL constraint
- ✅ Foreign key constraint added (`fk_tickets_raffle`)
- ✅ Index created for performance (`idx_tickets_raffle_id`)
- ✅ Existing tickets updated with `raffle_id = 1`
- ✅ Ticket generation works without errors
- ✅ No "column does not exist" errors

## Files Changed

1. `raffle-app/migrations/add_raffle_id_to_tickets.sql` - New migration file
2. `raffle-app/db.js` - Updated tickets table schema
3. `raffle-app/server.js` - Added migration runner
4. `raffle-app/test-raffle-id-fix.js` - Validation script

## Rollback (if needed)

If you need to rollback:

```sql
-- Remove constraints
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS fk_tickets_raffle;
DROP INDEX IF EXISTS idx_tickets_raffle_id;
ALTER TABLE tickets ALTER COLUMN raffle_id DROP NOT NULL;
```

⚠️ **Warning**: Rollback is not recommended as the application code expects `raffle_id` to be NOT NULL.

## Additional Notes

- Migration is **idempotent** - safe to run multiple times
- Works only with **PostgreSQL** (SQLite handling is different)
- **No data loss** - existing tickets are updated, not deleted
- **Automatic** - runs on every server startup
- **Safe** - migration errors don't crash the server
