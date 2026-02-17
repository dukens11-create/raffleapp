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
    List<AvailableTicket> allTickets = [];
    
    // Parse categories object from backend
    if (json['categories'] != null && json['categories'] is Map) {
      final categories = json['categories'] as Map<String, dynamic>;
      categories.forEach((category, tickets) {
        if (tickets is List) {
          allTickets.addAll(
            tickets.map((t) => AvailableTicket.fromJson(t)).toList()
          );
        }
      });
    }
    
    return AvailableTicketsResponse(
      tickets: allTickets,
      total: allTickets.length,
    );
  }
}
