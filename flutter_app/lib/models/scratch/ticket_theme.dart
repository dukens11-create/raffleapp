import 'package:flutter/material.dart';

class TicketTheme {
  final List<Color> gradientColors;
  final Color textColor;
  final String animation;

  TicketTheme({
    required this.gradientColors,
    required this.textColor,
    required this.animation,
  });

  factory TicketTheme.fromJson(Map<String, dynamic> json) {
    return TicketTheme(
      gradientColors: (json['gradientColors'] as List)
          .map((c) => _parseColor(c as String))
          .toList(),
      textColor: _parseColor(json['textColor'] as String),
      animation: json['animation'] as String,
    );
  }

  static Color _parseColor(String colorStr) {
    return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
  }

  static String _colorToHex(Color color) {
    // Convert color to hex string with proper formatting
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    // All ticket theme colors are opaque (alpha = FF), so we return RGB only
    // Format: AARRGGBB -> RRGGBB (skip first 2 characters which are alpha)
    return '#${hex.substring(2)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'gradientColors': gradientColors.map((c) => _colorToHex(c)).toList(),
      'textColor': _colorToHex(textColor),
      'animation': animation,
    };
  }
}
