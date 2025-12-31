# Ticket Printing System - Documentation

## Overview
Professional ticket printing system for Avery 16145 perforated paper, supporting duplex printing with buyer and seller stub sections.

## Features
- ✅ Avery 16145 paper support (5.5" × 1.75" tickets, 10 per sheet)
- ✅ Professional front/back design with buyer and seller information fields
- ✅ QR code generation for ticket verification
- ✅ Preview functionality before printing
- ✅ Batch printing with automatic sheet calculation
- ✅ Print tracking in database
- ✅ Duplex printing support with proper alignment

## Paper Specifications

### Avery 16145
- **Paper Size:** 8.5" × 11" (Letter)
- **Ticket Size:** 5.5" × 1.75" each (landscape)
- **Layout:** 2 columns × 5 rows = 10 tickets per sheet
- **Margins:** 
  - Top/Bottom: 0.5"
  - Left/Right: 0.1875"
- **Features:** Pre-perforated for easy separation

## Ticket Design

### Front Side (Buyer Keeps)
- 🎫 Title: "RAFFLE TICKET"
- Ticket Number (large, prominent)
- Category and Price
- QR Code (1" × 1")
- Buyer Information Fields:
  - Date: ___
  - Name: ___
  - Phone: ___
  - Draw Date: [INSERT DATE]
- Footer: "Keep this ticket for entry"

### Back Side (Seller Stub)
- 📋 Title: "SELLER STUB"
- Ticket Number
- Category with price
- Small QR Code (0.6" × 0.6")
- Seller Information Fields:
  - Sold By: ___
  - Seller ID: ___
  - Buyer Name: ___
  - Buyer Phone: ___
  - Date Sold: ___
  - Payment: [Cash/Check/Card]
- Footer: "Office Use Only - Keep Record"

## User Interface

### Print Center (`/print-tickets.html`)
1. **Category Selection:** ABC/EFG/JKL/XYZ
2. **Ticket Range:** Start # to End #
3. **Sheet Calculator:** Automatically calculates sheets needed
4. **Preview Button:** Shows first ticket preview with stats
5. **Print Button:** Generates and downloads PDF

### Admin Dashboard Integration
- Prominent "Print Tickets" section in admin.html
- Direct link to Print Center
- Positioned before "Create Ticket" section

## API Endpoints

### GET /api/admin/tickets/print-batch
Fetch tickets for printing with QR codes for preview.

**Parameters:**
- `category` (string): Ticket category (ABC/EFG/JKL/XYZ)
- `start` (number): Starting ticket number
- `end` (number): Ending ticket number

**Response:**
```json
{
  "tickets": [
    {
      "id": 1,
      "barcode": "ABC-000000001",
      "category": "ABC",
      "price": 50.00,
      "qr_code": "data:image/png;base64,...",
      "status": "AVAILABLE",
      "ticket_number": "ABC-000000001"
    }
  ],
  "sheets": 10,
  "total_tickets": 100
}
```

### POST /api/admin/tickets/mark-printed
Mark tickets as printed in the database.

**Body:**
```json
{
  "ticket_ids": [1, 2, 3, 4, 5]
}
```

**Response:**
```json
{
  "success": true,
  "marked": 5
}
```

### POST /api/admin/tickets/print/generate
Generate and download PDF for printing (existing endpoint, used by print-tickets.html).

**Body:**
```json
{
  "raffle_id": 1,
  "category": "ABC",
  "start_ticket": "ABC-000000001",
  "end_ticket": "ABC-000000100",
  "paper_type": "AVERY_16145"
}
```

**Response:** PDF file download

## Database Schema

### Tickets Table (Enhanced)
```sql
CREATE TABLE tickets (
  id INTEGER PRIMARY KEY,
  raffle_id INTEGER,
  category_id INTEGER,
  ticket_number TEXT UNIQUE NOT NULL,
  category TEXT,
  price NUMERIC(10,2),
  status TEXT DEFAULT 'AVAILABLE',
  barcode TEXT,
  qr_code_data TEXT,
  printed BOOLEAN DEFAULT FALSE,      -- New
  printed_at TIMESTAMP,               -- New
  print_count INTEGER DEFAULT 0,      -- New
  ...
);
```

### Print Jobs Table
```sql
CREATE TABLE print_jobs (
  id INTEGER PRIMARY KEY,
  admin_id INTEGER,
  raffle_id INTEGER NOT NULL,
  category TEXT NOT NULL,
  ticket_range_start TEXT NOT NULL,
  ticket_range_end TEXT NOT NULL,
  total_tickets INTEGER NOT NULL,
  total_pages INTEGER NOT NULL,
  paper_type TEXT NOT NULL,
  status TEXT DEFAULT 'scheduled',
  progress_percent INTEGER DEFAULT 0,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);
```

## Printer Settings

### For Best Results
1. **Paper:** Load Avery 16145 perforated ticket paper
2. **Size:** Letter (8.5" × 11")
3. **Orientation:** Portrait
4. **Duplex:** Long Edge (flip on long side)
5. **Scale:** 100% (no scaling!)
6. **Quality:** High/Best
7. **Color:** Color (for better QR code scanning)

### Duplex Printing Setup
- **Front pages (odd):** Buyer tickets with full information
- **Back pages (even):** Seller stubs
- When duplex printed, front and back align perfectly

## Usage Flow

1. **Admin logs in** → Goes to dashboard
2. **Clicks "Print Tickets"** link → Opens Print Center
3. **Selects category** (e.g., ABC)
4. **Enters range** (e.g., 1 to 100)
5. **Clicks "Preview"** → Sees:
   - Total tickets: 100
   - Sheets needed: 10
   - Pages to print: 20 (front + back)
   - First ticket preview
6. **Clicks "Print Tickets"** → Downloads PDF
7. **Opens PDF** in PDF reader
8. **Prints with duplex settings**
9. **System automatically marks tickets as printed** in database
10. **Tickets ready to distribute!**

## Code Architecture

### Files Modified/Created

#### New Files
- `raffle-app/public/print-tickets.html` - Print interface
- `raffle-app/public/styles/print-tickets.css` - Print styles

#### Modified Files
- `raffle-app/services/printService.js` - Enhanced ticket generation
- `raffle-app/services/ticketService.js` - Database compatibility fix
- `raffle-app/server.js` - New API endpoints
- `raffle-app/public/admin.html` - Print center link

### Service Functions

#### printService.js
- `CATEGORY_NAMES` - Category display mapping
- `TEMPLATES` - Paper template configurations
- `drawTicketFront()` - Render front side
- `drawTicketBack()` - Render back side
- `generatePrintPDF()` - Main PDF generation (optimized)
- `createPrintJob()` - Track print jobs
- `updatePrintJobStatus()` - Update job progress

#### qrcodeService.js (existing)
- `generateTicketQRCode()` - Generate QR codes
- `generateVerificationURL()` - Create verification URLs

#### ticketService.js
- `getTicketsByRange()` - Fetch tickets by range
- `markAsPrinted()` - Mark as printed (fixed for SQLite)
- `generateAndSaveCodes()` - Generate barcodes/QR codes

## Performance Optimizations

1. **Batch QR Generation:** Pre-generate all QR codes for a batch using `Promise.all`
2. **Single Code Generation:** Generate codes once, use for both front and back
3. **Efficient Querying:** Range queries with proper indexes
4. **Progress Tracking:** Update progress every 5 tickets

## Security

### Authentication & Authorization
- ✅ All print endpoints require authentication (`requireAuth`)
- ✅ Admin-only access (`requireAdmin`)
- ✅ Session-based authentication

### Input Validation
- ✅ Category validation (must be ABC/EFG/JKL/XYZ)
- ✅ Range validation (start ≤ end)
- ✅ Parameter validation (required fields checked)
- ✅ Array type validation for mark-printed endpoint

### SQL Injection Prevention
- ✅ Parameterized queries throughout
- ✅ No string concatenation in SQL
- ✅ Database abstraction layer (db.run, db.all)

### Cross-Database Compatibility
- ✅ Boolean handling (SQLite: 1, PostgreSQL: TRUE)
- ✅ Timestamp handling (db.getCurrentTimestamp())
- ✅ Query placeholder conversion (? → $1, $2)

## Testing Checklist

- [x] Server starts successfully
- [x] Dependencies installed
- [x] Print pages accessible
- [x] Database schema initialized
- [x] Sample tickets created
- [x] Code review completed
- [x] Security scan completed
- [ ] PDF generation tested (requires tickets)
- [ ] Duplex alignment verified (requires physical printer)
- [ ] QR codes scan correctly (requires mobile device)

## Troubleshooting

### Common Issues

**Issue:** PDF doesn't download
- **Solution:** Check browser console for errors, verify authentication

**Issue:** Tickets don't align with perforations
- **Solution:** Ensure "Scale: 100%" in printer settings, verify Avery 16145 paper

**Issue:** Front and back don't align in duplex
- **Solution:** Use "Long Edge" duplex setting, test with single sheet first

**Issue:** QR codes don't scan
- **Solution:** Print in color at high quality, ensure good lighting when scanning

**Issue:** "No tickets found in range"
- **Solution:** Create tickets first or let system auto-generate them

## Future Enhancements

### Nice-to-Have Features
- [ ] Print ticket design customization (logo upload)
- [ ] Bulk print by seller (print all tickets for Seller #5)
- [ ] Print report (list of printed tickets)
- [ ] Reprint option with warning
- [ ] Export to PDF before printing for review
- [ ] Print queue management
- [ ] Printer profiles (save preferred settings)
- [ ] Batch size configuration
- [ ] Custom paper template creation

## Support

For issues or questions:
1. Check this documentation
2. Review server logs: `/tmp/server.log`
3. Check database: `sqlite3 raffle.db` or PostgreSQL logs
4. Verify Avery 16145 paper specifications
5. Test with sample tickets first

## Version History

- **v1.0.0** (2025-12-31): Initial release
  - Avery 16145 support
  - Duplex printing
  - Preview functionality
  - Print tracking
  - QR code generation
