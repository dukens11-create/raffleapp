import 'package:raffle_app/models/ticket.dart';

class TicketAdmin extends Ticket {
  final String? sellerName;
  final String? buyerName;
  final String? buyerPhone;
  final String? department;
  final DateTime? soldAt;
  final double? price;

  TicketAdmin({
    required super.id,
    required super.ticketNumber,
    required super.category,
    required super.status,
    super.qrCode,
    super.barcode,
    this.sellerName,
    this.buyerName,
    this.buyerPhone,
    this.department,
    this.soldAt,
    this.price,
  });

  factory TicketAdmin.fromJson(Map<String, dynamic> json) {
    return TicketAdmin(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'available',
      qrCode: json['qr_code'],
      barcode: json['barcode'],
      sellerName: json['seller_name'],
      buyerName: json['buyer_name'],
      buyerPhone: json['buyer_phone'],
      department: json['department'],
      soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at']) : null,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data.addAll({
      'seller_name': sellerName,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'department': department,
      'sold_at': soldAt?.toIso8601String(),
      'price': price,
    });
    return data;
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
