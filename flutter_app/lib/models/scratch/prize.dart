import 'package:flutter/material.dart';

class Prize {
  static const String freeTicketEmoji = '🎟️';
  
  final String emoji;
  final String text;
  final int value;
  final int weight;

  Prize({
    required this.emoji,
    required this.text,
    required this.value,
    required this.weight,
  });

  bool get isFreeTicket => emoji == freeTicketEmoji;

  factory Prize.fromJson(Map<String, dynamic> json) {
    return Prize(
      emoji: json['emoji'] as String,
      text: json['text'] as String,
      value: json['value'] as int,
      weight: json['weight'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'text': text,
      'value': value,
      'weight': weight,
    };
  }
}
