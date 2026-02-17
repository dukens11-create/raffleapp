class Buyer {
  final int id;
  final String phone;
  final String name;
  final String? email;
  final String? department;
  final int ticketCount;
  final DateTime createdAt;

  Buyer({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.department,
    required this.ticketCount,
    required this.createdAt,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['id'] as int,
      phone: json['phone'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      department: json['department'] as String?,
      ticketCount: json['ticket_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'department': department,
      'ticket_count': ticketCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
