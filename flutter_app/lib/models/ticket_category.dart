import 'package:flutter/material.dart';

/// Enum representing all ticket categories with their specifications
enum TicketTier {
  basic,
  premium,
  bronze,
  silver,
  gold,
  diamond,
}

/// Extension to provide ticket specifications for each tier
extension TicketTierSpecs on TicketTier {
  String get name {
    switch (this) {
      case TicketTier.basic:
        return 'BASIC';
      case TicketTier.premium:
        return 'PREMIUM';
      case TicketTier.bronze:
        return 'BRONZE';
      case TicketTier.silver:
        return 'SILVER';
      case TicketTier.gold:
        return 'GOLD';
      case TicketTier.diamond:
        return 'DIAMOND';
    }
  }

  double get price {
    switch (this) {
      case TicketTier.basic:
        return 50.0;
      case TicketTier.premium:
        return 100.0;
      case TicketTier.bronze:
        return 250.0;
      case TicketTier.silver:
        return 500.0;
      case TicketTier.gold:
        return 1000.0;
      case TicketTier.diamond:
        return 5000.0;
    }
  }

  String get codePrefix {
    switch (this) {
      case TicketTier.basic:
        return 'XYZ';
      case TicketTier.premium:
        return 'EFG';
      case TicketTier.bronze:
        return 'JKL';
      case TicketTier.silver:
        return 'ABC';
      case TicketTier.gold:
        return 'GOLD';
      case TicketTier.diamond:
        return 'DMD';
    }
  }

  String get codeFormat {
    switch (this) {
      case TicketTier.basic:
      case TicketTier.premium:
      case TicketTier.bronze:
      case TicketTier.silver:
        return '$codePrefix-######';
      case TicketTier.gold:
      case TicketTier.diamond:
        return '$codePrefix-#####';
    }
  }

  double get maxPrize {
    switch (this) {
      case TicketTier.basic:
        return 5000.0;
      case TicketTier.premium:
        return 10000.0;
      case TicketTier.bronze:
        return 25000.0;
      case TicketTier.silver:
        return 150000.0;
      case TicketTier.gold:
        return 500000.0;
      case TicketTier.diamond:
        return 2000000.0;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TicketTier.basic:
        return const Color(0xFF10b981); // Green
      case TicketTier.premium:
        return const Color(0xFF7c3aed); // Purple
      case TicketTier.bronze:
        return const Color(0xFFea580c); // Orange
      case TicketTier.silver:
        return const Color(0xFFcbd5e1); // Silver
      case TicketTier.gold:
        return const Color(0xFFfbbf24); // Gold
      case TicketTier.diamond:
        return const Color(0xFF22d3ee); // Cyan
    }
  }

  Color get darkerShade {
    switch (this) {
      case TicketTier.basic:
        return const Color(0xFF059669);
      case TicketTier.premium:
        return const Color(0xFF6d28d9);
      case TicketTier.bronze:
        return const Color(0xFFc2410c);
      case TicketTier.silver:
        return const Color(0xFF94a3b8);
      case TicketTier.gold:
        return const Color(0xFFf59e0b);
      case TicketTier.diamond:
        return const Color(0xFF06b6d4);
    }
  }

  /// Get text color that contrasts well with the background
  Color get textColor {
    // Silver needs dark text, others can use white
    return this == TicketTier.silver ? Colors.black87 : Colors.white;
  }

  /// Get gradient colors for the ticket
  List<Color> get gradientColors {
    return [backgroundColor, darkerShade];
  }

  /// Generate a sample ticket number for this tier
  String generateSampleCode(int number) {
    if (this == TicketTier.gold || this == TicketTier.diamond) {
      return '$codePrefix-${number.toString().padLeft(5, '0')}';
    }
    return '$codePrefix-${number.toString().padLeft(6, '0')}';
  }

  /// Format the max prize for display
  String get formattedMaxPrize {
    if (maxPrize >= 1000000) {
      return '${(maxPrize / 1000000).toStringAsFixed(1)}M HTG';
    } else if (maxPrize >= 1000) {
      return '${(maxPrize / 1000).toStringAsFixed(0)}K HTG';
    }
    return '${maxPrize.toStringAsFixed(0)} HTG';
  }
}

class TicketCategory {
  final String categoryCode;
  final String categoryName;
  final double price;
  final String? color;
  final int onlineAvailable;
  final int onlineTotal;

  TicketCategory({
    required this.categoryCode,
    required this.categoryName,
    required this.price,
    this.color,
    required this.onlineAvailable,
    required this.onlineTotal,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      categoryCode: json['category_code'] as String,
      categoryName: json['category_name'] as String,
      price: (json['price'] as num).toDouble(),
      color: json['color'] as String?,
      onlineAvailable: json['online_available'] as int,
      onlineTotal: json['online_total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_code': categoryCode,
      'category_name': categoryName,
      'price': price,
      'color': color,
      'online_available': onlineAvailable,
      'online_total': onlineTotal,
    };
  }

  bool get isAvailable => onlineAvailable > 0;
  bool get isSoldOut => onlineAvailable == 0;
  
  double get availabilityPercentage => 
    onlineTotal > 0 ? (onlineAvailable / onlineTotal) * 100 : 0;

  /// Get the matching TicketTier for this category
  TicketTier? get tier {
    final upperName = categoryName.toUpperCase();
    try {
      return TicketTier.values.firstWhere(
        (tier) => tier.name == upperName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a TicketCategory from a TicketTier
  factory TicketCategory.fromTier(TicketTier tier, {
    required int onlineAvailable,
    required int onlineTotal,
  }) {
    return TicketCategory(
      categoryCode: tier.codePrefix,
      categoryName: tier.name,
      price: tier.price,
      color: '#${tier.backgroundColor.value.toRadixString(16).substring(2)}',
      onlineAvailable: onlineAvailable,
      onlineTotal: onlineTotal,
    );
  }
}
