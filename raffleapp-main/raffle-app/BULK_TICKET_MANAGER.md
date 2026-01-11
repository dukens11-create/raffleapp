# Bulk Ticket Manager Documentation

## Overview

The Bulk Ticket Manager is an admin tool that provides comprehensive functionality for mass ticket operations, including:

- Mass export of all tickets in various formats (PDF, Excel, CSV, TXT)
- Barcode validation and legacy ticket detection
- Bulk barcode regeneration to ensure all tickets use the new 8-digit format
- Ticket invalidation and replacement tracking
- Real-time statistics on barcode format compliance

## Features

### 1. Barcode Statistics Dashboard

View real-time statistics about the ticket barcode status in your system:

- **Total Tickets**: Total number of tickets in the system
- **Valid 8-Digit Barcodes**: Tickets with correct 8-digit barcode format
- **Missing Barcodes**: Tickets that don't have a barcode assigned
- **Invalid Format**: Tickets with barcodes in incorrect format
- **Flagged Invalid**: Tickets marked as invalid/replaced
- **Category Breakdown**: Statistics grouped by ticket category (ABC, EFG, JKL, XYZ)

### 2. Legacy Ticket Detection

Automatically scan the system to detect tickets with:

- Missing barcodes
- Invalid barcode formats (not 8-digit format)
- Legacy barcodes that need replacement

Results are displayed in a detailed table showing:
- Ticket number
- Category
- Current barcode
- Issue type (Missing or Invalid Format)

### 3. Barcode Regeneration

Regenerate barcodes for all or filtered tickets:

**Options:**
- **Filter by Category**: Regenerate only for specific category (ABC, EFG, JKL, XYZ) or all categories
- **Legacy Only**: Only regenerate tickets with missing or invalid barcodes (recommended)

**Process:**
1. Select category filter (optional)
2. Choose whether to regenerate all or legacy-only tickets
3. Click "Regenerate Barcodes"
4. Confirm the action
5. View detailed results showing:
   - Total tickets processed
   - Successfully regenerated count
   - Skipped tickets
   - Any errors encountered

### 4. Bulk Export Options

Export all tickets with valid 8-digit barcodes in multiple formats:

#### Excel (XLSX)
- Comprehensive spreadsheet with all ticket information
- Includes: ticket number, barcode, category, price, status, buyer/seller info, timestamps
- Limit: 50,000 tickets per export

#### CSV
- Comma-separated values format
- Same fields as Excel export
- Easy to import into other systems
- Text-based, universally compatible

#### Text (TXT)
- Simple format: `TICKET-NUMBER  BARCODE`
- One ticket per line
- Perfect for barcode scanning systems
- Lightweight and fast

#### PDF (Printable Tickets)
- Professional print-ready tickets
- Multiple paper formats supported:
  - **Avery 16145**: 10 tickets per page (5.5" x 1.75")
  - **PrintWorks Custom**: 8 tickets per page (5.5" x 2.125")
  - **Letter 8.5x11 - 8 Tickets**: Portrait layout
  - **Grid Layout - 20 Tickets**: 4x5 grid (2" x 2.1")
- Includes barcodes and all ticket details
- Duplex printing supported (front/back)

## New 8-Digit Barcode Format

### Format Specification

The new barcode format consists of exactly 8 digits:
- **First digit (1-4)**: Category prefix
  - 1 = ABC (Regular)
  - 2 = EFG (Silver)
  - 3 = JKL (Gold)
  - 4 = XYZ (Platinum)
- **Next 7 digits**: Zero-padded sequence number (0000001 - 9999999)

### Examples

- `ABC-000001` → Barcode: `10000001`
- `EFG-000001` → Barcode: `20000001`
- `JKL-000001` → Barcode: `30000001`
- `XYZ-000001` → Barcode: `40000001`
- `ABC-123456` → Barcode: `10123456`

### Benefits

1. **Fixed Length**: Always 8 digits, easier to validate
2. **Category Identification**: First digit instantly identifies category
3. **Unique**: Each barcode is globally unique within the system
4. **Scannable**: Compatible with standard barcode scanners
5. **Human Readable**: Easy to verify manually

## API Endpoints

The Bulk Ticket Manager uses the following API endpoints:

### GET `/api/admin/bulk-tickets/statistics`
Get barcode statistics for the entire system.

**Response:**
```json
{
  "total_tickets": 10000,
  "missing_barcode": 0,
  "valid_8digit": 10000,
  "invalid_format": 0,
  "flagged_invalid": 0,
  "by_category": [
    {
      "category": "ABC",
      "total": 5000,
      "valid": 5000,
      "missing": 0
    }
  ]
}
```

### GET `/api/admin/bulk-tickets/detect-legacy`
Detect tickets with missing or invalid barcodes.

**Response:**
```json
{
  "total": 10,
  "tickets": [
    {
      "id": 123,
      "ticket_number": "ABC-000001",
      "barcode": null,
      "category": "ABC",
      "issue": "MISSING_BARCODE"
    }
  ]
}
```

### POST `/api/admin/bulk-tickets/regenerate`
Regenerate barcodes for all or filtered tickets.

**Request Body:**
```json
{
  "category": "ABC",  // Optional
  "legacyOnly": true  // Optional, default: false
}
```

**Response:**
```json
{
  "total": 100,
  "regenerated": 100,
  "skipped": 0,
  "errors": []
}
```

### POST `/api/admin/bulk-tickets/flag-legacy`
Flag legacy tickets as invalid/replaced.

**Request Body:**
```json
{
  "ticketIds": [123, 456, 789]
}
```

**Response:**
```json
{
  "success": true,
  "flagged": 3
}
```

### POST `/api/admin/bulk-tickets/export-pdf`
Export tickets to PDF format.

**Request Body:**
```json
{
  "category": "ABC",  // Optional
  "startTicket": "ABC-000001",  // Optional
  "endTicket": "ABC-001000",  // Optional
  "paperType": "AVERY_16145"  // Optional, default: AVERY_16145
}
```

**Response:**
PDF file download

### POST `/api/tickets/validate-barcode`
Validate ticket barcode for sale/scan (used in seller apps).

**Request Body:**
```json
{
  "barcode": "10000001"
}
```

**Response (Valid):**
```json
{
  "valid": true,
  "ticket": {
    "id": 123,
    "ticket_number": "ABC-000001",
    "barcode": "10000001",
    "status": "AVAILABLE",
    ...
  }
}
```

**Response (Invalid):**
```json
{
  "valid": false,
  "error": "INVALID_FORMAT",
  "message": "This barcode format is not valid. Please use a ticket with the new 8-digit barcode format."
}
```

## Validation in Scan/Sale Flows

All ticket scanning and selling operations now validate barcodes using the new 8-digit format:

### Validation Steps

1. **Format Check**: Ensures barcode is exactly 8 digits with first digit 1-4
2. **Database Lookup**: Finds ticket in database by barcode
3. **Status Check**: Verifies ticket is not flagged as invalid/replaced
4. **Availability Check**: Confirms ticket is available for sale

### Error Messages

- **INVALID_FORMAT**: "This barcode format is not valid. Please use a ticket with the new 8-digit barcode format."
- **NOT_FOUND**: "Ticket not found. Please verify the barcode is correct."
- **LEGACY_TICKET**: "This ticket has been replaced with a new barcode. Please obtain the updated ticket."
- **ALREADY_SOLD**: "This ticket has already been sold."

## Usage Workflow

### Initial Setup (One-Time)

1. **Access the Bulk Ticket Manager**
   - Log in as admin
   - Go to Admin Dashboard
   - Click "🔧 Open Bulk Manager"

2. **Check System Status**
   - View barcode statistics
   - Identify any issues

3. **Detect Legacy Tickets** (if needed)
   - Click "Detect Legacy Tickets"
   - Review results

4. **Regenerate Barcodes** (if needed)
   - Select category or all
   - Check "Only regenerate legacy/invalid barcodes"
   - Click "Regenerate Barcodes"
   - Confirm action

### Regular Operations

1. **Export Tickets for Printing**
   - Select category or all
   - Choose PDF format
   - Select paper type
   - Click "Export Tickets"

2. **Export for Other Systems**
   - Select category or all
   - Choose Excel/CSV/TXT format
   - Click "Export Tickets"

3. **Monitor System Health**
   - Regularly check statistics dashboard
   - Ensure all tickets have valid barcodes

## Notifications and Communication

When tickets are regenerated or replaced:

1. **System Updates**
   - All ticket barcodes are updated in the database
   - Old barcodes are invalidated (if flagged)

2. **Seller Communication** (Manual Process)
   - Export updated ticket list
   - Distribute to sellers via email or print
   - Provide clear instructions on using new barcodes

3. **Buyer Communication** (Manual Process)
   - For sold tickets with regenerated barcodes:
     - Export list of affected tickets
     - Contact buyers via phone/email
     - Arrange ticket replacement if necessary

## Security and Audit Trail

- All bulk operations are logged
- Only admins can access the Bulk Ticket Manager
- Print jobs are tracked in the `print_jobs` table
- Legacy tickets can be flagged for audit purposes
- All barcode changes are permanent (no rollback)

## Best Practices

1. **Always backup database** before regenerating barcodes
2. **Use "Legacy Only" option** when regenerating to minimize changes
3. **Test exports** with small batches first
4. **Communicate changes** to sellers and buyers promptly
5. **Monitor statistics** regularly to catch issues early
6. **Export backups** of ticket data periodically

## Troubleshooting

### Issue: Statistics show missing barcodes

**Solution:**
1. Click "Detect Legacy Tickets" to identify affected tickets
2. Use "Regenerate Barcodes" with "Legacy Only" checked
3. Verify statistics dashboard shows all valid

### Issue: PDF export fails

**Solution:**
1. Check ticket count (max 50,000 per export)
2. Try smaller category filter
3. Check server logs for errors
4. Verify print service is running

### Issue: Barcode validation fails in seller app

**Solution:**
1. Verify barcode is exactly 8 digits
2. Check if ticket is flagged as invalid
3. Regenerate barcode if in wrong format
4. Ensure seller app is updated

## Technical Details

### Database Schema

Tickets are stored with the following barcode-related fields:

- `barcode` (TEXT): 8-digit barcode number
- `status` (TEXT): AVAILABLE, SOLD, INVALID
- `printed` (BOOLEAN): Whether ticket has been printed
- `print_count` (INTEGER): Number of times printed

### Barcode Generation

Barcodes are generated using the `barcodeService.generateBarcodeNumber()` function:

```javascript
// Example
barcodeService.generateBarcodeNumber('ABC-000001')
// Returns: '10000001'
```

### PDF Generation

PDFs are generated using the `printService.generatePrintPDF()` function with support for multiple paper templates.

## Support

For technical support or questions:
1. Check this documentation
2. Review server logs in `/raffle-app/`
3. Contact system administrator
4. Refer to the main README.md for general setup issues
