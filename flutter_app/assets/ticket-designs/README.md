# Ticket Design Assets

This directory contains ticket design images for the Flutter mobile app.

## Files
- `basic-ticket.png` - BASIC tier (50 HTG)
- `premium-ticket.png` - PREMIUM tier (100 HTG)
- `bronze-ticket.png` - BRONZE tier (250 HTG)
- `silver-ticket.png` - SILVER tier (500 HTG)
- `gold-ticket.png` - GOLD tier (1,000 HTG)
- `diamond-ticket.png` - DIAMOND tier (5,000 HTG)

## Usage
Reference these images in Flutter using:
```dart
Image.asset('assets/ticket-designs/silver-ticket.png')
```

## Note
Currently using SVG designs from `raffle-app/public/ticket-designs/`.
PNG versions should be exported at 800x1200px resolution for optimal mobile display.

To generate PNG files from SVG:
1. Open SVG files in design tool (Figma, Inkscape, etc.)
2. Export at 2x resolution (800x1200px)
3. Save as PNG with transparency
4. Place in this directory
