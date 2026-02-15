import 'package:flutter/material.dart';
import 'prize.dart';
import 'ticket_theme.dart';

class ScratchTicket {
  final String id;
  final String name;
  final String typeName;
  final String className;
  final int price;
  final String prizeRange;
  final String? subText;
  final String coverText;
  final String category;
  final List<Prize> prizes;
  final TicketTheme theme;

  ScratchTicket({
    required this.id,
    required this.name,
    required this.typeName,
    required this.className,
    required this.price,
    required this.prizeRange,
    this.subText,
    required this.coverText,
    required this.category,
    required this.prizes,
    required this.theme,
  });

  factory ScratchTicket.fromJson(Map<String, dynamic> json) {
    return ScratchTicket(
      id: json['id'] as String,
      name: json['name'] as String,
      typeName: json['typeName'] as String,
      className: json['className'] as String,
      price: json['price'] as int,
      prizeRange: json['prizeRange'] as String,
      subText: json['subText'] as String?,
      coverText: json['coverText'] as String,
      category: json['category'] as String,
      prizes: (json['prizes'] as List)
          .map((p) => Prize.fromJson(p as Map<String, dynamic>))
          .toList(),
      theme: TicketTheme.fromJson(json['theme'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'typeName': typeName,
      'className': className,
      'price': price,
      'prizeRange': prizeRange,
      'subText': subText,
      'coverText': coverText,
      'category': category,
      'prizes': prizes.map((p) => p.toJson()).toList(),
      'theme': theme.toJson(),
    };
  }

  // Select a prize based on weighted probability
  Prize selectPrize() {
    final totalWeight = prizes.fold<int>(0, (sum, prize) => sum + prize.weight);
    final random = (DateTime.now().millisecondsSinceEpoch % totalWeight);
    
    int currentWeight = 0;
    for (final prize in prizes) {
      currentWeight += prize.weight;
      if (random < currentWeight) {
        return prize;
      }
    }
    
    return prizes.last; // Fallback
  }
}
