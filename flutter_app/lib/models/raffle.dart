class Raffle {
  final int id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime drawDate;
  final String status;
  final int? totalTickets;
  final DateTime createdAt;

  Raffle({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.drawDate,
    required this.status,
    this.totalTickets,
    required this.createdAt,
  });

  factory Raffle.fromJson(Map<String, dynamic> json) {
    return Raffle(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] ?? json['startDate']),
      drawDate: DateTime.parse(json['draw_date'] ?? json['drawDate']),
      status: json['status'] as String,
      totalTickets: json['total_tickets'] as int?,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'draw_date': drawDate.toIso8601String(),
      'status': status,
      'total_tickets': totalTickets,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
}
