# Comprehensive Raffle Ticket Management System

## Overview

Production-ready raffle system supporting 1.5M tickets across 4 price categories with automatic barcode/QR generation, printing support for 2 paper types, dual scanning interfaces, and 10% seller commission tracking.

## Features

### 📦 Ticket Categories
- **ABC (Bronze)**: 500,000 tickets @ $50 each = $25M potential
- **EFG (Silver)**: 500,000 tickets @ $100 each = $50M potential
- **JKL (Gold)**: 250,000 tickets @ $250 each = $62.5M potential
- **XYZ (Platinum)**: 250,000 tickets @ $500 each = $125M potential

**Total**: 1.5M tickets, $262.5M total potential revenue

### 🎫 Ticket Management
- Automatic barcode generation (Code128 format)
- QR code generation with verification URLs
- Bulk import/export via Excel/CSV
- Print tracking and history
- Status management (Available, Sold, Reserved, Void)

### 🖨️ Printing System
Supports two paper types:
1. **Avery 16145**: 1.75" × 5.5", 10 tickets per page, pre-perforated
2. **PrintWorks**: 2.125" × 5.5", 8 tickets per page, manual cutting

Features:
- Automatic barcode/QR overlay
- Batch printing with progress tracking
- Reprint capability
- Double-sided printing support
- Print job history

### 👥 User Roles

**Admin:**
- Create and manage raffles
- Configure ticket categories
- Import/export tickets
- Print tickets
- Scan and verify tickets
- Record winners
- View reports and analytics
- Manage sellers

**Seller:**
- Scan tickets (barcode or manual entry)
- Sell tickets to buyers
- View sales dashboard
- Track commission (10% per sale)
- View sales history

## Getting Started

### Prerequisites
- Node.js v14 or higher
- npm
- SQLite3 (development) or PostgreSQL (production)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd raffleapp/raffle-app
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
npm start
```

4. Access the application:
- URL: http://localhost:3000
- Default admin: Phone `1234567890`, Password `admin123`

## User Guide

### For Administrators

#### 1. Access Admin Dashboard
Navigate to `raffle-dashboard.html` to see:
- Real-time statistics
- Category breakdowns
- Revenue tracking
- Quick action buttons

#### 2. Print Tickets
Go to **Print Center** (`raffle-print.html`):
1. Enter ticket range (e.g., ABC-000001 to ABC-001000)
2. Select paper type (Avery 16145 or PrintWorks)
3. Click "Generate Print PDF"
4. System automatically generates barcodes and QR codes
5. Download and print the PDF
6. Tickets are marked as "printed" in database

#### 3. Import Tickets
Go to **Import/Export** (`raffle-import.html`):
1. Download the template file
2. Fill in ticket data (ticket number, category, price)
3. Upload the Excel/CSV file
4. System imports in batches of 1000
5. View import results

#### 4. Export Tickets
Export all tickets or filter by category/status:
- Excel format (.xlsx) with all fields
- CSV format (.csv) for simple data
- Includes barcodes, QR codes, and sales data

#### 5. Scan Tickets
Use admin scanning interface to:
- Verify ticket authenticity
- Check ticket status
- View complete ticket history
- Record winners during draws

### For Sellers

#### 1. Access Seller Dashboard
Navigate to `raffle-seller-dashboard.html` to see:
- Today's sales count
- Today's revenue
- Total sales
- Total commission earned
- Recent sales list

#### 2. Scan and Sell Tickets
Go to **Scan & Sell** (`raffle-scan-seller.html`):
1. Enter barcode number (e.g., 1000001) or ticket number (e.g., ABC-000001)
2. Click "Check Ticket"
3. Verify ticket details and price
4. If available, enter buyer information:
   - Buyer name (required)
   - Buyer phone (required)
   - Buyer email (optional)
   - Payment method
5. Click "Confirm Sale"
6. 10% commission is automatically calculated and credited

## API Documentation

### Admin Endpoints

#### Raffle Management
- `GET /api/admin/raffles` - List all raffles
- `POST /api/admin/raffles` - Create new raffle
- `GET /api/admin/raffles/:id/stats` - Get raffle statistics

#### Ticket Operations
- `POST /api/admin/tickets/import` - Import tickets (Excel/CSV)
- `GET /api/admin/tickets/export` - Export tickets
- `GET /api/admin/tickets/template` - Download import template
- `POST /api/admin/tickets/print` - Generate print job
- `GET /api/admin/tickets/print/:jobId` - Get print job status
- `GET /api/admin/print-jobs` - List print jobs

#### Scanning & Winners
- `POST /api/admin/tickets/scan` - Scan ticket for verification
- `POST /api/admin/winners/draw` - Record winner
- `GET /api/admin/winners` - List all winners

#### Reports
- `GET /api/admin/reports/revenue` - Revenue by category
- `GET /api/admin/reports/sellers` - Seller performance

### Seller Endpoints

- `GET /api/seller/dashboard` - Get seller stats
- `POST /api/seller/tickets/scan` - Scan ticket
- `GET /api/seller/tickets/check/:barcode` - Check ticket by barcode
- `POST /api/seller/tickets/sell` - Complete sale
- `GET /api/seller/sales` - Sales history
- `GET /api/seller/commission` - Commission breakdown

### Public Endpoints

- `GET /api/tickets/verify/:ticketNumber` - Verify ticket (QR scan)

## Database Schema

### Core Tables

**raffles**: Raffle event management
**ticket_categories**: Category definitions with pricing
**tickets**: Complete ticket information (1.5M capacity)
**users**: Admin and seller accounts
**print_jobs**: Print job tracking
**ticket_scans**: Audit trail
**winners**: Winner records
**ticket_designs**: Custom design uploads

### Key Indexes

Performance indexes on:
- `tickets.ticket_number` (unique)
- `tickets.barcode` (unique)
- `tickets.qr_code_data`
- `tickets.category`
- `tickets.status`
- `tickets.printed`

## Technical Architecture

### Backend Services
- **barcodeService.js**: Code128 barcode generation
- **qrcodeService.js**: QR code generation with verification URLs
- **ticketService.js**: CRUD operations and ticket management
- **printService.js**: PDF generation with PDFKit
- **importExportService.js**: Excel/CSV processing

### Frontend Pages
- **raffle-dashboard.html**: Admin dashboard
- **raffle-print.html**: Print center
- **raffle-import.html**: Import/export interface
- **raffle-seller-dashboard.html**: Seller dashboard
- **raffle-scan-seller.html**: Seller scanning interface

## Barcode/QR Code Format

### Barcodes
Category prefix + number:
- ABC-000001 → 1000001
- EFG-000001 → 2000001
- JKL-000001 → 3000001
- XYZ-000001 → 4000001

### QR Codes
Verification URL format:
```
https://enejipamticket.com/verify/ABC-000001
```

## Commission Structure

Sellers earn **10% commission** on each sale:
- ABC ($50): $5.00 commission
- EFG ($100): $10.00 commission
- JKL ($250): $25.00 commission
- XYZ ($500): $50.00 commission

## Security Features

- Password hashing with bcrypt
- Role-based access control
- Session management
- Rate limiting
- CSRF protection
- SQL injection prevention
- Audit logging (all ticket scans logged)

## Performance

- Optimized for 1.5M tickets
- Indexed queries for <100ms lookup
- Batch processing for imports (1000-5000 per batch)
- Efficient PDF generation
- Real-time dashboard updates

## Deployment

### Development
```bash
npm install
npm start
```

### Production
1. Set `NODE_ENV=production`
2. Configure `DATABASE_URL` for PostgreSQL
3. Set `SESSION_SECRET`
4. Deploy to Render, Heroku, or similar platform

## Support

For issues or questions, please contact the development team or open an issue in the repository.

## License

MIT License - See LICENSE file for details
