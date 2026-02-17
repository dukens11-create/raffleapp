# Ticket Design Guide - Grate Genyen Raffle System

## Overview
This guide provides complete specifications for the 6-tier ticket design system used in the Grate Genyen raffle application. All designs follow a consistent template based on the SILVER ticket reference design.

## Design Philosophy
- **Consistency**: All tickets share the same layout, logo, and structural elements
- **Visual Hierarchy**: Category differentiation through color-coded themes
- **Cultural Relevance**: Haitian Creole text and locally relevant imagery
- **Print-Ready**: High resolution designs suitable for physical printing
- **Digital-Optimized**: Responsive scaling for mobile and web displays

---

## Base Template Elements

### Header Section
**Left Banner: "GRATE TOUT"**
- Position: Top-left corner
- Background: Brown banner (#8B4513)
- Text: White, bold
- Font Style: Sans-serif, uppercase

**Right Banner: Price Display**
- Position: Top-right corner  
- Background: Brown banner (#8B4513)
- Text: "XXX GOURDES" in white
- Font Style: Sans-serif, bold

### Center Logo
**"GRATE GENYEN" Branding**
- "GRATE": Yellow text (#FFD700) with 3D shadow effect
- "GENYEN": Light blue text (#87CEEB) with 3D shadow effect
- Position: Upper center of ticket
- Style: Large, prominent, eye-catching

### Category Banner
**Metallic Ribbon**
- Position: Center of ticket
- Style: 3D metallic ribbon effect matching category color
- Text: Category name (BASIC, PREMIUM, BRONZE, SILVER, GOLD, DIAMOND)
- Font: Bold, uppercase, contrasting color for readability

### Scratch Area
**Ticket Number Box**
- Position: Center-lower section
- Style: White rectangular box
- Purpose: Display unique ticket number
- Format: XXX-###### or XXXX-#####

### Bottom Section
**Category Label**
- Position: Below scratch area
- Text: Repeats category name
- Style: Category-colored text

**Prize Banner**
- Position: Bottom of ticket
- Background: Brown banner (#8B4513)
- Text: "GRATE & GENYEN JISKA [PRIZE] GOURDES!"
- Font: White, bold, centered

### Background Effects
- Sparkly glitter texture throughout
- Confetti/sparkle decorative elements
- Category-specific color gradient

---

## Ticket Specifications

### 1. BASIC Ticket (50 HTG)
**Colors**
- Background Gradient: Emerald green sparkle
  - Primary: #10b981
  - Secondary: #059669
  - Accent: #047857
- Metallic Ribbon: Green metallic

**Text Content**
- Price Banner: "50 GOURDES"
- Prize Banner: "GRATE & GENYEN JISKA 5,000 GOURDES!"
- Ticket Code Format: `XYZ-######`

**Target Audience**: Entry-level players
**Max Prize**: 5,000 HTG
**File**: `ticket-designs/BASIC-50-HTG.png`
**Flutter Asset**: `assets/images/tickets/basic_ticket.png`

---

### 2. PREMIUM Ticket (100 HTG)
**Colors**
- Background Gradient: Purple sparkle
  - Primary: #7c3aed
  - Secondary: #6366f1
  - Accent: #8b5cf6
- Metallic Ribbon: Purple metallic

**Text Content**
- Price Banner: "100 GOURDES"
- Prize Banner: "GRATE & GENYEN JISKA 10,000 GOURDES!"
- Ticket Code Format: `EFG-######`

**Target Audience**: Regular players
**Max Prize**: 10,000 HTG (updated from 15,000)
**File**: `ticket-designs/PREMIUM-100-HTG.png`
**Flutter Asset**: `assets/images/tickets/premium_ticket.png`

---

### 3. BRONZE Ticket (250 HTG)
**Colors**
- Background Gradient: Orange-red sparkle
  - Primary: #ea580c
  - Secondary: #dc2626
  - Accent: #c2410c
- Metallic Ribbon: Bronze metallic

**Text Content**
- Price Banner: "250 GOURDES"
- Prize Banner: "GRATE & GENYEN JISKA 25,000 GOURDES!"
- Ticket Code Format: `JKL-######`

**Target Audience**: Mid-tier players
**Max Prize**: 25,000 HTG (updated from 50,000)
**File**: `ticket-designs/BRONZE-250-HTG.png`
**Flutter Asset**: `assets/images/tickets/bronze_ticket.png`

---

### 4. SILVER Ticket (500 HTG) ✅ Reference Design
**Colors**
- Background Gradient: Silver sparkle
  - Primary: #cbd5e1
  - Secondary: #94a3b8
  - Accent: #64748b
- Metallic Ribbon: Silver metallic

**Text Content**
- Price Banner: "500 GOURDES"
- Prize Banner: "GRATE & GENYEN JISKA 150,000 GOURDES!"
- Ticket Code Format: `ABC-######`

**Target Audience**: Premium players
**Max Prize**: 150,000 HTG
**File**: `ticket-designs/SILVER-500-HTG.png` (Reference image)
**Flutter Asset**: `assets/images/tickets/silver_ticket.png`

---

### 5. GOLD Ticket (1,000 HTG)
**Colors**
- Background Gradient: Gold sparkle
  - Primary: #fbbf24
  - Secondary: #f59e0b
  - Accent: #d97706
- Metallic Ribbon: Gold metallic

**Text Content**
- Price Banner: "1,000 GOURDES"
- Prize Banner: "GRATE & GENYEN JISKA 500,000 GOURDES!"
- Ticket Code Format: `GOLD-#####`

**Target Audience**: High-stakes players
**Max Prize**: 500,000 HTG (updated from 250,000)
**File**: `ticket-designs/GOLD-1000-HTG.png`
**Flutter Asset**: `assets/images/tickets/gold_ticket.png`

---

### 6. DIAMOND Ticket (5,000 HTG)
**Colors**
- Background Gradient: Cyan/diamond sparkle
  - Primary: #22d3ee
  - Secondary: #06b6d4
  - Accent: #0891b2
- Metallic Ribbon: Cyan metallic

**Text Content**
- Price Banner: "5,000 GOURDES"
- Prize Banner: "GRATE & GENYEN JISKA 2,000,000 GOURDES!"
- Ticket Code Format: `DMD-#####`

**Target Audience**: VIP players
**Max Prize**: 2,000,000 HTG (updated from 1,000,000)
**File**: `ticket-designs/DIAMOND-5000-HTG.png`
**Flutter Asset**: `assets/images/tickets/diamond_ticket.png`

---

## Technical Specifications

### Image Format
- **File Type**: PNG with transparency support
- **Resolution**: Minimum 1024x1024px
- **Print Resolution**: 300 DPI for physical tickets
- **Color Space**: sRGB for digital, CMYK for print
- **Compression**: Optimized for web (< 500KB per image)

### Dimensions
- **Aspect Ratio**: 1:1 (square) or 2:3 (portrait)
- **Safe Area**: 10% margin from edges
- **Text Minimum Size**: 12pt for readability
- **QR Code Area**: Reserved bottom-right corner (optional)

### Typography
**Primary Font Stack**:
1. System fonts for performance
2. Web-safe fallbacks
3. Sans-serif default

**Font Sizes**:
- Header Text: 24-32pt
- Logo Text: 48-64pt
- Category Banner: 36-48pt
- Prize Text: 18-24pt
- Ticket Number: 16-20pt

### Color Accessibility
- Contrast Ratio: Minimum 4.5:1 for text
- Color Blindness: Tested with Deuteranopia simulation
- Print Test: Verified on standard office printers

---

## Design Asset Locations

### Public Web Assets
```
raffle-app/public/ticket-designs/
├── BASIC-50-HTG.png
├── PREMIUM-100-HTG.png
├── BRONZE-250-HTG.png
├── SILVER-500-HTG.png
├── GOLD-1000-HTG.png
├── DIAMOND-5000-HTG.png
└── README.md
```

### Flutter Assets
```
flutter_app/assets/images/tickets/
├── basic_ticket.png
├── premium_ticket.png
├── bronze_ticket.png
├── silver_ticket.png
├── gold_ticket.png
└── diamond_ticket.png
```

---

## Usage Guidelines

### Digital Display
1. **Mobile Apps**: Use Flutter asset references
2. **Web Portal**: Reference from `/public/ticket-designs/`
3. **Email**: Use CDN links or embedded images
4. **Social Media**: Export at platform-specific dimensions

### Print Production
1. Export at 300 DPI minimum
2. Use CMYK color mode
3. Include bleed area (3mm)
4. Verify colors with print test
5. Use thick card stock (300gsm recommended)

### Security Features (Optional)
- Holographic overlay
- UV-reactive ink
- Microprint text
- QR codes for verification
- Serial number tracking

---

## Maintenance & Updates

### Version Control
- All design files tracked in Git
- Version naming: v1.0, v1.1, etc.
- Change log in this document

### Update Process
1. Design changes in source files
2. Export at specified resolutions
3. Update both web and Flutter assets
4. Test on all target platforms
5. Deploy with version tag

### Quality Checklist
- [ ] All text readable at minimum size
- [ ] Colors match specification exactly
- [ ] File sizes optimized
- [ ] Works on light and dark backgrounds
- [ ] Print test completed
- [ ] Mobile responsive scaling verified
- [ ] Accessibility standards met

---

## Contact & Support
For design questions or asset requests, contact the development team.

**Last Updated**: 2026-02-17
**Version**: 1.0
**Maintained by**: Grate Genyen Development Team
