class MyTicket {
  final String ticketNumber;
  final String category;
  final int price;
  final String barcode;
  final String purchaseDate;
  final String status;

  MyTicket({
    required this.ticketNumber,
    required this.category,
    required this.price,
    required this.barcode,
    required this.purchaseDate,
    required this.status,
  });

  factory MyTicket.fromJson(Map<String, dynamic> json) {
    return MyTicket(
      ticketNumber: json['ticket_number'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      barcode: json['barcode'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      status: json['status'] ?? 'unknown',
    );
  }
}

class MyTicketsResponse {
  final List<MyTicket> tickets;
  final int count;

  MyTicketsResponse({
    required this.tickets,
    required this.count,
  });

  factory MyTicketsResponse.fromJson(Map<String, dynamic> json) {
    return MyTicketsResponse(
      tickets: (json['tickets'] as List?)
              ?.map((t) => MyTicket.fromJson(t))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}
