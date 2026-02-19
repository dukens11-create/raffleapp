/// Payment model for ticket purchase transactions
class Payment {
  final String? id;
  final String paymentReference;
  final String paymentMethod;
  final String paymentStatus;
  final String buyerName;
  final String buyerPhone;
  final String? buyerEmail;
  final String? department;
  final String ticketCategory;
  final int ticketQuantity;
  final double amount;
  final String? transactionId;
  final List<String>? ticketsAllocated;
  final String? paymentToken;
  final String? redirectUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Payment({
    this.id,
    required this.paymentReference,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerEmail,
    this.department,
    required this.ticketCategory,
    required this.ticketQuantity,
    required this.amount,
    this.transactionId,
    this.ticketsAllocated,
    this.paymentToken,
    this.redirectUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString(),
      paymentReference: json['payment_reference'] ?? json['paymentReference'] ?? '',
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? '',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'pending',
      buyerName: json['buyer_name'] ?? json['buyerName'] ?? '',
      buyerPhone: json['buyer_phone'] ?? json['buyerPhone'] ?? '',
      buyerEmail: json['buyer_email'] ?? json['buyerEmail'],
      department: json['department'] ?? json['customer_department'],
      ticketCategory: json['ticket_category'] ?? json['ticketCategory'] ?? json['category'] ?? '',
      ticketQuantity: json['ticket_quantity'] ?? json['ticketQuantity'] ?? json['quantity'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: json['transaction_id'] ?? json['transactionId'],
      ticketsAllocated: json['tickets_allocated'] != null
          ? List<String>.from(json['tickets_allocated'])
          : (json['ticketsAllocated'] != null
              ? List<String>.from(json['ticketsAllocated'])
              : null),
      paymentToken: json['payment_token'] ?? json['paymentToken'],
      redirectUrl: json['redirect_url'] ?? json['redirectUrl'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_reference': paymentReference,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_email': buyerEmail,
      'department': department,
      'ticket_category': ticketCategory,
      'ticket_quantity': ticketQuantity,
      'amount': amount,
      'transaction_id': transactionId,
      'tickets_allocated': ticketsAllocated,
      'payment_token': paymentToken,
      'redirect_url': redirectUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isPending => paymentStatus == 'pending';
  bool get isApproved => paymentStatus == 'approved' || paymentStatus == 'completed';
  bool get isRejected => paymentStatus == 'rejected' || paymentStatus == 'failed';
  
  String get statusDisplay {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
      case 'completed':
        return 'Approved';
      case 'rejected':
      case 'failed':
        return 'Rejected';
      default:
        return paymentStatus;
    }
  }
}

/// Payment initiation response from API
class PaymentInitiationResponse {
  final bool success;
  final String paymentReference;
  final List<String> ticketsAllocated;
  final int quantity;
  final String category;
  final double amount;
  final PaymentDetails? paymentDetails;
  final String? error;

  PaymentInitiationResponse({
    required this.success,
    required this.paymentReference,
    required this.ticketsAllocated,
    required this.quantity,
    required this.category,
    required this.amount,
    this.paymentDetails,
    this.error,
  });

  factory PaymentInitiationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationResponse(
      success: json['success'] ?? false,
      paymentReference: json['payment_reference'] ?? json['paymentReference'] ?? '',
      ticketsAllocated: json['tickets_allocated'] != null
          ? List<String>.from(json['tickets_allocated'])
          : (json['ticketsAllocated'] != null
              ? List<String>.from(json['ticketsAllocated'])
              : []),
      quantity: json['quantity'] ?? json['ticket_quantity'] ?? 0,
      category: json['category'] ?? json['ticket_category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDetails: json['payment_details'] != null
          ? PaymentDetails.fromJson(json['payment_details'])
          : (json['paymentDetails'] != null
              ? PaymentDetails.fromJson(json['paymentDetails'])
              : null),
      error: json['error'],
    );
  }
}

/// Payment details (MonCash/NatCash specific)
class PaymentDetails {
  final bool success;
  final String? paymentToken;
  final String? redirectUrl;
  final String? paymentId;
  final String? transactionRef;
  final String? status;
  final String? mode;

  PaymentDetails({
    required this.success,
    this.paymentToken,
    this.redirectUrl,
    this.paymentId,
    this.transactionRef,
    this.status,
    this.mode,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      success: json['success'] ?? false,
      paymentToken: json['paymentToken'] ?? json['payment_token'],
      redirectUrl: json['redirectUrl'] ?? json['redirect_url'],
      paymentId: json['paymentId'] ?? json['payment_id'],
      transactionRef: json['transactionRef'] ?? json['transaction_ref'],
      status: json['status'],
      mode: json['mode'],
    );
  }
}

/// Payment method definition
class PaymentMethodOption {
  final String id;
  final String name;
  final String type; // 'automated' or 'manual'
  final String? description;
  final String? icon;
  final bool enabled;

  const PaymentMethodOption({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.icon,
    this.enabled = true,
  });

  bool get isAutomated => type == 'automated';
  bool get isManual => type == 'manual';
}

/// Available payment methods
class PaymentMethods {
  static const moncashAutomated = PaymentMethodOption(
    id: 'moncash',
    name: 'MonCash',
    type: 'automated',
    description: 'Pay instantly with MonCash',
    icon: '💳',
  );

  static const moncashManual = PaymentMethodOption(
    id: 'moncash_manual',
    name: 'MonCash USSD',
    type: 'manual',
    description: 'Pay with *202# and submit reference',
    icon: '📱',
  );

  static const natcashAutomated = PaymentMethodOption(
    id: 'natcash',
    name: 'NatCash',
    type: 'automated',
    description: 'Pay instantly with NatCash',
    icon: '💳',
  );

  static const natcashManual = PaymentMethodOption(
    id: 'natcash_manual',
    name: 'NatCash Manual',
    type: 'manual',
    description: 'Pay via NatCash app and submit reference',
    icon: '📱',
  );

  static const List<PaymentMethodOption> all = [
    moncashAutomated,
    moncashManual,
    natcashAutomated,
    natcashManual,
  ];

  static PaymentMethodOption? getById(String id) {
    try {
      return all.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }
}
