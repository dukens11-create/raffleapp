# Migration Instructions: Update Raffle Name to GRATE GENYEN

## Overview
This migration updates existing raffle names from "Grand Raffle 2026", "Default Raffle", or "Grate Genyen Raffle" to the standardized "GRATE GENYEN" branding.

## Running the Migration

### Option 1: Using npm script (Recommended)
```bash
cd raffle-app
npm run migrate:raffle-name
```

### Option 2: Using node directly
```bash
cd raffle-app
node migrations/update-raffle-name.js
```

## What the Migration Does

1. **Updates raffle names** - Changes old raffle names to "GRATE GENYEN"
2. **Updates descriptions** - Sets description to "Official Grate Genyen raffle for ticket sales"
3. **Shows results** - Displays how many records were updated
4. **Lists all raffles** - Shows current state of all raffles after migration

## Safety Features

- ✅ **Safe to run multiple times** - Only updates raffles with old names
- ✅ **Works with both databases** - Compatible with PostgreSQL and SQLite
- ✅ **No data loss** - Only updates name and description fields
- ✅ **Verification included** - Shows all raffles after update

## Expected Output

```
🔄 Starting raffle name migration...
Database type: SQLite
✅ Updated 1 raffle record(s)

📋 Current raffles:
  - ID 1: GRATE GENYEN

✅ Migration completed successfully
Migration finished successfully
```

## After Migration

Once the migration is complete:
- ✅ Buyer portal will show "GRATE GENYEN" in the Raffle Info section
- ✅ Flutter app will show "GRATE GENYEN" on the home screen
- ✅ All API responses will return the updated raffle name
- ✅ New raffles will automatically use "GRATE GENYEN"

## Troubleshooting

### Migration doesn't find any raffles
This is normal if no raffles exist yet. The system will create a new raffle with the correct name on startup.

### Database connection errors
- Check that you're in the `raffle-app` directory
- Verify `DATABASE_URL` environment variable is set (for PostgreSQL)
- For SQLite, ensure `raffle.db` file exists

### Need to rollback?
To restore old names, manually update the database:
```sql
UPDATE raffles 
SET name = 'Default Raffle', 
    description = 'Default raffle for ticket sales'
WHERE name = 'GRATE GENYEN';
```

## Questions?
See the main README.md or contact the development team.
