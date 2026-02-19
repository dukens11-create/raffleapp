class CachedUser {
  final int id;
  final String phone;
  final String name;
  final String? email;
  final String role;
  final String? department;
  final bool synced;

  CachedUser({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.role,
    this.department,
    this.synced = false,
  });

  factory CachedUser.fromMap(Map<String, dynamic> map) {
    return CachedUser(
      id: map['id'] as int,
      phone: map['phone'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      role: map['role'] as String,
      department: map['department'] as String?,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'synced': synced ? 1 : 0,
    };
  }

  factory CachedUser.fromJson(Map<String, dynamic> json) {
    return CachedUser(
      id: json['id'] as int,
      phone: json['phone'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      department: json['department'] as String?,
      synced: json['synced'] == true || json['synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'synced': synced,
    };
  }

  CachedUser copyWith({
    int? id,
    String? phone,
    String? name,
    String? email,
    String? role,
    String? department,
    bool? synced,
  }) {
    return CachedUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() {
    return 'CachedUser(id: $id, phone: $phone, name: $name, role: $role, synced: $synced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Convenience getters
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isSeller => role.toLowerCase() == 'seller';
  bool get isBuyer => role.toLowerCase() == 'buyer';
}
