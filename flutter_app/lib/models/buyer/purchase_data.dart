class PurchaseRequest {
  final String fullName;
  final String phone;
  final String department;
  final String? email;
  final String category;
  final int quantity;
  final String paymentMethod;

  PurchaseRequest({
    required this.fullName,
    required this.phone,
    required this.department,
    this.email,
    required this.category,
    required this.quantity,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'department': department,
      'email': email,
      'category': category,
      'quantity': quantity,
      'payment_method': paymentMethod,
    };
  }
}

class PurchaseResponse {
  final bool success;
  final String? message;
  final String? buyerCode;
  final String? redirectUrl;
  final dynamic data;

  PurchaseResponse({
    required this.success,
    this.message,
    this.buyerCode,
    this.redirectUrl,
    this.data,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      success: json['success'] ?? false,
      message: json['message'],
      buyerCode: json['buyer_code'],
      redirectUrl: json['redirect_url'],
      data: json['data'],
    );
  }
}

class ManualPaymentRequest {
  final String buyerCode;
  final String transactionReference;
  final String paymentMethod;

  ManualPaymentRequest({
    required this.buyerCode,
    required this.transactionReference,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'buyer_code': buyerCode,
      'transaction_reference': transactionReference,
      'payment_method': paymentMethod,
    };
  }
}

class ManualPaymentResponse {
  final bool success;
  final String message;

  ManualPaymentResponse({
    required this.success,
    required this.message,
  });

  factory ManualPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ManualPaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
