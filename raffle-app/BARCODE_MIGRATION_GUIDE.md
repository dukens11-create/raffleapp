# Barcode Migration Guide

## New Feature: Legacy Barcode Support (January 2026)

### Overview

The system now supports **both new and legacy barcode formats** during scanning! This allows sellers to scan tickets with old barcode formats without requiring physical ticket replacement.

### Supported Formats

#### New Format (8-digit) - Primary
- **Format**: `[1-4]XXXXXXX` (8 digits total)
- **Examples**: `10000001`, `20000001`, `30000001`, `40000001`
- **Mapping**: 1=ABC, 2=EFG, 3=JKL, 4=XYZ

#### Legacy Formats - Now Accepted
1. **13-digit EAN-13**: `9780000000001`
2. **Ticket number with dash**: `ABC-000001`
3. **Ticket number without dash**: `ABC000001`
4. **Multiple dashes**: `ABC-000-001`
5. **Pure numeric (6-7 or 9+ digits)**: `000001`, `1000001`
6. **Other alphanumeric (6+ chars)**: Any combination with letters and numbers

### Testing Scenarios

✅ **Successful Scans**:
- 8-digit: `10000001` → Finds ABC-000001
- Legacy 13-digit: `9780000000001` → Finds matching ticket
- Ticket number: `ABC-000001` or `ABC000001` → Finds ticket
- Multiple dashes: `ABC-000-001` → Finds ABC-000001

❌ **Rejected Scans**:
- Empty: `""` → "Barcode is required"
- Special chars only: `###` → "Barcode format not recognized"
- Too short: `ABC` → "Barcode format not recognized"
- Non-existent: `10999999` → "Ticket not found"

### API Changes

**Error Message Update:**
- Old: "This barcode format is not valid. Please use a ticket with the new 8-digit barcode format."
- New: "Barcode format not recognized. Please verify the barcode is readable and try again."

### Backward Compatibility

✅ All existing functionality maintained:
- New 8-digit barcodes work exactly as before
- Ticket generation still creates 8-digit barcodes
- All validation logic preserved
- No database schema changes
- No breaking API changes

For full technical details, see the complete guide below.

---

## Issue: Old Format Barcodes Still Showing Up

If you're seeing old format barcodes in your app, it means your existing tickets in the database haven't been migrated to the new 8-digit barcode format yet.

## Old vs New Barcode Format

### Old Format (varies)
- Could be 13 digits (EAN-13)
- Could include ticket number directly
- Examples: `9780000000001`, `ABC000001000`, etc.

### New Format (8 digits)
- Category prefix (1 digit) + Ticket sequence (7 digits)
- ABC-000001 → `10000001`
- EFG-000001 → `20000001`
- JKL-000001 → `30000001`
- XYZ-000001 → `40000001`

## How to Migrate Your Database

### Step 1: Backup Your Database First! 🚨

**IMPORTANT**: Always backup your database before running migrations.

```bash
# For SQLite
cp raffle.db raffle.db.backup

# For PostgreSQL
pg_dump your_database > backup.sql
```

### Step 2: Run the Migration Script

The migration script has been optimized to handle large datasets without memory issues.

```bash
# Navigate to raffle-app directory
cd raffle-app

# Run the migration script
node migrations/migrate_to_8digit_barcodes.js
```

### Step 3: Verify the Migration

The script will:
1. Check how many tickets need migration
2. Convert all barcodes to 8-digit format in batches of 1000
3. Nullify old QR code data (QR codes are disabled in favor of barcodes)
4. Verify all barcodes are unique
5. Show a summary of the migration

Expected output:
```
🔄 Starting migration to 8-digit barcodes...

📊 Step 1: Checking ticket count...
   Found 150,000 tickets to process

🔧 Step 2: Converting barcodes to 8-digit format (BATCH PROCESSING)...
   Progress: 1,000 / 150,000 tickets processed
   Progress: 2,000 / 150,000 tickets processed
   ...
   Converted 150,000 barcodes

📋 Sample barcode conversions:
   ABC-000001: [old] -> 10000001
   ABC-000002: [old] -> 10000002
   ...

💾 Step 3: Updating database (BATCH PROCESSING)...
   Progress: 1,000 / 150,000 tickets updated
   Progress: 2,000 / 150,000 tickets updated
   ...

🔍 Step 4: Verifying barcode uniqueness...
   ✅ All barcodes are unique!

📊 Migration Summary:
   Total tickets: 150,000
   Successfully updated: 150,000
   Errors: 0
   All QR code data: NULLIFIED

✅ Migration completed successfully!
```

## What the Migration Does

1. **Reads tickets in batches**: Processes 1000 tickets at a time to prevent memory issues
2. **Converts barcodes**: Changes each ticket's barcode to the new 8-digit format based on ticket number
3. **Updates database**: Saves new barcodes and removes old QR code data
4. **Verifies uniqueness**: Ensures no duplicate barcodes exist

## After Migration

1. **Restart your application**: The app should now show the new 8-digit barcodes
2. **Test exports**: Try exporting tickets to verify barcodes are correct
3. **Test printing**: Print test tickets to ensure barcodes scan correctly

## Troubleshooting

### Error: "No tickets to migrate"
- Your database is empty or the table doesn't exist
- Make sure you're running the script in the correct directory

### Error: "Duplicate barcode detected"
- This shouldn't happen with the new format, but if it does:
- Check if you have duplicate ticket numbers in your database
- Contact support with the error details

### Migration takes a long time
- This is normal for large databases (1M+ tickets)
- The script processes 1000 tickets at a time and logs progress
- Don't interrupt the migration - let it complete

### Memory issues during migration
- The new batch processing should prevent this
- If it still happens, the system may need more RAM
- For very large databases (5M+ tickets), consider running on a machine with 4GB+ RAM

## Need Help?

If you encounter any issues:
1. Check the error message carefully
2. Make sure you have a backup of your database
3. Share the full error output for debugging

## Technical Details

The migration script uses the improved batch processing methods:
- `db.processBatches()` for memory-efficient data reading
- Batch size: 1000 tickets
- Progress logging: Every 1000 tickets
- Automatic garbage collection between batches

This ensures the migration can handle databases with millions of tickets without running out of memory.
