import 'package:flutter/material.dart';

/// Ticket tier enumeration with all configuration data
enum TicketTier {
  basic(
    name: 'BASIC',
    price: 50,
    maxPrize: 5000,
    codePrefix: 'XYZ',
    codeDigits: 6,
    backgroundColor: Color(0xFF10b981),
    backgroundGradient: [Color(0xFF10b981), Color(0xFF059669)],
  ),
  premium(
    name: 'PREMIUM',
    price: 100,
    maxPrize: 10000,
    codePrefix: 'EFG',
    codeDigits: 6,
    backgroundColor: Color(0xFF7c3aed),
    backgroundGradient: [Color(0xFF7c3aed), Color(0xFF6d28d9)],
  ),
  bronze(
    name: 'BRONZE',
    price: 250,
    maxPrize: 25000,
    codePrefix: 'JKL',
    codeDigits: 6,
    backgroundColor: Color(0xFFea580c),
    backgroundGradient: [Color(0xFFea580c), Color(0xFFc2410c)],
  ),
  silver(
    name: 'SILVER',
    price: 500,
    maxPrize: 150000,
    codePrefix: 'ABC',
    codeDigits: 6,
    backgroundColor: Color(0xFFcbd5e1),
    backgroundGradient: [Color(0xFFcbd5e1), Color(0xFF94a3b8)],
  ),
  gold(
    name: 'GOLD',
    price: 1000,
    maxPrize: 500000,
    codePrefix: 'GOLD',
    codeDigits: 5,
    backgroundColor: Color(0xFFfbbf24),
    backgroundGradient: [Color(0xFFfbbf24), Color(0xFFf59e0b)],
  ),
  diamond(
    name: 'DIAMOND',
    price: 5000,
    maxPrize: 2000000,
    codePrefix: 'DMD',
    codeDigits: 5,
    backgroundColor: Color(0xFF22d3ee),
    backgroundGradient: [Color(0xFF22d3ee), Color(0xFF06b6d4)],
  );

  const TicketTier({
    required this.name,
    required this.price,
    required this.maxPrize,
    required this.codePrefix,
    required this.codeDigits,
    required this.backgroundColor,
    required this.backgroundGradient,
  });

  final String name;
  final int price;
  final int maxPrize;
  final String codePrefix;
  final int codeDigits;
  final Color backgroundColor;
  final List<Color> backgroundGradient;

  /// Generate a sample code format for display
  String get codeFormat => '$codePrefix-${'#' * codeDigits}';

  /// Format price with currency
  String get formattedPrice => '$price GOURDES';

  /// Format prize with currency
  String get formattedPrize => '${maxPrize.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} GOURDES!';
}

/// A Flutter widget that displays a raffle ticket design card
/// matching the Grate Genyen design system
class TicketDesignCard extends StatelessWidget {
  final TicketTier tier;
  final String? ticketCode;
  final bool showScratchArea;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const TicketDesignCard({
    super.key,
    required this.tier,
    this.ticketCode,
    this.showScratchArea = true,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 300.0;
    final cardHeight = height ?? 450.0;
    final aspectRatio = cardWidth / cardHeight;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: tier.backgroundGradient,
                    ),
                  ),
                ),
                
                // Sparkle overlay effect
                CustomPaint(
                  painter: SparklePainter(
                    color: Colors.white,
                    density: _getSparkleDensity(tier),
                  ),
                  size: Size(cardWidth, cardHeight),
                ),
                
                // Ticket content
                Column(
                  children: [
                    _buildTopBanner(),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLogo(),
                          _buildCategoryRibbon(),
                          if (showScratchArea) _buildScratchArea(),
                        ],
                      ),
                    ),
                    _buildBottomBanner(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top brown banner with "GRATE TOUT" and price
  Widget _buildTopBanner() {
    return Container(
      height: 60,
      color: const Color(0xFF8b4513),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'GRATE TOUT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFf8fafc),
            ),
          ),
          Text(
            tier.formattedPrice,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFf8fafc),
            ),
          ),
        ],
      ),
    );
  }

  /// Grate Genyen logo with yellow and blue text
  Widget _buildLogo() {
    return Column(
      children: [
        Text(
          'GRATE',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: tier == TicketTier.gold
                ? const Color(0xFF7c3aed)
                : const Color(0xFFfbbf24),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'GENYEN',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: tier == TicketTier.gold
                ? const Color(0xFF1e40af)
                : tier == TicketTier.diamond
                    ? Colors.white
                    : const Color(0xFF38bdf8),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Category ribbon badge with tier name
  Widget _buildCategoryRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: _getRibbonColor(),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        tier.name,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  /// White scratch area with code
  Widget _buildScratchArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFcbd5e1), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Scratch to Reveal',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ticketCode ?? tier.codeFormat,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94a3b8),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom brown banner with prize information
  Widget _buildBottomBanner() {
    return Container(
      height: 60,
      color: const Color(0xFF8b4513),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'GRATE & GENYEN JISKA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfbbf24),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tier.formattedPrize,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfbbf24),
            ),
          ),
        ],
      ),
    );
  }

  /// Get ribbon color based on tier
  Color _getRibbonColor() {
    switch (tier) {
      case TicketTier.silver:
        return const Color(0xFF94a3b8);
      case TicketTier.gold:
        return const Color(0xFFd97706);
      case TicketTier.diamond:
        return const Color(0xFF0891b2);
      default:
        return const Color(0xFF6b7280);
    }
  }

  /// Get sparkle density based on tier (higher tiers = more sparkles)
  double _getSparkleDensity(TicketTier tier) {
    switch (tier) {
      case TicketTier.basic:
        return 0.3;
      case TicketTier.premium:
        return 0.4;
      case TicketTier.bronze:
        return 0.5;
      case TicketTier.silver:
        return 0.7;
      case TicketTier.gold:
        return 0.8;
      case TicketTier.diamond:
        return 1.0;
    }
  }
}

/// Custom painter for sparkle effect overlay
class SparklePainter extends CustomPainter {
  final Color color;
  final double density;

  SparklePainter({
    required this.color,
    this.density = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = _SeededRandom(42); // Use seeded random for consistency
    final sparkleCount = (size.width * size.height * density / 500).toInt();

    for (int i = 0; i < sparkleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.6 + 0.2;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.density != density || oldDelegate.color != color;
  }
}

/// Simple seeded random number generator for consistent sparkle positions
class _SeededRandom {
  int _seed;

  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}

/// Example widget showing all ticket tiers in a grid
class TicketGalleryWidget extends StatelessWidget {
  const TicketGalleryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Design Gallery'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: TicketTier.values.length,
          itemBuilder: (context, index) {
            final tier = TicketTier.values[index];
            return TicketDesignCard(
              tier: tier,
              onTap: () {
                _showTicketDetails(context, tier);
              },
            );
          },
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, TicketTier tier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tier.name} Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ${tier.formattedPrice}'),
            const SizedBox(height: 8),
            Text('Max Prize: ${tier.formattedPrize}'),
            const SizedBox(height: 8),
            Text('Code Format: ${tier.codeFormat}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
