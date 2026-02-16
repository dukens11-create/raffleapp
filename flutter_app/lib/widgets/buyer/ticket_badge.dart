import 'package:flutter/material.dart';

class TicketBadge extends StatelessWidget {
  final String type;

  const TicketBadge({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getTicketConfig(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  _TicketConfig _getTicketConfig(String type) {
    switch (type.toUpperCase()) {
      case 'BASIC':
        return _TicketConfig(
          gradientColors: [const Color(0xFF10b981), const Color(0xFF059669)],
          textColor: Colors.white,
        );
      case 'PREMIUM':
        return _TicketConfig(
          gradientColors: [const Color(0xFF7c3aed), const Color(0xFF6366f1)],
          textColor: Colors.white,
        );
      case 'BRONZE':
        return _TicketConfig(
          gradientColors: [const Color(0xFFea580c), const Color(0xFFdc2626)],
          textColor: Colors.white,
        );
      case 'SILVER':
        return _TicketConfig(
          gradientColors: [const Color(0xFFcbd5e1), const Color(0xFF94a3b8)],
          textColor: const Color(0xFF1e293b),
        );
      case 'GOLD':
        return _TicketConfig(
          gradientColors: [const Color(0xFFfbbf24), const Color(0xFFf59e0b)],
          textColor: const Color(0xFF78350f),
        );
      case 'DIAMOND':
        return _TicketConfig(
          gradientColors: [const Color(0xFF22d3ee), const Color(0xFF06b6d4)],
          textColor: Colors.white,
        );
      default:
        return _TicketConfig(
          gradientColors: [Colors.grey, Colors.grey[700]!],
          textColor: Colors.white,
        );
    }
  }
}

class _TicketConfig {
  final List<Color> gradientColors;
  final Color textColor;

  _TicketConfig({
    required this.gradientColors,
    required this.textColor,
  });
}
