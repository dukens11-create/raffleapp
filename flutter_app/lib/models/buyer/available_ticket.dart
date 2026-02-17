class AvailableTicket {
  final String ticketNumber;
  final String barcode;
  final String category;
  final double price;
  final String status;
  final String createdAt;

  AvailableTicket({
    required this.ticketNumber,
    required this.barcode,
    required this.category,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory AvailableTicket.fromJson(Map<String, dynamic> json) {
    return AvailableTicket(
      ticketNumber: json['ticket_number'] ?? '',
      barcode: json['barcode'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'AVAILABLE',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AvailableTicketsResponse {
  final Map<String, List<AvailableTicket>> categories;
  final String timestamp;

  AvailableTicketsResponse({
    required this.categories,
    required this.timestamp,
  });

  factory AvailableTicketsResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<AvailableTicket>> cats = {};
    
    if (json['categories'] != null) {
      (json['categories'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          cats[key] = value
              .map((t) => AvailableTicket.fromJson(t))
              .toList();
        }
      });
    }

    return AvailableTicketsResponse(
      categories: cats,
      timestamp: json['timestamp'] ?? '',
    );
  }
  
  // Helper method to get all tickets as a flat list
  List<AvailableTicket> getAllTickets() {
    return categories.values.expand((list) => list).toList();
  }
  
  // Helper method to get total ticket count
  int getTotalCount() {
    return categories.values.fold(0, (sum, list) => sum + list.length);
  }
}
