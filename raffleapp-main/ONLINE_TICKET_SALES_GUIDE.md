# Online Ticket Sales Implementation Guide

## Overview

This guide explains how to enable and use the online ticket sales feature that allows buyers to purchase raffle tickets directly through the buyers portal.

## Feature Summary

- **Last 100,000 tickets** from each category (ABC, EFG, JKL, XYZ) can be made available for online purchase
- **Total of 400,000 tickets** available online (100K × 4 categories)
- Buyers can purchase tickets through `/buyers` portal
- Admins can manage online availability through admin dashboard
- Integrates with existing payment methods (MonCash, NatCash, Manual)

## Setup Instructions

### 1. Database Migration

After deploying the code, run the migration script to mark the last 100K tickets per category as available online:

```bash
cd raffle-app

# First, do a dry run to see what will be changed
node migrations/mark_online_available_tickets.js --dry-run

# If the output looks correct, run the actual migration
node migrations/mark_online_available_tickets.js
```

**Expected Output:**
```
🎫 Migration: Mark Tickets Available Online
================================================

Found 4 categories:
  - ABC: 375,000 tickets
  - EFG: 375,000 tickets
  - JKL: 375,000 tickets
  - XYZ: 375,000 tickets

Processing category: ABC
  Total tickets: 375,000
  Online available: Last 100,000 tickets
  Range: ABC-275001 to ABC-375000
  ✅ Marked 100,000 tickets as available online

... (similar for EFG, JKL, XYZ)

✅ Migration complete: 400,000 tickets marked as available online
```

### 2. Verify Migration

Check the admin dashboard to confirm the migration:

1. Login to admin dashboard
2. Scroll to "🌐 Online Ticket Sales Management" section
3. Verify statistics show:
   - Total Online Available: 400,000
   - By category breakdown showing 100,000 per category

### 3. Test Buyers Portal

1. Navigate to `/buyers` page
2. Go to "📋 Raffle Info" tab
3. Verify the "🛒 Buy Tickets Online" section shows available tickets
4. Test the purchase flow:
   - Click "🎫 Buy Tickets Now"
   - Fill in buyer information
   - Select category and quantity
   - Choose payment method
   - Complete test purchase

## Admin Management

### Viewing Online Sales Statistics

**Location:** Admin Dashboard → Online Ticket Sales Management section

**Statistics Available:**
- Total online-available tickets across all categories
- Currently available for purchase (unsold)
- Tickets sold through online portal
- Breakdown by category

**Refresh Stats:** Click "🔄 Refresh Stats" button

### Managing Online Availability

#### Enable/Disable Entire Categories

To enable or disable online sales for a specific category:

1. Go to "Enable/Disable by Category" section
2. Select category from dropdown (ABC, EFG, JKL, XYZ)
3. Click:
   - **✅ Enable** - Makes all tickets in category available online
   - **❌ Disable** - Removes all tickets in category from online sales

#### Mark All Tickets in Categories

The "✨ Mark All Tickets" button marks ALL tickets in each category as available online (not just the last 100K).

**Use this with caution** - it's intended for special promotions where you want to offer all tickets online.

**For normal use:** Use the migration script which marks only the last 100K per category.

### Reverting Migration

To remove all tickets from online availability:

```bash
cd raffle-app
node migrations/mark_online_available_tickets.js --reset
```

This is useful if:
- You want to temporarily disable online sales
- You need to reconfigure which tickets are available
- You're troubleshooting issues

After reset, you can run the migration again to re-enable online sales.

## Buyer Experience

### Purchase Flow

1. **Browse Raffle Info**
   - View available categories and prices
   - See online-available ticket counts per category

2. **Purchase Tickets**
   - Enter buyer information (name, phone, email, department)
   - Select category and quantity (1-10 tickets per transaction)
   - View total amount
   - Choose payment method

3. **Payment Methods**
   - **MonCash (Automated)** - Redirects to MonCash for payment
   - **NatCash (Automated)** - Sends payment request to phone
   - **MonCash (Manual)** - Submit USSD transaction reference
   - **NatCash (Manual)** - Submit transaction reference

4. **Ticket Assignment**
   - **Automated payments:** Tickets assigned immediately upon payment confirmation
   - **Manual payments:** Tickets assigned after admin approves payment
   - SMS notification sent with ticket numbers

### Lookup Purchased Tickets

Buyers can view their tickets:
1. Go to "👤 My Tickets" tab
2. Enter email, phone, or buyer code
3. View all purchased tickets with details

## API Endpoints

### Public Endpoints

**GET `/api/public/raffle-info`**
- Returns raffle information including online-available ticket counts
- No authentication required

**GET `/api/public/available-tickets`**
- Returns paginated list of tickets available online
- Filters by `available_online = true AND status = 'AVAILABLE'`
- Optional query param: `category` (ABC, EFG, JKL, XYZ)

### Admin Endpoints

**POST `/api/admin/tickets/mark-online-available`**
- Mark or unmark tickets as available online
- Requires admin authentication
- Body:
  ```json
  {
    "category": "ABC",
    "action": "mark" // or "unmark"
  }
  ```

**GET `/api/admin/tickets/online-stats`**
- Get online ticket availability statistics
- Requires admin authentication
- Returns overall stats and per-category breakdown

## Integration with Existing Features

### Seller Workflow

**Not Affected** - Sellers can continue selling tickets through the seller portal as normal. The online availability flag is independent of the seller workflow.

**Important:** Tickets marked as available online CAN still be sold by sellers. The system allows both channels to operate simultaneously.

### Payment Processing

Uses the existing payment service (`services/paymentService.js`):
- MonCash API integration
- NatCash API integration
- Manual payment verification workflow
- SMS notifications via `services/smsService.js`

### Ticket Assignment

When a payment is approved (automated or manual):
1. System queries for available tickets: `status = 'AVAILABLE' AND available_online = true`
2. Assigns requested quantity of tickets to buyer
3. Updates ticket status to 'SOLD'
4. Sets buyer information (name, phone, email, department)
5. Records payment reference
6. Sends SMS notification to buyer

## Monitoring & Troubleshooting

### Check Online Sales Status

**Admin Dashboard:**
- View real-time statistics in Online Ticket Sales Management section
- Monitor tickets sold online vs. offline
- Track available inventory per category

**Database Query:**
```sql
-- Check online availability by category
SELECT 
  category,
  COUNT(*) as total,
  SUM(CASE WHEN available_online THEN 1 ELSE 0 END) as online_total,
  SUM(CASE WHEN status = 'AVAILABLE' AND available_online THEN 1 ELSE 0 END) as available,
  SUM(CASE WHEN status = 'SOLD' AND available_online THEN 1 ELSE 0 END) as sold
FROM tickets
GROUP BY category;
```

### Common Issues

**Issue:** No tickets showing as available online
- **Solution:** Run the migration script to mark tickets as available online

**Issue:** Buyers can't complete purchase
- **Check:** Payment service configuration (MonCash/NatCash credentials)
- **Check:** SMS service configuration for notifications
- **Check:** Department list is populated

**Issue:** Admin can't see statistics
- **Solution:** Ensure admin is logged in and has admin role
- **Check:** Browser console for JavaScript errors

## Mobile Optimization

The buyers portal is optimized for mobile devices:
- Responsive design (mobile-first)
- Touch-friendly buttons (min 44px height)
- Large form inputs for easy typing
- Progressive Web App capabilities
- Works on 3G/4G connections in Haiti

## Multi-Language Support

The interface supports:
- English
- Haitian Creole (Kreyòl)
- French
- Spanish

Language can be selected in the interface. The online ticket sales feature respects the selected language.

## Best Practices

1. **Regular Monitoring**
   - Check online sales statistics daily
   - Monitor payment success rates
   - Review failed transactions

2. **Inventory Management**
   - Keep track of online vs. offline ticket allocations
   - Adjust online availability based on demand
   - Use migration script to add more tickets if needed

3. **Customer Support**
   - Provide clear instructions for payment methods
   - Have phone support available for buyers
   - Respond promptly to payment verification requests

4. **Security**
   - Monitor for suspicious purchase patterns
   - Review payment logs regularly
   - Keep payment provider credentials secure

## Support

For technical issues or questions:
- Review the main README.md
- Check server logs for errors
- Contact system administrator

---

**Last Updated:** January 11, 2026
**Feature Version:** 1.0.0
