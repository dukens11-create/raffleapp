class AvailableTicket {
  final String ticketNumber;
  final String category;
  final int price;
  final String status;

  AvailableTicket({
    required this.ticketNumber,
    required this.category,
    required this.price,
    required this.status,
  });

  factory AvailableTicket.fromJson(Map<String, dynamic> json) {
    return AvailableTicket(
      ticketNumber: json['ticket_number'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      status: json['status'] ?? 'available',
    );
  }
}

class AvailableTicketsResponse {
  final List<AvailableTicket> tickets;
  final int total;

  AvailableTicketsResponse({
    required this.tickets,
    required this.total,
  });

  factory AvailableTicketsResponse.fromJson(Map<String, dynamic> json) {
    return AvailableTicketsResponse(
      tickets: (json['tickets'] as List?)
              ?.map((t) => AvailableTicket.fromJson(t))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}
