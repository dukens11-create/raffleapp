# Ticket Design System - Implementation Guide

This document provides comprehensive instructions for using and maintaining the 6-tier ticket design system in the Grate Genyen raffle application.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Quick Start](#quick-start)
4. [Using Ticket Designs](#using-ticket-designs)
5. [API Reference](#api-reference)
6. [Flutter Integration](#flutter-integration)
7. [Web Integration](#web-integration)
8. [Design Specifications](#design-specifications)
9. [Creating Design Assets](#creating-design-assets)
10. [Testing](#testing)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The Grate Genyen ticket design system consists of 6 distinct ticket tiers, each with unique visual styling:

| Category | Price | Max Prize | Color Theme |
|----------|-------|-----------|-------------|
| **BASIC** | 50 HTG | 5,000 HTG | Emerald Green (#10b981) |
| **PREMIUM** | 100 HTG | 10,000 HTG | Purple (#7c3aed) |
| **BRONZE** | 250 HTG | 25,000 HTG | Orange-Red (#ea580c) |
| **SILVER** | 500 HTG | 150,000 HTG | Silver Gray (#94a3b8) |
| **GOLD** | 1,000 HTG | 500,000 HTG | Gold (#fbbf24) |
| **DIAMOND** | 5,000 HTG | 2,000,000 HTG | Cyan (#22d3ee) |

---

## Directory Structure

```
raffleapp/
├── TICKET_DESIGN_GUIDE.md          # Complete design specifications
├── TICKET_DESIGN_SYSTEM_README.md  # This file
├── raffle-app/
│   ├── server.js                   # Backend with ticket design API
│   └── public/
│       ├── ticket-gallery.html     # Web gallery viewer
│       └── ticket-designs/         # Ticket design images
│           ├── README.md
│           ├── BASIC-50-HTG.png
│           ├── PREMIUM-100-HTG.png
│           ├── BRONZE-250-HTG.png
│           ├── SILVER-500-HTG.png
│           ├── GOLD-1000-HTG.png
│           └── DIAMOND-5000-HTG.png
└── flutter_app/
    ├── pubspec.yaml                # Updated with assets
    ├── lib/
    │   └── widgets/
    │       └── ticket_design_card.dart  # Reusable widget
    └── assets/
        └── images/
            └── tickets/            # Flutter ticket assets
                ├── basic_ticket.png
                ├── premium_ticket.png
                ├── bronze_ticket.png
                ├── silver_ticket.png
                ├── gold_ticket.png
                └── diamond_ticket.png
```

---

## Quick Start

### 1. View Ticket Gallery (Web)

Open the ticket gallery in your browser:

```bash
# If running locally
http://localhost:3000/ticket-gallery.html

# Or on production
https://your-domain.com/ticket-gallery.html
```

### 2. Use in Flutter App

```dart
import 'package:raffle_app/widgets/ticket_design_card.dart';

// Show ticket design as sample
TicketDesignCard(
  category: 'SILVER',
  showAsSample: true,
)

// Show with ticket number
TicketDesignCard(
  category: 'GOLD',
  ticketNumber: 'GOLD-12345',
)
```

### 3. Access via API

```bash
# List all ticket designs
curl http://localhost:3000/api/ticket-designs

# Get specific design image
curl http://localhost:3000/api/ticket-designs/SILVER
```

---

## Using Ticket Designs

### In Web Applications

#### HTML Direct Display
```html
<img src="/ticket-designs/SILVER-500-HTG.png" 
     alt="Silver Ticket" 
     style="width: 300px;" />
```

#### JavaScript Fetch
```javascript
// Fetch design metadata
fetch('/api/ticket-designs')
  .then(res => res.json())
  .then(data => {
    data.designs.forEach(design => {
      console.log(`${design.category}: ${design.price} HTG`);
    });
  });

// Display image
const img = document.createElement('img');
img.src = '/api/ticket-designs/GOLD';
document.body.appendChild(img);
```

#### React Component
```jsx
function TicketDesign({ category }) {
  return (
    <div className="ticket-container">
      <img 
        src={`/api/ticket-designs/${category}`}
        alt={`${category} Ticket`}
        onError={(e) => {
          e.target.src = '/images/placeholder-ticket.png';
        }}
      />
    </div>
  );
}
```

### In Flutter Applications

#### Basic Usage
```dart
import 'package:raffle_app/widgets/ticket_design_card.dart';

class MyTicketScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Tickets')),
      body: ListView(
        children: [
          TicketDesignCard(
            category: 'SILVER',
            ticketNumber: 'ABC-123456',
            width: 300,
            height: 400,
          ),
        ],
      ),
    );
  }
}
```

#### With Ticket Info Card
```dart
import 'package:raffle_app/widgets/ticket_design_card.dart';

Column(
  children: [
    TicketDesignCard(
      category: 'GOLD',
      showAsSample: true,
    ),
    SizedBox(height: 16),
    TicketInfoCard(category: 'GOLD'),
  ],
)
```

#### Grid Gallery
```dart
GridView.count(
  crossAxisCount: 2,
  children: [
    'BASIC', 'PREMIUM', 'BRONZE', 
    'SILVER', 'GOLD', 'DIAMOND'
  ].map((category) => TicketDesignCard(
    category: category,
    showAsSample: true,
    onTap: () => _showTicketDetails(category),
  )).toList(),
)
```

---

## API Reference

### GET `/api/ticket-designs`

List all available ticket designs with metadata.

**Response:**
```json
{
  "success": true,
  "designs": [
    {
      "category": "BASIC",
      "price": 50,
      "maxPrize": 5000,
      "codeFormat": "XYZ-######",
      "color": "#10b981",
      "imageUrl": "/api/ticket-designs/BASIC"
    },
    ...
  ],
  "count": 6
}
```

### GET `/api/ticket-designs/:category`

Get the ticket design image for a specific category.

**Parameters:**
- `category` (path): One of BASIC, PREMIUM, BRONZE, SILVER, GOLD, DIAMOND

**Response:** PNG image file or 404 error if not found

**Example:**
```bash
curl http://localhost:3000/api/ticket-designs/SILVER > silver-ticket.png
```

**Error Response:**
```json
{
  "error": "Invalid category",
  "validCategories": ["BASIC", "PREMIUM", "BRONZE", "SILVER", "GOLD", "DIAMOND"]
}
```

---

## Flutter Integration

### Step 1: Add Assets to pubspec.yaml

Already configured in `flutter_app/pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/tickets/
    - assets/icons/
    - assets/animations/
```

### Step 2: Import Widget

```dart
import 'package:raffle_app/widgets/ticket_design_card.dart';
```

### Step 3: Use in Your Screen

```dart
TicketDesignCard(
  category: 'SILVER',
  ticketNumber: ticket.ticketNumber,
  width: 300,
  height: 400,
  borderRadius: 12,
  elevation: 4,
  onTap: () {
    // Handle tap
  },
)
```

### Widget Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `category` | String | required | Ticket category (BASIC, PREMIUM, etc.) |
| `ticketNumber` | String? | null | Optional ticket number to display |
| `showAsSample` | bool | false | Show as sample without ticket number |
| `width` | double? | null | Card width (auto if null) |
| `height` | double? | null | Card height (auto if null) |
| `borderRadius` | double | 12.0 | Border radius in pixels |
| `elevation` | double | 4.0 | Shadow elevation |
| `onTap` | VoidCallback? | null | Tap callback |

---

## Web Integration

### Ticket Gallery Page

Access the interactive gallery at `/ticket-gallery.html`:

**Features:**
- Side-by-side comparison of all 6 ticket tiers
- Hover effects with zoom
- Download functionality
- Specifications table
- Responsive design

### Embedding in Your Web App

```html
<!-- Single ticket -->
<div class="ticket-preview">
  <img src="/api/ticket-designs/SILVER" 
       alt="Silver Ticket"
       style="max-width: 100%; border-radius: 12px;" />
</div>

<!-- Dynamic gallery -->
<script>
  fetch('/api/ticket-designs')
    .then(res => res.json())
    .then(data => {
      const gallery = document.getElementById('ticket-gallery');
      data.designs.forEach(design => {
        const img = document.createElement('img');
        img.src = design.imageUrl;
        img.alt = `${design.category} Ticket`;
        gallery.appendChild(img);
      });
    });
</script>
```

---

## Design Specifications

See [TICKET_DESIGN_GUIDE.md](./TICKET_DESIGN_GUIDE.md) for complete specifications including:

- Color palettes and gradients
- Typography and font requirements
- Element positioning and layout
- Image dimensions and resolution
- Print specifications
- Accessibility guidelines

---

## Creating Design Assets

### Design Requirements

1. **Resolution**: Minimum 1024x1024px (300 DPI for print)
2. **Format**: PNG with transparency support
3. **File Size**: < 500KB (optimized for web)
4. **Color Space**: sRGB (digital), CMYK (print)

### Design Elements (Consistent Across All Tiers)

- ✅ "GRATE TOUT" banner (top-left, brown #8B4513)
- ✅ Price banner (top-right, brown #8B4513)
- ✅ "GRATE GENYEN" logo (yellow #FFD700 + blue #87CEEB)
- ✅ Category banner (metallic ribbon, category color)
- ✅ Scratch area (white box for ticket number)
- ✅ Prize banner (bottom, brown #8B4513)
- ✅ Sparkle/glitter background effects

### Variable Elements (Per Category)

- 🎨 Background color gradient
- 🎨 Metallic ribbon color
- 💰 Price display
- 💎 Prize amount
- 🏷️ Category name

### Creation Workflow

1. **Use SILVER ticket as reference template**
2. **Create color variations using gradient overlays**
3. **Update text elements** (price, prize, category)
4. **Export at 1024x1024px, 300 DPI**
5. **Optimize for web** (compress to < 500KB)
6. **Place in both directories**:
   - `raffle-app/public/ticket-designs/`
   - `flutter_app/assets/images/tickets/`

### File Naming Convention

**Web Assets:**
- `BASIC-50-HTG.png`
- `PREMIUM-100-HTG.png`
- etc.

**Flutter Assets:**
- `basic_ticket.png`
- `premium_ticket.png`
- etc.

---

## Testing

### Backend API Testing

```bash
# Test design listing
curl http://localhost:3000/api/ticket-designs

# Test image retrieval
curl http://localhost:3000/api/ticket-designs/SILVER -o test-silver.png

# Test invalid category
curl http://localhost:3000/api/ticket-designs/INVALID
# Expected: 404 error with valid categories list
```

### Flutter Widget Testing

```dart
testWidgets('TicketDesignCard displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TicketDesignCard(
          category: 'SILVER',
          showAsSample: true,
        ),
      ),
    ),
  );
  
  expect(find.byType(Image), findsOneWidget);
});
```

### Web Gallery Testing

1. Open `/ticket-gallery.html`
2. Verify all 6 tickets display
3. Test hover effects
4. Test download buttons
5. Check responsive layout on mobile

---

## Troubleshooting

### Issue: Images Not Loading in Flutter

**Solution:**
```bash
# Clean and rebuild Flutter app
cd flutter_app
flutter clean
flutter pub get
flutter run
```

### Issue: API Returns 404 for Design

**Cause:** Design file doesn't exist yet (placeholder mode)

**Solution:** Add actual PNG files to `raffle-app/public/ticket-designs/`

### Issue: Gallery Shows Placeholders

**Expected Behavior:** Until actual design PNGs are created, colored placeholders are shown with ticket information.

**Solution:** Create high-resolution ticket designs following specifications in `TICKET_DESIGN_GUIDE.md`

### Issue: File Too Large

**Solution:**
```bash
# Optimize PNG files
npm install -g imagemagick
convert input.png -quality 85 -resize 1024x1024 output.png
```

---

## Maintenance

### Adding New Ticket Tier

1. Update `TICKET_DESIGN_GUIDE.md` with new tier specs
2. Create design PNG files
3. Update `server.js` API endpoint with new category
4. Update Flutter `ticket_design_card.dart` widget
5. Update `ticket-gallery.html`
6. Test all integrations

### Updating Existing Design

1. Modify source design files
2. Re-export at specified resolution
3. Replace files in both directories
4. Clear Flutter cache: `flutter clean`
5. Clear browser cache for web
6. Test on all platforms

---

## Support

For questions or issues:
- Review [TICKET_DESIGN_GUIDE.md](./TICKET_DESIGN_GUIDE.md)
- Check `/raffle-app/public/ticket-designs/README.md`
- Contact development team

---

**Last Updated:** 2026-02-17  
**Version:** 1.0  
**Maintained by:** Grate Genyen Development Team
