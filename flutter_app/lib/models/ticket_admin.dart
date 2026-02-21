import 'package:raffle_app/models/ticket.dart';

class TicketAdmin extends Ticket {
  TicketAdmin({
    required super.id,
    required super.ticketNumber,
    // barcode is required by Ticket; use empty string as fallback when backend omits it
    required super.barcode,
    required super.category,
    // price is required by Ticket; use 0.0 as fallback when backend omits it
    required super.price,
    required super.status,
    super.sellerId,
    super.sellerName,
    super.buyerPhone,
    super.buyerName,
    super.department,
    required super.availableOnline,
    required super.createdAt,
    super.soldAt,
  });

  factory TicketAdmin.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] ?? json['createdAt'];
    if (createdAtStr == null) {
      throw ArgumentError('created_at or createdAt field is required');
    }
    return TicketAdmin(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? json['ticketNumber'] ?? '',
      // barcode: fallback to empty string if backend omits it
      barcode: json['barcode'] as String? ?? '',
      category: json['category'] ?? '',
      // price: fallback to 0.0 if backend omits it
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'AVAILABLE',
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
      buyerName: json['buyer_name'] as String?,
      department: json['department'] as String?,
      availableOnline: json['available_online'] == 1 || json['available_online'] == true,
      createdAt: DateTime.parse(createdAtStr as String),
      soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at'] as String) : null,
    );
  }
}

class BulkTicketOperation {
  final String operation; // create, update, delete, invalidate
  final List<String>? ticketNumbers;
  final Map<String, dynamic>? updateData;
  final int? count; // for bulk create
  final String? category; // for bulk create

  BulkTicketOperation({
    required this.operation,
    this.ticketNumbers,
    this.updateData,
    this.count,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      if (ticketNumbers != null) 'ticket_numbers': ticketNumbers,
      if (updateData != null) 'update_data': updateData,
      if (count != null) 'count': count,
      if (category != null) 'category': category,
    };
  }
}
