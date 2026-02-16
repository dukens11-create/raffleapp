import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w600,
          fontSize: small ? 11 : 12,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return _StatusConfig(
          label: 'Available',
          backgroundColor: const Color(0xFF10b981).withOpacity(0.15),
          textColor: const Color(0xFF059669),
        );
      case 'sold':
        return _StatusConfig(
          label: 'Sold',
          backgroundColor: const Color(0xFFef4444).withOpacity(0.15),
          textColor: const Color(0xFFdc2626),
        );
      case 'pending':
        return _StatusConfig(
          label: 'Pending',
          backgroundColor: const Color(0xFFf59e0b).withOpacity(0.15),
          textColor: const Color(0xFFd97706),
        );
      case 'verified':
        return _StatusConfig(
          label: 'Verified',
          backgroundColor: const Color(0xFF3b82f6).withOpacity(0.15),
          textColor: const Color(0xFF2563eb),
        );
      default:
        return _StatusConfig(
          label: status,
          backgroundColor: Colors.grey.withOpacity(0.15),
          textColor: Colors.grey[700]!,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
