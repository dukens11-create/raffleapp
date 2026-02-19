import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Represents a buyer's scratch ticket as returned by the backend (without prize
/// details until the ticket is scratched).
class BuyerScratchTicket {
  final int id;
  final String? paymentReference;
  final String? buyerName;
  final String ticketType;
  final String? category;
  final bool isScratched;
  final DateTime? scratchedAt;
  final bool claimed;
  final DateTime? createdAt;

  // Prize fields — only populated after scratching
  final String? prizeEmoji;
  final String? prizeText;
  final int? prizeValue;
  final bool? hasPrize;

  const BuyerScratchTicket({
    required this.id,
    this.paymentReference,
    this.buyerName,
    required this.ticketType,
    this.category,
    required this.isScratched,
    this.scratchedAt,
    required this.claimed,
    this.createdAt,
    this.prizeEmoji,
    this.prizeText,
    this.prizeValue,
    this.hasPrize,
  });

  factory BuyerScratchTicket.fromJson(Map<String, dynamic> json) {
    return BuyerScratchTicket(
      id: json['id'] as int,
      paymentReference: json['payment_reference'] as String?,
      buyerName: json['buyer_name'] as String?,
      ticketType: (json['ticket_type'] as String?) ?? '',
      category: json['category'] as String?,
      isScratched: _parseBool(json['is_scratched']),
      scratchedAt: json['scratched_at'] != null
          ? DateTime.tryParse(json['scratched_at'] as String)
          : null,
      claimed: _parseBool(json['claimed']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      prizeEmoji: json['prize_emoji'] as String?,
      prizeText: json['prize_text'] as String?,
      prizeValue: json['prize_value'] as int?,
      hasPrize: json['has_prize'] != null ? _parseBool(json['has_prize']) : null,
    );
  }

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }

  /// Returns a copy with prize fields populated after scratching.
  BuyerScratchTicket withPrize({
    required String prizeEmoji,
    required String prizeText,
    required int prizeValue,
    required bool hasPrize,
  }) {
    return BuyerScratchTicket(
      id: id,
      paymentReference: paymentReference,
      buyerName: buyerName,
      ticketType: ticketType,
      category: category,
      isScratched: true,
      scratchedAt: scratchedAt ?? DateTime.now(),
      claimed: claimed,
      createdAt: createdAt,
      prizeEmoji: prizeEmoji,
      prizeText: prizeText,
      prizeValue: prizeValue,
      hasPrize: hasPrize,
    );
  }
}

/// Result returned after calling the scratch API.
class ScratchResult {
  final bool success;
  final bool alreadyScratched;
  final String prizeEmoji;
  final String prizeText;
  final int prizeValue;
  final bool hasPrize;

  const ScratchResult({
    required this.success,
    required this.alreadyScratched,
    required this.prizeEmoji,
    required this.prizeText,
    required this.prizeValue,
    required this.hasPrize,
  });

  factory ScratchResult.fromJson(Map<String, dynamic> json) {
    return ScratchResult(
      success: (json['success'] as bool?) ?? false,
      alreadyScratched: (json['already_scratched'] as bool?) ?? false,
      prizeEmoji: (json['prize_emoji'] as String?) ?? '😅',
      prizeText: (json['prize_text'] as String?) ?? 'ESEYE ANKÒ',
      prizeValue: (json['prize_value'] as int?) ?? 0,
      hasPrize: BuyerScratchTicket._parseBool(json['has_prize']),
    );
  }
}

/// Service for interacting with the buyer scratch ticket backend endpoints.
class BuyerScratchService {
  final String baseUrl = ApiConfig.baseUrl;
  final Duration _timeout = const Duration(seconds: 10);

  String _handleError(dynamic error, String endpoint) {
    if (error is SocketException) {
      return 'Cannot connect to server. Please check your internet connection.';
    }
    final s = error.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Cannot connect to server. Please check your internet connection.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'Connection timeout. Please try again.';
    }
    return 'Error connecting to $baseUrl$endpoint: $s';
  }

  /// Fetch all scratch tickets belonging to [phone].
  Future<List<BuyerScratchTicket>> getMyTickets(String phone) async {
    const endpoint = '/api/public/buyer-scratch-tickets/lookup';
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['tickets'] as List<dynamic>? ?? [];
        return list
            .map((e) => BuyerScratchTicket.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Failed to fetch scratch tickets');
      }
    } catch (e) {
      debugPrint('❌ BuyerScratchService.getMyTickets: $e');
      throw Exception(_handleError(e, endpoint));
    }
  }

  /// Mark ticket [id] as scratched and return the prize.
  /// This is idempotent — calling it again returns the same prize.
  Future<ScratchResult> scratchTicket(int id, String phone) async {
    final endpoint = '/api/public/buyer-scratch-ticket/$id/scratch';
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ScratchResult.fromJson(data);
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Failed to scratch ticket');
      }
    } catch (e) {
      debugPrint('❌ BuyerScratchService.scratchTicket: $e');
      throw Exception(_handleError(e, endpoint));
    }
  }
}
