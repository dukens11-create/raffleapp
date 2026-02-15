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

  Map<String, dynamic> toJson() {
    return {
      'gradientColors': gradientColors.map((c) => '#${c.value.toRadixString(16).substring(2)}').toList(),
      'textColor': '#${textColor.value.toRadixString(16).substring(2)}',
      'animation': animation,
    };
  }
}
