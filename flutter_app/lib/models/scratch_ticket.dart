class ScratchTicket {
  final int id;
  final String paymentReference;
  final String buyerPhone;
  final String buyerName;
  final String category;
  final double prizeAmount;
  final bool hasPrize;
  final String prizeMessage;
  final bool isScratched;
  final bool claimed;
  final DateTime? scratchedAt;
  final DateTime? claimedAt;
  final DateTime? createdAt;

  ScratchTicket({
    required this.id,
    required this.paymentReference,
    required this.buyerPhone,
    required this.buyerName,
    required this.category,
    required this.prizeAmount,
    required this.hasPrize,
    required this.prizeMessage,
    required this.isScratched,
    required this.claimed,
    this.scratchedAt,
    this.claimedAt,
    this.createdAt,
  });

  factory ScratchTicket.fromJson(Map<String, dynamic> json) {
    return ScratchTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      paymentReference: json['payment_reference'] as String? ?? '',
      buyerPhone: json['buyer_phone'] as String? ?? '',
      buyerName: json['buyer_name'] as String? ?? '',
      category: (json['category'] as String? ?? '').replaceAll('SCRATCH-', ''),
      prizeAmount: (json['prize_amount'] as num?)?.toDouble() ?? 0.0,
      hasPrize: json['has_prize'] == true || json['has_prize'] == 1,
      prizeMessage: json['prize_message'] as String? ?? '',
      isScratched: json['is_scratched'] == true || json['is_scratched'] == 1,
      claimed: json['claimed'] == true || json['claimed'] == 1,
      scratchedAt: json['scratched_at'] != null
          ? DateTime.tryParse(json['scratched_at'] as String)
          : null,
      claimedAt: json['claimed_at'] != null
          ? DateTime.tryParse(json['claimed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_reference': paymentReference,
      'buyer_phone': buyerPhone,
      'buyer_name': buyerName,
      'category': category,
      'prize_amount': prizeAmount,
      'has_prize': hasPrize,
      'prize_message': prizeMessage,
      'is_scratched': isScratched,
      'claimed': claimed,
      'scratched_at': scratchedAt?.toIso8601String(),
      'claimed_at': claimedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayCategory => category.isEmpty ? 'Unknown' : category;

  String get shortRef => paymentReference.length > 16
      ? paymentReference.substring(paymentReference.length - 16)
      : paymentReference;
}
