import 'package:flutter/material.dart';
import '../models/ticket_category.dart';

/// A widget that displays a ticket design card for any ticket tier.
/// Can show in preview mode (without ticket number) or with a specific ticket number.
class TicketDesignCard extends StatelessWidget {
  final TicketTier tier;
  final String? ticketNumber;
  final bool isPreview;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const TicketDesignCard({
    Key? key,
    required this.tier,
    this.ticketNumber,
    this.isPreview = false,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aspectRatio = 1.6; // 16:10 ratio (400x250)
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tier.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  
                  // Content
                  Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildBody()),
                      _buildFooter(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the header section with logo and price banner
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'GRATE GENYEN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tier.textColor,
              letterSpacing: 2,
            ),
          ),
        ),
        
        // Price banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: tier.darkerShade,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GRATE TOUT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${tier.price.toStringAsFixed(0)} HTG',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the body section with category name, ticket number, and scratch area
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Category name
          Text(
            tier.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tier.textColor,
              letterSpacing: 1.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Ticket number or preview text
          if (!isPreview && ticketNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticketNumber!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: tier.textColor,
                  letterSpacing: 1,
                ),
              ),
            )
          else
            Text(
              tier.codeFormat,
              style: TextStyle(
                fontSize: 14,
                color: tier.textColor.withOpacity(0.7),
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Scratch area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              border: Border.all(
                color: tier.darkerShade,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  color: tier.textColor.withOpacity(0.5),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'ZONE À GRATTER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tier.textColor.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the footer section with prize banner
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: tier.darkerShade,
      ),
      child: Center(
        child: Text(
          'GAGNER JUSQU\'À ${tier.maxPrize.toStringAsFixed(0)} HTG',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// A gallery widget to display all ticket tiers
class TicketDesignGallery extends StatelessWidget {
  final bool showAllTiers;
  final List<TicketTier>? specificTiers;
  final Function(TicketTier)? onTierTap;

  const TicketDesignGallery({
    Key? key,
    this.showAllTiers = true,
    this.specificTiers,
    this.onTierTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tiers = showAllTiers 
        ? TicketTier.values 
        : (specificTiers ?? TicketTier.values);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        return TicketDesignCard(
          tier: tier,
          isPreview: true,
          onTap: onTierTap != null ? () => onTierTap!(tier) : null,
        );
      },
    );
  }
}

/// A widget to display ticket specifications
class TicketSpecificationCard extends StatelessWidget {
  final TicketTier tier;

  const TicketSpecificationCard({
    Key? key,
    required this.tier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tier.name} Ticket',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tier.backgroundColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSpecRow('Price', '${tier.price.toStringAsFixed(0)} HTG'),
            _buildSpecRow('Code Format', tier.codeFormat),
            _buildSpecRow('Max Prize', '${tier.maxPrize.toStringAsFixed(0)} HTG'),
            _buildSpecRow('Formatted Prize', tier.formattedMaxPrize),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Color: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tier.backgroundColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${tier.backgroundColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
