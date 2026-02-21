/// Test-only user model used by test fixtures.
class User {
  final String id;
  final String username;
  final String? email;
  final String role;
  final String? fullName;
  final String? phoneNumber;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.fullName,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone_number': phoneNumber,
    };
  }
}
