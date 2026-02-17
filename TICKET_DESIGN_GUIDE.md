# Grate Genyen Raffle Ticket Design Guide

## Overview

This document defines the comprehensive design system for all 6 ticket categories in the Grate Genyen raffle application. All tickets maintain consistent branding while varying in color, price, and prize amounts to reflect their tier.

---

## Ticket Categories

### Category Specifications Table

| Category | Price (HTG) | Code Format | Max Prize (HTG) | Background Color | Color Code |
|----------|-------------|-------------|-----------------|------------------|------------|
| BASIC    | 50          | XYZ-######  | 5,000           | Green            | #10b981    |
| PREMIUM  | 100         | EFG-######  | 10,000          | Purple           | #7c3aed    |
| BRONZE   | 250         | JKL-######  | 25,000          | Orange           | #ea580c    |
| SILVER   | 500         | ABC-######  | 150,000         | Silver           | #cbd5e1    |
| GOLD     | 1,000       | GOLD-#####  | 500,000         | Gold             | #fbbf24    |
| DIAMOND  | 5,000       | DMD-#####   | 2,000,000       | Cyan             | #22d3ee    |

---

## Design Elements (Consistent Across All Tickets)

### 1. **Logo and Branding**
- **Logo Text**: "GRATE GENYEN"
- **Logo Style**: Bold, prominent placement at top center
- **Logo Color**: Consistent across all tickets (typically black or dark text for visibility)
- **Font**: Sans-serif, bold weight

### 2. **Layout Structure**

```
┌─────────────────────────────────┐
│     GRATE GENYEN (Logo)         │
├─────────────────────────────────┤
│  GRATE TOUT   │   [PRICE] HTG   │  ← Header Banner
├─────────────────────────────────┤
│                                 │
│      [CATEGORY NAME]            │  ← Category Label
│                                 │
│      [TICKET NUMBER]            │  ← Unique Code
│                                 │
│    ╔═════════════════╗          │
│    ║                 ║          │
│    ║  SCRATCH AREA   ║          │  ← Interactive Scratch Zone
│    ║                 ║          │
│    ╚═════════════════╝          │
│                                 │
├─────────────────────────────────┤
│   GAGNER JUSQU'À [MAX PRIZE]    │  ← Bottom Prize Banner
└─────────────────────────────────┘
```

### 3. **Typography**

- **Logo**: 24-28pt, Bold
- **Header Labels**: 16-18pt, Bold
- **Category Name**: 20-22pt, Bold, Centered
- **Ticket Number**: 18-20pt, Bold, Monospace
- **Prize Banner**: 16-18pt, Bold

### 4. **Header Banner**
- Split into two sections
- Left section: "GRATE TOUT" (Win Everything)
- Right section: Ticket price
- Background: Darker shade of ticket category color
- Text color: White or high contrast

### 5. **Scratch Area**
- Central placement
- Rectangular shape with rounded corners
- Gray overlay before scratching
- Reveals prize or message after scratching
- Border: 2-3px solid in category color
- Size: Approximately 40-50% of ticket body

### 6. **Bottom Prize Banner**
- Full width banner
- Text: "GAGNER JUSQU'À [MAX PRIZE] HTG" (Win up to)
- Background: Darker shade of category color
- Text color: White
- Font: Bold

### 7. **Background**
- Primary color from category specifications
- Optional gradient: Light to medium shade of category color
- Clean, professional appearance

---

## Category-Specific Details

### BASIC Ticket (Green)
- **Color**: #10b981 (Emerald Green)
- **Price**: 50 HTG
- **Code Format**: XYZ-123456
- **Max Prize**: 5,000 HTG
- **Target Audience**: Entry-level players
- **Gradient Suggestion**: #10b981 → #059669

### PREMIUM Ticket (Purple)
- **Color**: #7c3aed (Vibrant Purple)
- **Price**: 100 HTG
- **Code Format**: EFG-123456
- **Max Prize**: 10,000 HTG
- **Target Audience**: Regular players
- **Gradient Suggestion**: #7c3aed → #6d28d9

### BRONZE Ticket (Orange)
- **Color**: #ea580c (Bright Orange)
- **Price**: 250 HTG
- **Code Format**: JKL-123456
- **Max Prize**: 25,000 HTG
- **Target Audience**: Intermediate players
- **Gradient Suggestion**: #ea580c → #c2410c

### SILVER Ticket (Silver/Gray)
- **Color**: #cbd5e1 (Light Gray/Silver)
- **Price**: 500 HTG
- **Code Format**: ABC-123456
- **Max Prize**: 150,000 HTG
- **Target Audience**: Committed players
- **Gradient Suggestion**: #cbd5e1 → #94a3b8
- **Note**: Use dark text for contrast on light background

### GOLD Ticket (Gold/Yellow)
- **Color**: #fbbf24 (Golden Yellow)
- **Price**: 1,000 HTG
- **Code Format**: GOLD-12345
- **Max Prize**: 500,000 HTG
- **Target Audience**: Premium players
- **Gradient Suggestion**: #fbbf24 → #f59e0b

### DIAMOND Ticket (Cyan)
- **Color**: #22d3ee (Bright Cyan)
- **Price**: 5,000 HTG
- **Code Format**: DMD-12345
- **Max Prize**: 2,000,000 HTG
- **Target Audience**: High-stakes players
- **Gradient Suggestion**: #22d3ee → #06b6d4

---

## Implementation Guidelines

### For Graphic Designers

1. **Dimensions**
   - Physical ticket: 85mm × 55mm (standard credit card size)
   - Digital display: 400px × 250px (16:10 ratio)
   - High resolution: 300 DPI for print

2. **Color Usage**
   - Primary background: Category color at 100% opacity
   - Header/Footer banners: Category color at 80-90% opacity (darker)
   - Scratch area border: Category color at 100% opacity
   - Text: White on dark backgrounds, dark on light backgrounds

3. **Spacing**
   - Margin: 8-10px from edges
   - Element padding: 12-16px
   - Line height: 1.4-1.6

4. **Scratch Area Implementation**
   - Overlay: Gray (#808080) at 80% opacity
   - Border: 3px solid in category color
   - Corner radius: 8px
   - Should reveal prize information when scratched

### For Flutter Developers

1. **Widget Requirements**
   - Responsive design
   - Support preview and active modes
   - Handle ticket number display/hiding
   - Category-based color theming
   - Optional scratch functionality

2. **Model Requirements**
   - Enum for ticket categories
   - Helper methods for color retrieval
   - Validation for ticket codes
   - Prize calculation methods

### For Web Developers

1. **HTML/CSS Requirements**
   - Responsive layout (mobile-first)
   - CSS Grid/Flexbox for ticket gallery
   - Print-friendly styles
   - Hover effects for interactivity

2. **Accessibility**
   - Sufficient color contrast (WCAG AA minimum)
   - Alt text for images
   - Keyboard navigation support

---

## File Organization

### Asset Structure
```
assets/
  ticket-designs/
    basic/
      ticket-template.png
      scratch-overlay.png
    premium/
      ticket-template.png
      scratch-overlay.png
    bronze/
      ticket-template.png
      scratch-overlay.png
    silver/
      ticket-template.png
      scratch-overlay.png
    gold/
      ticket-template.png
      scratch-overlay.png
    diamond/
      ticket-template.png
      scratch-overlay.png
    shared/
      logo.png
      logo.svg
```

---

## Design Validation Checklist

Before finalizing any ticket design, ensure:

- [ ] Logo "GRATE GENYEN" is clearly visible
- [ ] Category color matches specification exactly
- [ ] Price is correctly displayed in header
- [ ] Ticket code format matches specification
- [ ] Max prize amount is accurate
- [ ] Scratch area is properly positioned
- [ ] All text is legible and properly contrasted
- [ ] Layout is consistent with other tickets
- [ ] Design works at both physical and digital sizes
- [ ] Print quality is 300 DPI or higher

---

## Usage Examples

### Sample Ticket Numbers

- BASIC: `XYZ-000001`, `XYZ-000002`, `XYZ-999999`
- PREMIUM: `EFG-000001`, `EFG-000002`, `EFG-999999`
- BRONZE: `JKL-000001`, `JKL-000002`, `JKL-999999`
- SILVER: `ABC-000001`, `ABC-000002`, `ABC-999999`
- GOLD: `GOLD-00001`, `GOLD-00002`, `GOLD-99999`
- DIAMOND: `DMD-00001`, `DMD-00002`, `DMD-99999`

### Sample Prize Messages

- "FÉLICITATIONS! Vous avez gagné [AMOUNT] HTG" (Congratulations! You won)
- "Merci de jouer! Essayez encore" (Thanks for playing! Try again)
- "GRAND PRIX! [AMOUNT] HTG!" (Grand Prize!)

---

## Brand Guidelines

### Official Colors (Hex)
- Primary Green (BASIC): `#10b981`
- Primary Purple (PREMIUM): `#7c3aed`
- Primary Orange (BRONZE): `#ea580c`
- Primary Silver (SILVER): `#cbd5e1`
- Primary Gold (GOLD): `#fbbf24`
- Primary Cyan (DIAMOND): `#22d3ee`

### Typography
- Primary Font: System default sans-serif or "Inter", "Roboto", "Helvetica"
- Code Font: "Monaco", "Courier New", monospace

### Spacing System
- XS: 4px
- SM: 8px
- MD: 12px
- LG: 16px
- XL: 24px
- 2XL: 32px

---

## Version History

- **v1.0** (2026-02-17): Initial design guide created with all 6 ticket categories

---

## Contact & Support

For questions about ticket designs or implementation:
- Technical: Refer to code documentation in `flutter_app/lib/models/ticket_category.dart`
- Design Assets: See `raffle-app/public/ticket-designs/README.md`
- Updates: Check repository for latest specifications

---

## License

This design system is proprietary to Grate Genyen. All designs and specifications are confidential.
