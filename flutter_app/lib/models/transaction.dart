class Transaction {
  final int id;
  final String transactionId;
  final String paymentMethod;
  final double amount;
  final String status;
  final String buyerPhone;
  final String buyerName;
  final String? buyerEmail;
  final String? department;
  final int quantity;
  final String? ticketNumbers;
  final String paymentReference;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  Transaction({
    required this.id,
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.buyerPhone,
    required this.buyerName,
    this.buyerEmail,
    this.department,
    required this.quantity,
    this.ticketNumbers,
    required this.paymentReference,
    required this.createdAt,
    this.verifiedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      transactionId: json['transaction_id'] as String,
      paymentMethod: json['payment_method'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      buyerPhone: json['buyer_phone'] as String,
      buyerName: json['buyer_name'] as String,
      buyerEmail: json['buyer_email'] as String?,
      department: json['department'] as String?,
      quantity: json['quantity'] as int,
      ticketNumbers: json['ticket_numbers'] as String?,
      paymentReference: json['payment_reference'] as String,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'amount': amount,
      'status': status,
      'buyer_phone': buyerPhone,
      'buyer_name': buyerName,
      'buyer_email': buyerEmail,
      'department': department,
      'quantity': quantity,
      'ticket_numbers': ticketNumbers,
      'payment_reference': paymentReference,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isFailed => status == 'failed';
  bool get isMonCash => paymentMethod == 'moncash';
  bool get isNatCash => paymentMethod == 'natcash';

  List<String> get ticketNumbersList {
    if (ticketNumbers == null || ticketNumbers!.isEmpty) return [];
    return ticketNumbers!.split(',').map((t) => t.trim()).toList();
  }
}
