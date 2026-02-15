class User {
  final int id;
  final String phone;
  final String role;
  final String? name;
  final String? email;
  final String? department;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.role,
    this.name,
    this.email,
    this.department,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phone: json['phone'] as String,
      role: json['role'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      department: json['department'] as String?,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'role': role,
      'name': name,
      'email': email,
      'department': department,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
