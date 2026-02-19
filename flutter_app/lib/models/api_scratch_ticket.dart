/// Model representing a purchased scratch ticket retrieved from the API.
/// This is distinct from the local demo [ScratchTicket] in models/scratch/.
class ApiScratchTicket {
  final String paymentReference;
  final String ticketCategory;
  final String buyerName;
  final String paymentStatus;
  final String? createdAt;

  // Scratch-ticket specific fields (null when not yet generated / ticket not approved)
  final int? scratchTicketId;
  final bool hasPrize;
  final double prizeAmount;
  final String prizeMessage;
  final bool isScratched;
  final String? scratchedAt;
  final bool claimed;

  const ApiScratchTicket({
    required this.paymentReference,
    required this.ticketCategory,
    required this.buyerName,
    required this.paymentStatus,
    this.createdAt,
    this.scratchTicketId,
    this.hasPrize = false,
    this.prizeAmount = 0,
    this.prizeMessage = '',
    this.isScratched = false,
    this.scratchedAt,
    this.claimed = false,
  });

  bool get isApproved => paymentStatus == 'approved';

  factory ApiScratchTicket.fromJson(Map<String, dynamic> json) {
    return ApiScratchTicket(
      paymentReference: json['payment_reference'] as String? ?? '',
      ticketCategory: json['ticket_category'] as String? ?? '',
      buyerName: json['buyer_name'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
      scratchTicketId: json['scratch_ticket_id'] as int?,
      hasPrize: _parseBool(json['has_prize']),
      prizeAmount: (json['prize_amount'] ?? 0.0) is int
          ? (json['prize_amount'] as int).toDouble()
          : (json['prize_amount'] ?? 0.0) as double,
      prizeMessage: json['prize_message'] as String? ?? '',
      isScratched: _parseBool(json['is_scratched']),
      scratchedAt: json['scratched_at'] as String?,
      claimed: _parseBool(json['claimed']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    return false;
  }

  ApiScratchTicket copyWith({
    bool? hasPrize,
    double? prizeAmount,
    String? prizeMessage,
    bool? isScratched,
    String? scratchedAt,
    bool? claimed,
    int? scratchTicketId,
  }) {
    return ApiScratchTicket(
      paymentReference: paymentReference,
      ticketCategory: ticketCategory,
      buyerName: buyerName,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
      scratchTicketId: scratchTicketId ?? this.scratchTicketId,
      hasPrize: hasPrize ?? this.hasPrize,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      prizeMessage: prizeMessage ?? this.prizeMessage,
      isScratched: isScratched ?? this.isScratched,
      scratchedAt: scratchedAt ?? this.scratchedAt,
      claimed: claimed ?? this.claimed,
    );
  }
}
