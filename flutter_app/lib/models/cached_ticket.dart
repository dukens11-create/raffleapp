class CachedTicket {
  final int id;
  final String barcode;
  final String category;
  final double price;
  final String status;
  final int? buyerId;
  final int? sellerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  CachedTicket({
    required this.id,
    required this.barcode,
    required this.category,
    required this.price,
    required this.status,
    this.buyerId,
    this.sellerId,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  factory CachedTicket.fromMap(Map<String, dynamic> map) {
    return CachedTicket(
      id: map['id'] as int,
      barcode: map['barcode'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      status: map['status'] as String,
      buyerId: map['buyer_id'] as int?,
      sellerId: map['seller_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'category': category,
      'price': price,
      'status': status,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory CachedTicket.fromJson(Map<String, dynamic> json) {
    return CachedTicket(
      id: json['id'] as int,
      barcode: json['barcode'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      buyerId: json['buyer_id'] as int?,
      sellerId: json['seller_id'] as int?,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      synced: json['synced'] == true || json['synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'category': category,
      'price': price,
      'status': status,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced,
    };
  }

  CachedTicket copyWith({
    int? id,
    String? barcode,
    String? category,
    double? price,
    String? status,
    int? buyerId,
    int? sellerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return CachedTicket(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      price: price ?? this.price,
      status: status ?? this.status,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() {
    return 'CachedTicket(id: $id, barcode: $barcode, category: $category, '
        'price: $price, status: $status, synced: $synced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedTicket && other.id == id && other.barcode == barcode;
  }

  @override
  int get hashCode => id.hashCode ^ barcode.hashCode;
}
