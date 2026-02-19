import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Model representing a buyer's scratch ticket entry.
class BuyerScratchTicket {
  final int id;
  final String? paymentReference;
  final String? buyerName;
  final String ticketType;
  final String category;
  final bool isScratched;
  final DateTime? scratchedAt;
  final bool claimed;
  final DateTime? createdAt;
  // Prize fields - only populated after scratching
  final bool? hasPrize;
  final String? prizeEmoji;
  final String? prizeText;
  final int? prizeValue;

  BuyerScratchTicket({
    required this.id,
    this.paymentReference,
    this.buyerName,
    required this.ticketType,
    required this.category,
    required this.isScratched,
    this.scratchedAt,
    required this.claimed,
    this.createdAt,
    this.hasPrize,
    this.prizeEmoji,
    this.prizeText,
    this.prizeValue,
  });

  factory BuyerScratchTicket.fromJson(Map<String, dynamic> json) {
    return BuyerScratchTicket(
      id: json['id'] as int,
      paymentReference: json['payment_reference'] as String?,
      buyerName: json['buyer_name'] as String?,
      ticketType: json['ticket_type'] as String? ?? 'basic',
      category: json['category'] as String? ?? '',
      isScratched: json['is_scratched'] == true || json['is_scratched'] == 1,
      scratchedAt: json['scratched_at'] != null
          ? DateTime.tryParse(json['scratched_at'] as String)
          : null,
      claimed: json['claimed'] == true || json['claimed'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      hasPrize: json['has_prize'] != null
          ? (json['has_prize'] == true || json['has_prize'] == 1)
          : null,
      prizeEmoji: json['prize_emoji'] as String?,
      prizeText: json['prize_text'] as String?,
      prizeValue: json['prize_value'] as int?,
    );
  }
}

/// Result returned after marking a scratch ticket as scratched.
class ScratchResult {
  final bool success;
  final bool alreadyScratched;
  final String prizeEmoji;
  final String prizeText;
  final int prizeValue;
  final bool hasPrize;

  ScratchResult({
    required this.success,
    required this.alreadyScratched,
    required this.prizeEmoji,
    required this.prizeText,
    required this.prizeValue,
    required this.hasPrize,
  });

  factory ScratchResult.fromJson(Map<String, dynamic> json) {
    return ScratchResult(
      success: json['success'] == true,
      alreadyScratched: json['already_scratched'] == true,
      prizeEmoji: json['prize_emoji'] as String? ?? '😅',
      prizeText: json['prize_text'] as String? ?? 'ESEYE ANKÒ',
      prizeValue: json['prize_value'] as int? ?? 0,
      hasPrize: json['has_prize'] == true,
    );
  }
}

/// Service for interacting with the buyer scratch ticket backend APIs.
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
    return 'Error: $s (Endpoint: $endpoint)';
  }

  /// Fetch all scratch tickets for a buyer identified by [phone].
  Future<List<BuyerScratchTicket>> getMyScratchTickets(String phone) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    final endpoint = '/api/buyer/scratch-tickets';
    try {
      final url = '$baseUrl$endpoint?phone=${Uri.encodeQueryComponent(normalizedPhone)}';
      debugPrint('🔍 Fetching buyer scratch tickets: $url');
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = (data['tickets'] as List? ?? [])
            .map((e) => BuyerScratchTicket.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('✅ Loaded ${list.length} scratch tickets');
        return list;
      } else {
        throw Exception('Failed to load scratch tickets: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching scratch tickets: $e');
      throw Exception(_handleError(e, endpoint));
    }
  }

  /// Reveal the prize for scratch ticket [id], verified by [phone].
  /// Returns [ScratchResult] containing the prize data.
  Future<ScratchResult> markScratched(int id, String phone) async {
    final endpoint = '/api/buyer/scratch-ticket/$id/scratch';
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('🎰 Marking scratch ticket $id as scratched');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone': phone}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ScratchResult.fromJson(data);
      } else {
        final body = json.decode(response.body) as Map<String, dynamic>? ?? {};
        throw Exception(body['error'] ?? 'Failed to scratch ticket: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error scratching ticket: $e');
      throw Exception(_handleError(e, endpoint));
    }
  }
}
