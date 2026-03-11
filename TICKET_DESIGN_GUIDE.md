# Ticket Design System Guide

## Overview
This guide defines the complete visual design system for all 6 ticket tiers in the Grate Genyen raffle application. All tickets follow the same layout structure as the reference SILVER ticket design, with tier-specific colors and text.

## Design Philosophy
- **Consistent Layout**: All tickets share the same structural layout
- **Tier Differentiation**: Each tier uses unique background colors and pricing
- **Visual Hierarchy**: Clear pricing, category badges, and prize information
- **Scratch-Off Area**: White rectangular scratch area for code reveal
- **Branding**: Consistent "GRATE GENYEN" branding across all tickets

## Common Design Elements

### Layout Structure
1. **Top Banner** (Brown)
   - Left: "GRATE TOUT" text
   - Right: Price in "GOURDES"
   
2. **Logo Section** (Center)
   - "GRATE GENYEN" logo
   - Yellow + Light Blue 3D text effect
   
3. **Category Ribbon** (Metallic)
   - Centered ribbon with category name
   - Metallic/glossy appearance
   
4. **Scratch Area** (White Rectangle)
   - White background
   - Contains hidden code
   - "Scratch to reveal" instruction
   
5. **Bottom Banner** (Brown)
   - Prize information
   - Format: "GRATE & GENYEN JISKA [AMOUNT] GOURDES!"

### Typography
- **Headers**: Bold, sans-serif
- **Logo**: 3D effect with shadow
- **Prices**: Large, bold, high contrast
- **Body Text**: Clean, readable sans-serif

### Color Palette Codes
- **Brown Banners**: `#8b4513`
- **Yellow Logo**: `#fbbf24`
- **Light Blue Logo**: `#38bdf8`
- **White Scratch**: `#ffffff`
- **Text Dark**: `#1e293b`
- **Text Light**: `#f8fafc`

## Ticket Tier Specifications

### 1. BASIC Ticket
- **Price**: 50 HTG (Haitian Gourdes)
- **Background Color**: Emerald Green Sparkle (#10b981)
- **Category Badge**: "BASIC"
- **Maximum Prize**: 5,000 GOURDES
- **Code Format**: `XYZ-######` (6 random digits)
- **Color Theme**: Fresh, entry-level green
- **Target Audience**: New players, budget-conscious buyers

#### Design Details
```
Top Banner: "GRATE TOUT" | "50 GOURDES"
Ribbon: "BASIC"
Bottom Banner: "GRATE & GENYEN JISKA 5,000 GOURDES!"
Background: Emerald green (#10b981) with sparkle overlay
```

### 2. PREMIUM Ticket
- **Price**: 100 HTG (Haitian Gourdes)
- **Background Color**: Purple Sparkle (#7c3aed)
- **Category Badge**: "PREMIUM"
- **Maximum Prize**: 10,000 GOURDES
- **Code Format**: `EFG-######` (6 random digits)
- **Color Theme**: Royal purple for premium feel
- **Target Audience**: Regular players seeking better odds

#### Design Details
```
Top Banner: "GRATE TOUT" | "100 GOURDES"
Ribbon: "PREMIUM"
Bottom Banner: "GRATE & GENYEN JISKA 10,000 GOURDES!"
Background: Purple (#7c3aed) with sparkle overlay
```

### 3. BRONZE Ticket
- **Price**: 250 HTG (Haitian Gourdes)
- **Background Color**: Orange-Red Sparkle (#ea580c)
- **Category Badge**: "BRONZE"
- **Maximum Prize**: 25,000 GOURDES
- **Code Format**: `JKL-######` (6 random digits)
- **Color Theme**: Warm bronze/copper tone
- **Target Audience**: Mid-tier players

#### Design Details
```
Top Banner: "GRATE TOUT" | "250 GOURDES"
Ribbon: "BRONZE"
Bottom Banner: "GRATE & GENYEN JISKA 25,000 GOURDES!"
Background: Orange-red (#ea580c) with sparkle overlay
```

### 4. SILVER Ticket (Reference Design)
- **Price**: 500 HTG (Haitian Gourdes)
- **Background Color**: Silver Sparkle (#cbd5e1)
- **Category Badge**: "SILVER"
- **Maximum Prize**: 150,000 GOURDES
- **Code Format**: `ABC-######` (6 random digits)
- **Color Theme**: Shiny silver/metallic
- **Target Audience**: Serious players seeking substantial prizes

#### Design Details
```
Top Banner: "GRATE TOUT" | "500 GOURDES"
Ribbon: "SILVER"
Bottom Banner: "GRATE & GENYEN JISKA 150,000 GOURDES!"
Background: Silver (#cbd5e1) with sparkle/glitter overlay
```

### 5. GOLD Ticket
- **Price**: 1,000 HTG (Haitian Gourdes)
- **Background Color**: Gold Sparkle (#fbbf24)
- **Category Badge**: "GOLD"
- **Maximum Prize**: 500,000 GOURDES
- **Code Format**: `GOLD-#####` (5 random digits)
- **Color Theme**: Luxurious golden shine
- **Target Audience**: High-roller players

#### Design Details
```
Top Banner: "GRATE TOUT" | "1,000 GOURDES"
Ribbon: "GOLD"
Bottom Banner: "GRATE & GENYEN JISKA 500,000 GOURDES!"
Background: Gold (#fbbf24) with sparkle overlay
```

### 6. DIAMOND Ticket
- **Price**: 5,000 HTG (Haitian Gourdes)
- **Background Color**: Cyan Sparkle (#22d3ee)
- **Category Badge**: "DIAMOND"
- **Maximum Prize**: 2,000,000 GOURDES
- **Code Format**: `DMD-#####` (5 random digits)
- **Color Theme**: Brilliant cyan/diamond shimmer
- **Target Audience**: Premium players, collectors

#### Design Details
```
Top Banner: "GRATE TOUT" | "5,000 GOURDES"
Ribbon: "DIAMOND"
Bottom Banner: "GRATE & GENYEN JISKA 2,000,000 GOURDES!"
Background: Cyan (#22d3ee) with sparkle overlay
```

## Technical Implementation

### Sparkle Effect
All backgrounds should include a sparkle/glitter overlay effect:
- Use CSS radial gradients for web
- Use Flutter `ShaderMask` or custom painter for mobile
- Sparkle density: Medium to high
- Sparkle size: 2-5px randomly distributed
- Sparkle colors: White with varying opacity (10-80%)

### Responsive Design
- **Mobile**: Single column, full-width tickets
- **Tablet**: 2-column grid
- **Desktop**: 3-column grid
- Maintain aspect ratio: 2:3 (width:height)
- Minimum width: 280px
- Maximum width: 400px

### Accessibility
- Color contrast ratio: Minimum 4.5:1 for text
- Alt text for all images
- Screen reader support for ticket information
- Keyboard navigation support

## File Structure

```
raffle-app/public/ticket-designs/
├── basic-ticket.svg          (or .png)
├── premium-ticket.svg        (or .png)
├── bronze-ticket.svg         (or .png)
├── silver-ticket.svg         (or .png - reference design)
├── gold-ticket.svg           (or .png)
└── diamond-ticket.svg        (or .png)

flutter_app/assets/ticket-designs/
├── basic-ticket.png
├── premium-ticket.png
├── bronze-ticket.png
├── silver-ticket.png
├── gold-ticket.png
└── diamond-ticket.png
```

## Code Generation

### Ticket Code Formats
Each tier has a unique code prefix for easy identification:

| Tier     | Format       | Example      | Digits |
|----------|--------------|--------------|--------|
| BASIC    | XYZ-######   | XYZ-123456   | 6      |
| PREMIUM  | EFG-######   | EFG-789012   | 6      |
| BRONZE   | JKL-######   | JKL-345678   | 6      |
| SILVER   | ABC-######   | ABC-901234   | 6      |
| GOLD     | GOLD-#####   | GOLD-56789   | 5      |
| DIAMOND  | DMD-#####    | DMD-12345    | 5      |

### Code Generation Rules
1. Each code must be unique within its tier
2. Numbers are randomly generated
3. No sequential patterns (e.g., 123456)
4. Codes are validated against database before issuance
5. QR codes encode full ticket information

## Usage Guidelines

### When to Use Each Tier
- **BASIC**: Daily promotions, new user acquisition
- **PREMIUM**: Regular raffle events
- **BRONZE**: Special weekend events
- **SILVER**: Monthly featured raffles
- **GOLD**: Quarterly mega raffles
- **DIAMOND**: Annual grand prize events

### Marketing Recommendations
- Display all tiers in gallery view
- Highlight prize amounts prominently
- Use tier colors in promotional materials
- Create bundles (e.g., 5 BASIC + 1 PREMIUM)
- Limited edition variants for special occasions

## Future Enhancements
- Animated sparkle effects
- Holographic overlay for premium tiers
- Sound effects on scratch reveal
- Tier upgrade animations
- Collectible designs for holidays/events
- AR (Augmented Reality) ticket viewing

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-17  
**Maintained By**: Grate Genyen Development Team
