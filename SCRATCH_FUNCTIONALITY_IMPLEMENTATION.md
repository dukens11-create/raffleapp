# Scratch Functionality Implementation for BASIC Ticket

## Overview
This document describes the implementation of interactive scratch functionality for the BASIC ticket with custom background image support in the GRATE GENYEN scratch tickets system.

## Implementation Summary

### Files Modified
1. **raffle-app/public/scratch-tickets.html**
   - Added CSS for custom background image support
   - Updated BASIC ticket configuration with custom image properties
   - Modified `createTicketCard()` method to support custom background images
   - Enhanced `setupCanvas()` method for custom scratch area positioning

### Files Created
1. **raffle-app/public/ticket-designs/basic-ticket.png**
   - Custom background image for BASIC ticket (400x600px, 25KB)
   - Features green sparkly background with all required design elements

2. **raffle-app/public/ticket-designs/README.md**
   - Documentation for the ticket-designs directory

## Key Features Implemented

### 1. Custom Background Image Support
- Added CSS class `.use-custom-image` for tickets with custom backgrounds
- Background image displays behind all ticket elements
- Image is non-interactive (pointer-events: none) to allow scratch functionality

### 2. Positioned Scratch Area
- Scratch overlay positioned at specific coordinates using percentage-based positioning
- BASIC ticket scratch area: 42% from top, 50% horizontal (centered), 45% width, 20% height
- Scratch canvas automatically sized based on container dimensions

### 3. Updated BASIC Ticket Configuration
```javascript
{
  id: 'basic',
  name: 'GRATE GENYEN Basic',
  className: 'ticket-basic',
  price: 50,
  prizeRange: '5,000 GOURDES!',
  coverText: 'GRATE TOUTE',
  category: 'BAS',
  useCustomImage: true,
  imageUrl: '/ticket-designs/basic-ticket.png',
  scratchAreaPosition: {
    top: '42%',
    left: '50%',
    width: '45%',
    height: '20%'
  },
  prizes: [
    { emoji: '🎉', text: 'OU GENYEN\n5,000 GOUD', value: 5000, weight: 1 },
    { emoji: '💎', text: 'OU GENYEN\n2,500 GOUD', value: 2500, weight: 3 },
    { emoji: '🔥', text: 'OU GENYEN\n1,000 GOUD', value: 1000, weight: 10 },
    { emoji: '💰', text: 'OU GENYEN\n500 GOUD', value: 500, weight: 25 },
    { emoji: '🎁', text: 'OU GENYEN\n100 GOUD', value: 100, weight: 60 },
    { emoji: '✨', text: 'OU GENYEN\n5 GOUD', value: 5, weight: 100 },
    { emoji: '😅', text: 'ESEYE ANKÒ', value: 0, weight: 201 }
  ]
}
```

## Technical Details

### CSS Changes
```css
/* Custom ticket background image support */
.ticket-card.use-custom-image {
  position: relative;
  overflow: hidden;
  min-height: 600px;
}

.ticket-card.use-custom-image .ticket-header {
  background: transparent;
  position: relative;
  overflow: visible;
}

.ticket-background-image {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: auto;
  z-index: 0;
  pointer-events: none;
}

.ticket-card.use-custom-image .scratch-area {
  position: static;
  padding: 0;
}

.ticket-card.use-custom-image .scratch-container {
  position: absolute;
  z-index: 5;
}

.ticket-card.use-custom-image canvas {
  position: relative;
  z-index: 10;
}

.ticket-card.use-custom-image .prize-content {
  position: relative;
  z-index: 8;
}
```

### JavaScript Changes

#### Enhanced createTicketCard()
- Checks for `config.useCustomImage` flag
- Adds custom image class to card
- Injects background image element if custom image is enabled

#### Enhanced setupCanvas()
- Applies custom positioning when `config.scratchAreaPosition` is defined
- Forces reflow to ensure correct dimension calculations
- Sets canvas dimensions based on computed container size
- Maintains backward compatibility with non-custom tickets (200px default height)

## Verified Functionality

### ✅ Working Features
1. **Custom Background Display**: BASIC ticket shows custom image with all design elements
2. **Scratch Area Positioning**: Scratch overlay correctly positioned over white box (42% from top)
3. **Canvas Sizing**: Canvas dimensions (170x124px) correctly calculated from percentage-based positioning
4. **Interactive Scratching**: Users can scratch to reveal prizes
5. **Prize Generation**: Random prize selection works with updated probability distribution
6. **New Ticket Generation**: "🔄 New Ticket" button generates new prizes
7. **Progress Tracking**: Scratch percentage updates correctly
8. **Auto-reveal**: Auto-reveal at 55% threshold works
9. **Backward Compatibility**: All other ticket types (Premium, Bronze, Silver, Gold, Diamond) continue to work with default styling

### 📊 Prize Distribution
- Top prize (5,000 GOUD): 0.25% chance
- High prize (2,500 GOUD): 0.75% chance
- Mid-High (1,000 GOUD): 2.5% chance
- Mid (500 GOUD): 6.25% chance
- Low (100 GOUD): 15% chance
- Very Low (5 GOUD): 25% chance
- Loss (ESEYE ANKÒ): 50.25% chance

## Testing Results

### Visual Testing
- ✅ BASIC ticket displays with custom background image
- ✅ All design elements visible (logo, banners, badges, text)
- ✅ Scratch area positioned correctly over white box
- ✅ Other tickets display normally without custom images

### Functional Testing
- ✅ Scratch overlay has correct color and texture
- ✅ Mouse/touch scratching works
- ✅ Prize reveals correctly when scratching
- ✅ Progress percentage updates
- ✅ Auto-reveal triggers at threshold
- ✅ New ticket generation works
- ✅ Random prize selection follows probability distribution

### Compatibility Testing
- ✅ Premium ticket works with default styling
- ✅ Bronze ticket works with default styling
- ✅ Silver ticket works with default styling
- ✅ Gold ticket works with default styling
- ✅ Diamond ticket works with default styling

## Usage

To add custom image support to other ticket types:

1. Create a custom ticket image (400x600px recommended)
2. Save to `raffle-app/public/ticket-designs/`
3. Update ticket configuration:
```javascript
{
  id: 'ticket-id',
  // ... other config ...
  useCustomImage: true,
  imageUrl: '/ticket-designs/your-ticket.png',
  scratchAreaPosition: {
    top: 'Y%',      // Vertical position
    left: '50%',    // Horizontal position (50% = centered)
    width: 'W%',    // Width of scratch area
    height: 'H%'    // Height of scratch area
  }
}
```

## Screenshots

- Full page view: Shows all 6 ticket types with BASIC using custom image
- BASIC ticket close-up: Shows custom background with positioned scratch overlay
- After scratch: Shows prize revealed and scratch functionality working

## Notes

- Image file size: Keep under 500KB for optimal performance
- Image format: PNG recommended for transparency support
- Image dimensions: 400x600px works well with responsive design
- Positioning: Use percentage values for responsive positioning across screen sizes
- Z-index layering: Background (0) < Content (5) < Prize (8) < Canvas (10)

## Future Enhancements

Potential improvements for future iterations:

1. Support for multiple scratch areas per ticket
2. Animated scratch effects
3. Sound effects for scratching
4. Confetti animation for big wins
5. Share functionality for prizes
6. Ticket history/collection feature
