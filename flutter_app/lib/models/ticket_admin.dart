import 'package:raffle_app/models/ticket.dart';

class TicketAdmin extends Ticket {
  TicketAdmin({
    required super.id,
    required super.ticketNumber,
    // barcode is required and non-nullable, matching Ticket.barcode
    required super.barcode,
    required super.category,
    // price is required and non-nullable, matching Ticket.price
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
    return TicketAdmin(
      id: json['id'] as int? ?? 0,
      ticketNumber: json['ticket_number'] ?? json['ticketNumber'] ?? '',
      // Fall back to empty string if barcode is absent from backend response
      barcode: json['barcode'] as String? ?? '',
      category: json['category'] as String? ?? '',
      // Fall back to 0.0 if price is absent from backend response
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      status: json['status'] as String? ?? 'available',
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
      buyerName: json['buyer_name'] as String?,
      department: json['department'] as String?,
      availableOnline: json['available_online'] == 1 || json['available_online'] == true,
      // Fallback to current time when created_at is absent from the backend response.
      // Admin endpoints should always include this field; if missing it signals a data
      // integrity issue that callers should investigate.
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at']) : null,
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
