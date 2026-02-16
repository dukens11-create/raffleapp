class VerifyTicketResponse {
  final bool valid;
  final String? ticketNumber;
  final String? category;
  final int? price;
  final String? status;
  final String? message;

  VerifyTicketResponse({
    required this.valid,
    this.ticketNumber,
    this.category,
    this.price,
    this.status,
    this.message,
  });

  factory VerifyTicketResponse.fromJson(Map<String, dynamic> json) {
    return VerifyTicketResponse(
      valid: json['valid'] ?? false,
      ticketNumber: json['ticket_number'],
      category: json['category'],
      price: json['price'],
      status: json['status'],
      message: json['message'],
    );
  }
}
