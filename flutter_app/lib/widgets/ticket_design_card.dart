import 'package:flutter/material.dart';

/// Widget for displaying ticket design images with optional ticket number overlay
///
/// This widget handles rendering of the 6-tier ticket design system:
/// - BASIC, PREMIUM, BRONZE, SILVER, GOLD, DIAMOND
///
/// Usage:
/// ```dart
/// // Show ticket design as sample (no ticket number)
/// TicketDesignCard(
///   category: 'SILVER',
///   showAsSample: true,
/// )
///
/// // Show ticket with actual number
/// TicketDesignCard(
///   category: 'GOLD',
///   ticketNumber: 'GOLD-12345',
/// )
/// ```
class TicketDesignCard extends StatelessWidget {
  /// Ticket category: BASIC, PREMIUM, BRONZE, SILVER, GOLD, or DIAMOND
  final String category;

  /// Optional: display actual ticket number on the design
  final String? ticketNumber;

  /// Show as sample (no ticket number overlay)
  final bool showAsSample;

  /// Width of the card (defaults to auto)
  final double? width;

  /// Height of the card (defaults to auto)
  final double? height;

  /// Border radius for the card
  final double borderRadius;

  /// Box shadow elevation
  final double elevation;

  /// Callback when ticket is tapped
  final VoidCallback? onTap;

  const TicketDesignCard({
    Key? key,
    required this.category,
    this.ticketNumber,
    this.showAsSample = false,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.elevation = 4.0,
    this.onTap,
  }) : super(key: key);

  /// Get the image asset path for the specified category
  String _getImageAsset() {
    final categoryLower = category.toLowerCase();
    return 'assets/images/tickets/${categoryLower}_ticket.png';
  }

  /// Get ticket info based on category
  Map<String, dynamic> _getTicketInfo() {
    switch (category.toUpperCase()) {
      case 'BASIC':
        return {
          'color': const Color(0xFF10b981),
          'price': 50,
          'prize': '5,000',
          'codeFormat': 'XYZ-######',
        };
      case 'PREMIUM':
        return {
          'color': const Color(0xFF7c3aed),
          'price': 100,
          'prize': '10,000',
          'codeFormat': 'EFG-######',
        };
      case 'BRONZE':
        return {
          'color': const Color(0xFFea580c),
          'price': 250,
          'prize': '25,000',
          'codeFormat': 'JKL-######',
        };
      case 'SILVER':
        return {
          'color': const Color(0xFF94a3b8),
          'price': 500,
          'prize': '150,000',
          'codeFormat': 'ABC-######',
        };
      case 'GOLD':
        return {
          'color': const Color(0xFFfbbf24),
          'price': 1000,
          'prize': '500,000',
          'codeFormat': 'GOLD-#####',
        };
      case 'DIAMOND':
        return {
          'color': const Color(0xFF22d3ee),
          'price': 5000,
          'prize': '2,000,000',
          'codeFormat': 'DMD-#####',
        };
      default:
        return {
          'color': Colors.grey,
          'price': 0,
          'prize': '0',
          'codeFormat': 'XXX-######',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketInfo = _getTicketInfo();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background ticket image
              _buildTicketImage(),

              // Overlay ticket number if provided and not showing as sample
              if (!showAsSample && ticketNumber != null)
                _buildTicketNumberOverlay(screenWidth, screenHeight),

              // Optional: Show sample badge
              if (showAsSample) _buildSampleBadge(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the ticket image widget
  Widget _buildTicketImage() {
    return Image.asset(
      _getImageAsset(),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image not found - show colored placeholder
        final ticketInfo = _getTicketInfo();
        return _buildPlaceholder(ticketInfo['color']);
      },
    );
  }

  /// Build ticket number overlay
  Widget _buildTicketNumberOverlay(double screenWidth, double screenHeight) {
    return Positioned(
      top: screenHeight * 0.45,
      left: screenWidth * 0.25,
      right: screenWidth * 0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: Text(
          ticketNumber!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  /// Build sample badge overlay
  Widget _buildSampleBadge() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'SAMPLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  /// Build placeholder when image is not available
  Widget _buildPlaceholder(Color color) {
    final ticketInfo = _getTicketInfo();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GRATE GENYEN',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${ticketInfo['price']} GOURDES',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'JISKA ${ticketInfo['prize']} GOURDES!',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Info card showing ticket specifications
class TicketInfoCard extends StatelessWidget {
  final String category;

  const TicketInfoCard({
    Key? key,
    required this.category,
  }) : super(key: key);

  Map<String, dynamic> _getTicketInfo() {
    switch (category.toUpperCase()) {
      case 'BASIC':
        return {
          'color': const Color(0xFF10b981),
          'name': 'BASIC',
          'price': 50,
          'prize': '5,000',
          'code': 'XYZ-######',
        };
      case 'PREMIUM':
        return {
          'color': const Color(0xFF7c3aed),
          'name': 'PREMIUM',
          'price': 100,
          'prize': '10,000',
          'code': 'EFG-######',
        };
      case 'BRONZE':
        return {
          'color': const Color(0xFFea580c),
          'name': 'BRONZE',
          'price': 250,
          'prize': '25,000',
          'code': 'JKL-######',
        };
      case 'SILVER':
        return {
          'color': const Color(0xFF94a3b8),
          'name': 'SILVER',
          'price': 500,
          'prize': '150,000',
          'code': 'ABC-######',
        };
      case 'GOLD':
        return {
          'color': const Color(0xFFfbbf24),
          'name': 'GOLD',
          'price': 1000,
          'prize': '500,000',
          'code': 'GOLD-#####',
        };
      case 'DIAMOND':
        return {
          'color': const Color(0xFF22d3ee),
          'name': 'DIAMOND',
          'price': 5000,
          'prize': '2,000,000',
          'code': 'DMD-#####',
        };
      default:
        return {
          'color': Colors.grey,
          'name': 'UNKNOWN',
          'price': 0,
          'prize': '0',
          'code': 'XXX-######',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _getTicketInfo();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: info['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  info['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Price', '${info['price']} HTG'),
            _buildInfoRow('Max Prize', '${info['prize']} HTG'),
            _buildInfoRow('Code Format', info['code']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
