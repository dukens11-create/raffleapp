class Winner {
  final int id;
  final int raffleId;
  final String ticketNumber;
  final String? buyerName;
  final String? buyerPhone;
  final String prize;
  final DateTime drawnAt;
  final bool notified;
  final bool prizeClaimed;
  final DateTime? claimedAt;

  Winner({
    required this.id,
    required this.raffleId,
    required this.ticketNumber,
    this.buyerName,
    this.buyerPhone,
    required this.prize,
    required this.drawnAt,
    this.notified = false,
    this.prizeClaimed = false,
    this.claimedAt,
  });

  factory Winner.fromJson(Map<String, dynamic> json) {
    return Winner(
      id: json['id'] ?? 0,
      raffleId: json['raffle_id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      buyerName: json['buyer_name'],
      buyerPhone: json['buyer_phone'],
      prize: json['prize'] ?? '',
      drawnAt: DateTime.parse(json['drawn_at'] ?? DateTime.now().toIso8601String()),
      notified: json['notified'] ?? false,
      prizeClaimed: json['prize_claimed'] ?? false,
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raffle_id': raffleId,
      'ticket_number': ticketNumber,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'prize': prize,
      'drawn_at': drawnAt.toIso8601String(),
      'notified': notified,
      'prize_claimed': prizeClaimed,
      'claimed_at': claimedAt?.toIso8601String(),
    };
  }
}
