# Ticket Design Assets

This directory contains design assets for all Grate Genyen raffle ticket categories.

## Purpose

This folder is a placeholder for future ticket design images and assets. When graphic designers create the actual ticket designs, they should be placed here following the structure below.

## Directory Structure

```
ticket-designs/
├── README.md (this file)
├── basic/
│   ├── ticket-template.png
│   ├── ticket-template@2x.png
│   ├── ticket-template@3x.png
│   └── scratch-overlay.png
├── premium/
│   ├── ticket-template.png
│   ├── ticket-template@2x.png
│   ├── ticket-template@3x.png
│   └── scratch-overlay.png
├── bronze/
│   ├── ticket-template.png
│   ├── ticket-template@2x.png
│   ├── ticket-template@3x.png
│   └── scratch-overlay.png
├── silver/
│   ├── ticket-template.png
│   ├── ticket-template@2x.png
│   ├── ticket-template@3x.png
│   └── scratch-overlay.png
├── gold/
│   ├── ticket-template.png
│   ├── ticket-template@2x.png
│   ├── ticket-template@3x.png
│   └── scratch-overlay.png
├── diamond/
│   ├── ticket-template.png
│   ├── ticket-template@2x.png
│   ├── ticket-template@3x.png
│   └── scratch-overlay.png
└── shared/
    ├── logo.png
    ├── logo.svg
    ├── logo@2x.png
    └── logo@3x.png
```

## File Specifications

### Ticket Template Images

Each category folder should contain ticket template images at three resolutions:

- **ticket-template.png**: Base resolution (400x250px at 72 DPI)
- **ticket-template@2x.png**: Double resolution (800x500px at 144 DPI)
- **ticket-template@3x.png**: Triple resolution (1200x750px at 216 DPI)

### Scratch Overlay

- **scratch-overlay.png**: Gray overlay image for the scratch area
- Dimensions: Match the scratch area size on the ticket template
- Format: PNG with alpha transparency
- Color: Gray (#808080) at 80% opacity

### Logo Images

Shared logo assets for all tickets:

- **logo.png**: Base logo (100x100px)
- **logo.svg**: Vector logo (scalable)
- **logo@2x.png**: Double resolution logo (200x200px)
- **logo@3x.png**: Triple resolution logo (300x300px)

## Design Specifications

### Ticket Categories and Colors

| Category | Background Color | Code Format | Max Prize (HTG) |
|----------|------------------|-------------|-----------------|
| BASIC    | #10b981 (Green)  | XYZ-######  | 5,000           |
| PREMIUM  | #7c3aed (Purple) | EFG-######  | 10,000          |
| BRONZE   | #ea580c (Orange) | JKL-######  | 25,000          |
| SILVER   | #cbd5e1 (Silver) | ABC-######  | 150,000         |
| GOLD     | #fbbf24 (Gold)   | GOLD-#####  | 500,000         |
| DIAMOND  | #22d3ee (Cyan)   | DMD-#####   | 2,000,000       |

### Ticket Layout Requirements

All tickets must include:

1. **Top Section**:
   - "GRATE GENYEN" logo/text (centered, bold)
   - Size: 20-24pt

2. **Header Banner** (split layout):
   - Left: "GRATE TOUT"
   - Right: Price (e.g., "50 HTG")
   - Background: Darker shade of category color
   - Text: White, bold

3. **Body Section**:
   - Category name (e.g., "BASIC", "PREMIUM")
   - Ticket code placeholder or actual number
   - Scratch area with border (color: category color)

4. **Footer Banner**:
   - Text: "GAGNER JUSQU'À [MAX_PRIZE] HTG"
   - Background: Darker shade of category color
   - Text: White, bold

### Design Dimensions

- **Physical Print**: 85mm × 55mm (credit card size) at 300 DPI
- **Digital Display**: 400px × 250px (16:10 aspect ratio)
- **Aspect Ratio**: 1.6:1 (16:10)

### Color Usage Guidelines

1. **Background**: Use the specified category color as the primary background
2. **Gradient**: Optional gradient from category color to its darker shade
3. **Text**: 
   - White text on all categories except SILVER
   - Black text on SILVER category (for better contrast)
4. **Borders**: Use category color at 100% opacity
5. **Scratch Area**: Gray overlay (#808080) at 80% opacity with category color border

### Typography

- **Primary Font**: Sans-serif (Inter, Roboto, or Helvetica)
- **Code Font**: Monospace (Monaco, Courier New)
- **Logo**: Bold, uppercase
- **Body Text**: Semi-bold to bold
- **Sizes**: Refer to TICKET_DESIGN_GUIDE.md in repository root

## File Format Requirements

### For Web (HTML Gallery)

- Format: PNG with transparency
- Resolution: 400x250px (1x), 800x500px (2x)
- Color Space: sRGB
- Compression: Optimized for web (< 100KB per image)

### For Flutter App

- Format: PNG with transparency
- Multiple resolutions (@1x, @2x, @3x)
- Color Space: sRGB
- Asset loading: Via `pubspec.yaml` configuration

### For Print

- Format: PNG or PDF
- Resolution: 300 DPI minimum
- Size: 85mm × 55mm
- Color Space: CMYK (for print) or sRGB (for digital)
- Bleed: 2mm on all sides

## How to Add New Assets

### Step 1: Create the Design

1. Open your design software (Figma, Adobe Illustrator, Photoshop, etc.)
2. Use the specifications from `TICKET_DESIGN_GUIDE.md`
3. Create the ticket design matching the category specifications
4. Ensure all required elements are included

### Step 2: Export the Files

1. Export at three resolutions: 1x, 2x, 3x
2. Use PNG format with transparency
3. Optimize file sizes for web/mobile use
4. Name files according to the structure above

### Step 3: Place Files in Correct Directories

**For Flutter App:**
```bash
# Place in flutter_app/assets/ticket-designs/
cp ticket-template.png flutter_app/assets/ticket-designs/basic/
cp ticket-template@2x.png flutter_app/assets/ticket-designs/basic/
cp ticket-template@3x.png flutter_app/assets/ticket-designs/basic/
```

**For Web Gallery:**
```bash
# Also place in raffle-app/public/ticket-designs/
cp ticket-template.png raffle-app/public/ticket-designs/basic/
```

### Step 4: Update Code (if necessary)

If you're adding new ticket categories or changing the structure:

1. Update `flutter_app/lib/models/ticket_category.dart`
2. Update `flutter_app/lib/widgets/ticket_design_card.dart`
3. Update `raffle-app/public/ticket-gallery.html`

## Testing Your Designs

### Visual Testing

1. View designs in the Flutter app ticket gallery
2. Check the web gallery at `raffle-app/public/ticket-gallery.html`
3. Test on different screen sizes (mobile, tablet, desktop)
4. Verify colors match specifications exactly

### Print Testing

1. Print a test copy at actual size (85mm × 55mm)
2. Verify all text is legible
3. Check color accuracy
4. Ensure scratch area is properly positioned

## Design Tools and Resources

### Recommended Tools

- **Figma**: Web-based design (collaborative)
- **Adobe Illustrator**: Vector graphics
- **Adobe Photoshop**: Raster graphics
- **Sketch**: Mac-based design tool
- **Affinity Designer**: Alternative to Adobe tools

### Color Reference

Use these exact hex codes for consistency:

```css
/* BASIC */
--basic-color: #10b981;
--basic-dark: #059669;

/* PREMIUM */
--premium-color: #7c3aed;
--premium-dark: #6d28d9;

/* BRONZE */
--bronze-color: #ea580c;
--bronze-dark: #c2410c;

/* SILVER */
--silver-color: #cbd5e1;
--silver-dark: #94a3b8;

/* GOLD */
--gold-color: #fbbf24;
--gold-dark: #f59e0b;

/* DIAMOND */
--diamond-color: #22d3ee;
--diamond-dark: #06b6d4;
```

## Current Status

**Status**: Placeholder structure created ✅

Assets needed:
- [ ] BASIC ticket templates (3 resolutions)
- [ ] PREMIUM ticket templates (3 resolutions)
- [ ] BRONZE ticket templates (3 resolutions)
- [ ] SILVER ticket templates (3 resolutions)
- [ ] GOLD ticket templates (3 resolutions)
- [ ] DIAMOND ticket templates (3 resolutions)
- [ ] Shared logo assets (PNG and SVG)
- [ ] Scratch overlay images

## Support

For questions or issues:

1. Refer to `/TICKET_DESIGN_GUIDE.md` for complete design specifications
2. Check `flutter_app/lib/models/ticket_category.dart` for category definitions
3. Review `flutter_app/lib/widgets/ticket_design_card.dart` for implementation details
4. Contact the development team for technical assistance

## Version History

- **v1.0** (2026-02-17): Initial structure and documentation created

---

**Note**: This is a living document. Update it as the design system evolves and new assets are added.
