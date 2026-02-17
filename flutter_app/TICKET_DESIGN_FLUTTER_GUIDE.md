# Ticket Design System - Flutter Implementation Guide

## Overview

This guide explains how to use the ticket design system in the Flutter app. The system provides a consistent way to display all 6 ticket categories (BASIC, PREMIUM, BRONZE, SILVER, GOLD, DIAMOND) with their correct specifications.

## Quick Start

### 1. Import Required Files

```dart
import 'package:raffle_app/models/ticket_category.dart';
import 'package:raffle_app/widgets/ticket_design_card.dart';
```

### 2. Display a Single Ticket

```dart
// Preview mode (no ticket number)
TicketDesignCard(
  tier: TicketTier.gold,
  isPreview: true,
)

// With a specific ticket number
TicketDesignCard(
  tier: TicketTier.diamond,
  ticketNumber: 'DMD-12345',
  isPreview: false,
)
```

### 3. Display All Tickets in a Gallery

```dart
TicketDesignGallery(
  showAllTiers: true,
  onTierTap: (tier) {
    // Handle tier selection
    print('Selected: ${tier.name}');
  },
)
```

## Components

### 1. TicketTier Enum

Defines all 6 ticket categories with their specifications:

```dart
enum TicketTier {
  basic,    // 50 HTG
  premium,  // 100 HTG
  bronze,   // 250 HTG
  silver,   // 500 HTG
  gold,     // 1,000 HTG
  diamond,  // 5,000 HTG
}
```

### 2. TicketTier Extension Methods

Access ticket specifications:

```dart
final tier = TicketTier.gold;

// Basic properties
tier.name;              // "GOLD"
tier.price;             // 1000.0
tier.maxPrize;          // 500000.0
tier.codePrefix;        // "GOLD"
tier.codeFormat;        // "GOLD-#####"

// Colors
tier.backgroundColor;   // Color(0xFFfbbf24)
tier.darkerShade;       // Color(0xFFf59e0b)
tier.textColor;         // Colors.white
tier.gradientColors;    // [backgroundColor, darkerShade]

// Utilities
tier.generateSampleCode(123);  // "GOLD-00123"
tier.formattedMaxPrize;        // "500K HTG"
```

### 3. TicketDesignCard Widget

Main widget for displaying a ticket:

```dart
TicketDesignCard(
  tier: TicketTier.silver,           // Required: Which tier to display
  ticketNumber: 'ABC-123456',        // Optional: Specific ticket number
  isPreview: false,                  // Optional: Preview mode (default: false)
  onTap: () => print('Tapped!'),     // Optional: Tap handler
  width: 400,                        // Optional: Custom width
  height: 250,                       // Optional: Custom height
)
```

**Properties:**
- `tier` (required): The ticket tier to display
- `ticketNumber` (optional): If provided, shows this specific number; if null, shows format
- `isPreview` (optional): When true, shows code format instead of number
- `onTap` (optional): Callback when ticket is tapped
- `width` (optional): Custom width (maintains 16:10 aspect ratio)
- `height` (optional): Custom height (maintains 16:10 aspect ratio)

### 4. TicketDesignGallery Widget

Grid display of multiple tickets:

```dart
TicketDesignGallery(
  showAllTiers: true,                    // Show all 6 tiers
  specificTiers: [                       // Or specific tiers
    TicketTier.gold,
    TicketTier.diamond,
  ],
  onTierTap: (tier) {                    // Tap handler
    Navigator.push(...);
  },
)
```

### 5. TicketSpecificationCard Widget

Display detailed specifications for a tier:

```dart
TicketSpecificationCard(
  tier: TicketTier.premium,
)
```

Shows:
- Price
- Code format
- Max prize
- Formatted prize
- Color swatch and hex code

## Usage Examples

### Example 1: Simple Ticket Display

```dart
class MyTicketScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Ticket')),
      body: Center(
        child: TicketDesignCard(
          tier: TicketTier.bronze,
          ticketNumber: 'JKL-456789',
          onTap: () {
            // Handle tap - maybe show scratch interface
          },
        ),
      ),
    );
  }
}
```

### Example 2: Ticket Selection Gallery

```dart
class TicketSelectionScreen extends StatefulWidget {
  @override
  _TicketSelectionScreenState createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  TicketTier? selectedTier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Your Ticket')),
      body: TicketDesignGallery(
        showAllTiers: true,
        onTierTap: (tier) {
          setState(() {
            selectedTier = tier;
          });
          // Navigate to purchase screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseScreen(tier: tier),
            ),
          );
        },
      ),
    );
  }
}
```

### Example 3: Ticket with Specifications

```dart
class TicketDetailScreen extends StatelessWidget {
  final TicketTier tier;
  
  const TicketDetailScreen({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${tier.name} Ticket')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Large ticket preview
            TicketDesignCard(
              tier: tier,
              ticketNumber: tier.generateSampleCode(123456),
            ),
            
            SizedBox(height: 24),
            
            // Specifications
            TicketSpecificationCard(tier: tier),
            
            SizedBox(height: 24),
            
            // Purchase button
            ElevatedButton(
              onPressed: () => _purchaseTicket(tier),
              child: Text('Purchase for ${tier.price.toStringAsFixed(0)} HTG'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _purchaseTicket(TicketTier tier) {
    // Handle purchase
  }
}
```

### Example 4: Dynamic Ticket List

```dart
class MyTicketsScreen extends StatelessWidget {
  final List<PurchasedTicket> tickets = [
    PurchasedTicket(tier: TicketTier.basic, number: 'XYZ-001234'),
    PurchasedTicket(tier: TicketTier.premium, number: 'EFG-005678'),
    PurchasedTicket(tier: TicketTier.gold, number: 'GOLD-12345'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Tickets')),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: TicketDesignCard(
              tier: ticket.tier,
              ticketNumber: ticket.number,
              onTap: () => _showTicketDetail(ticket),
            ),
          );
        },
      ),
    );
  }
  
  void _showTicketDetail(PurchasedTicket ticket) {
    // Show ticket detail
  }
}
```

## Integration with Existing Models

### Convert API Response to TicketTier

```dart
// From TicketCategory to TicketTier
final category = TicketCategory.fromJson(apiResponse);
final tier = category.tier; // Returns TicketTier? based on category name

// From TicketTier to TicketCategory
final tier = TicketTier.premium;
final category = TicketCategory.fromTier(
  tier,
  onlineAvailable: 100,
  onlineTotal: 500,
);
```

### Using with Existing TicketCategory

```dart
// If you have an existing TicketCategory object
final category = ticketProvider.getCategory('GOLD');
final tier = category.tier;

if (tier != null) {
  // Display ticket with design system
  TicketDesignCard(
    tier: tier,
    ticketNumber: someTicketNumber,
  );
}
```

## Color Specifications

All colors are defined in the `TicketTier` extension:

| Tier    | Background | Dark Shade | Hex Background | Hex Dark   |
|---------|------------|------------|----------------|------------|
| BASIC   | Green      | Darker Green | #10b981      | #059669    |
| PREMIUM | Purple     | Darker Purple | #7c3aed     | #6d28d9    |
| BRONZE  | Orange     | Darker Orange | #ea580c     | #c2410c    |
| SILVER  | Silver     | Darker Silver | #cbd5e1     | #94a3b8    |
| GOLD    | Gold       | Darker Gold   | #fbbf24     | #f59e0b    |
| DIAMOND | Cyan       | Darker Cyan   | #22d3ee     | #06b6d4    |

## Customization

### Custom Sizing

```dart
// Small ticket
TicketDesignCard(
  tier: TicketTier.basic,
  width: 200,  // Will maintain 16:10 aspect ratio
)

// Large ticket
TicketDesignCard(
  tier: TicketTier.diamond,
  height: 400, // Will maintain 16:10 aspect ratio
)
```

### Custom Grid Layout

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,  // 3 columns
    childAspectRatio: 1.6,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: TicketTier.values.length,
  itemBuilder: (context, index) {
    return TicketDesignCard(
      tier: TicketTier.values[index],
      isPreview: true,
    );
  },
)
```

## Best Practices

1. **Use Preview Mode for Templates**: When showing ticket designs without specific numbers, use `isPreview: true`

2. **Show Actual Numbers for Purchased Tickets**: For tickets owned by users, always show the actual ticket number

3. **Maintain Aspect Ratio**: The ticket design uses a 16:10 aspect ratio. If you specify custom dimensions, the widget will maintain this ratio

4. **Handle Taps Appropriately**: Use `onTap` for navigation or showing ticket details

5. **Responsive Design**: Use `GridView` with `SliverGridDelegateWithFixedCrossAxisCount` for responsive layouts

## Testing

### Example Test File

Create `test/widgets/ticket_design_card_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:raffle_app/models/ticket_category.dart';
import 'package:raffle_app/widgets/ticket_design_card.dart';

void main() {
  testWidgets('TicketDesignCard displays correct tier info', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TicketDesignCard(
            tier: TicketTier.gold,
            ticketNumber: 'GOLD-12345',
          ),
        ),
      ),
    );

    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('GOLD-12345'), findsOneWidget);
    expect(find.text('GAGNER JUSQU\'À 500,000 HTG'), findsOneWidget);
  });

  test('TicketTier generates correct sample codes', () {
    expect(TicketTier.basic.generateSampleCode(1), 'XYZ-000001');
    expect(TicketTier.premium.generateSampleCode(123), 'EFG-000123');
    expect(TicketTier.gold.generateSampleCode(999), 'GOLD-00999');
  });

  test('TicketTier has correct prices', () {
    expect(TicketTier.basic.price, 50.0);
    expect(TicketTier.premium.price, 100.0);
    expect(TicketTier.diamond.price, 5000.0);
  });
}
```

## Demo Screens

Example screens are available in `lib/screens/ticket_design_example_screen.dart`:

1. **TicketDesignExampleScreen**: Full-featured gallery with toggle for ticket numbers
2. **SimpleTicketExample**: Basic usage example
3. **ComparisonExample**: Side-by-side comparison of all tiers

To test:

```dart
// In your main.dart or routing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TicketDesignExampleScreen(),
  ),
);
```

## Troubleshooting

### Issue: Colors don't match specifications
**Solution**: Ensure you're using the `tier.backgroundColor` and `tier.darkerShade` properties, not custom colors.

### Issue: Text is hard to read on SILVER tickets
**Solution**: The SILVER tier automatically uses dark text (`Colors.black87`). Use `tier.textColor` for consistency.

### Issue: Tickets appear stretched or squashed
**Solution**: The widget maintains a 16:10 aspect ratio. Don't force both width and height unless you account for this ratio.

### Issue: Ticket number doesn't appear
**Solution**: Set `isPreview: false` and provide a `ticketNumber` parameter.

## Assets

When actual ticket images are created by designers, place them in:

```
flutter_app/assets/ticket-designs/
  ├── basic/
  ├── premium/
  ├── bronze/
  ├── silver/
  ├── gold/
  ├── diamond/
  └── shared/
```

Refer to `raffle-app/public/ticket-designs/README.md` for complete asset specifications.

## Related Documentation

- Root: `/TICKET_DESIGN_GUIDE.md` - Complete design system documentation
- Assets: `/raffle-app/public/ticket-designs/README.md` - Asset specifications
- Web: `/raffle-app/public/ticket-gallery.html` - Web gallery view

## Support

For questions or issues with the ticket design system:
1. Check the root `TICKET_DESIGN_GUIDE.md` for design specifications
2. Review example implementations in `lib/screens/ticket_design_example_screen.dart`
3. Consult this guide for Flutter-specific usage

---

**Version**: 1.0  
**Last Updated**: 2026-02-17  
**Maintainer**: Development Team
