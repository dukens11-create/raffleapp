class Draw {
  final int id;
  final String category;
  final String winningTicket;
  final String? winnerName;
  final String? winnerPhone;
  final int? sellerId;
  final String? sellerName;
  final DateTime drawDate;
  final String? photoPath;
  final bool verified;

  Draw({
    required this.id,
    required this.category,
    required this.winningTicket,
    this.winnerName,
    this.winnerPhone,
    this.sellerId,
    this.sellerName,
    required this.drawDate,
    this.photoPath,
    required this.verified,
  });

  factory Draw.fromJson(Map<String, dynamic> json) {
    return Draw(
      id: json['id'] as int,
      category: json['category'] as String,
      winningTicket: json['winning_ticket'] ?? json['winningTicket'],
      winnerName: json['winner_name'] as String?,
      winnerPhone: json['winner_phone'] as String?,
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      drawDate: DateTime.parse(json['draw_date'] ?? json['drawDate']),
      photoPath: json['photo_path'] as String?,
      verified: json['verified'] == 1 || json['verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'winning_ticket': winningTicket,
      'winner_name': winnerName,
      'winner_phone': winnerPhone,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'draw_date': drawDate.toIso8601String(),
      'photo_path': photoPath,
      'verified': verified,
    };
  }
}
