class Ticket {
  final int id;
  final String ticketNumber;
  final String barcode;
  final String category;
  final double price;
  final String status;
  final int? sellerId;
  final String? sellerName;
  final String? buyerPhone;
  final String? buyerName;
  final String? department;
  final bool availableOnline;
  final DateTime createdAt;
  final DateTime? soldAt;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.barcode,
    required this.category,
    required this.price,
    required this.status,
    this.sellerId,
    this.sellerName,
    this.buyerPhone,
    this.buyerName,
    this.department,
    required this.availableOnline,
    required this.createdAt,
    this.soldAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] ?? json['createdAt'];
    if (createdAtStr == null) {
      throw ArgumentError('created_at or createdAt field is required');
    }
    
    return Ticket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number'] ?? json['ticketNumber'],
      barcode: json['barcode'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
      buyerName: json['buyer_name'] as String?,
      department: json['department'] as String?,
      availableOnline: json['available_online'] == 1 || json['available_online'] == true,
      createdAt: DateTime.parse(createdAtStr),
      soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'barcode': barcode,
      'category': category,
      'price': price,
      'status': status,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'buyer_phone': buyerPhone,
      'buyer_name': buyerName,
      'department': department,
      'available_online': availableOnline,
      'created_at': createdAt.toIso8601String(),
      'sold_at': soldAt?.toIso8601String(),
    };
  }

  bool get isSold => status == 'SOLD';
  bool get isAvailable => status == 'AVAILABLE';
}
