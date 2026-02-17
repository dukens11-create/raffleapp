# Ticket Design Assets

This directory contains the official ticket design images for all 6 tiers of the Grate Genyen raffle system.

## Files

| File Name | Category | Price | Max Prize | Ticket Code |
|-----------|----------|-------|-----------|-------------|
| BASIC-50-HTG.png | BASIC | 50 HTG | 5,000 HTG | XYZ-###### |
| PREMIUM-100-HTG.png | PREMIUM | 100 HTG | 10,000 HTG | EFG-###### |
| BRONZE-250-HTG.png | BRONZE | 250 HTG | 25,000 HTG | JKL-###### |
| SILVER-500-HTG.png | SILVER | 500 HTG | 150,000 HTG | ABC-###### |
| GOLD-1000-HTG.png | GOLD | 1,000 HTG | 500,000 HTG | GOLD-##### |
| DIAMOND-5000-HTG.png | DIAMOND | 5,000 HTG | 2,000,000 HTG | DMD-##### |

## Design Specifications

### Color Themes

**BASIC (Green)**
- Primary: #10b981 (Emerald)
- Secondary: #059669
- Theme: Fresh, accessible, entry-level

**PREMIUM (Purple)**
- Primary: #7c3aed (Violet)
- Secondary: #6366f1
- Theme: Premium, exclusive, cosmic

**BRONZE (Orange-Red)**
- Primary: #ea580c
- Secondary: #dc2626
- Theme: Warm, competitive, bronze medal

**SILVER (Gray)**
- Primary: #cbd5e1 (Slate)
- Secondary: #94a3b8
- Theme: Metallic, sophisticated, silver medal

**GOLD (Yellow)**
- Primary: #fbbf24 (Amber)
- Secondary: #f59e0b
- Theme: Luxury, prestigious, gold medal

**DIAMOND (Cyan)**
- Primary: #22d3ee (Cyan)
- Secondary: #06b6d4
- Theme: Premium, rare, diamond brilliance

## Technical Details

- **Format**: PNG with transparency
- **Resolution**: 1024x1024px minimum
- **DPI**: 300 (print-ready)
- **Color Space**: sRGB (digital), CMYK (print)
- **Optimization**: Web-optimized, < 500KB per file

## Common Elements

All tickets share these consistent elements:
- "GRATE TOUT" banner (top-left, brown background)
- Price banner (top-right, brown background)
- "GRATE GENYEN" logo (center, yellow + light blue)
- Category banner (center, metallic ribbon)
- Scratch area (white box for ticket number)
- Prize banner (bottom, brown background)
- Sparkle/glitter background effects

## Usage

### Web Application
```javascript
// Serve ticket design
app.get('/api/ticket-designs/:category', (req, res) => {
  const category = req.params.category.toUpperCase();
  res.sendFile(`public/ticket-designs/${category}-*.png`);
});
```

### HTML Display
```html
<img src="/ticket-designs/SILVER-500-HTG.png" alt="Silver Ticket" />
```

### API Response
```json
{
  "category": "SILVER",
  "price": 500,
  "imageUrl": "/ticket-designs/SILVER-500-HTG.png",
  "maxPrize": 150000
}
```

## Placeholder Notice

⚠️ **Note**: These files are currently placeholders. Actual high-resolution ticket designs should be created by a graphic designer following the specifications in `TICKET_DESIGN_GUIDE.md`.

To create the final designs:
1. Use the SILVER ticket as the reference template
2. Apply the color themes specified for each category
3. Update all text elements (price, prize amounts)
4. Export at 1024x1024px minimum, 300 DPI
5. Optimize for web (compress to < 500KB)
6. Replace placeholder files with final designs

## See Also

- [Complete Design Guide](../../TICKET_DESIGN_GUIDE.md)
- [Flutter Integration](../../flutter_app/lib/widgets/ticket_design_card.dart)
- [Web Gallery](../ticket-gallery.html)
