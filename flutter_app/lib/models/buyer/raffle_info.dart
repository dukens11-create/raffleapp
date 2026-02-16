class RaffleInfo {
  final String raffleName;
  final String? drawDate;
  final String status;
  final String? description;
  final List<TicketType> ticketTypes;
  final List<CategoryInfo> categories;
  final TicketStatistics statistics;

  RaffleInfo({
    required this.raffleName,
    this.drawDate,
    required this.status,
    this.description,
    required this.ticketTypes,
    required this.categories,
    required this.statistics,
  });

  factory RaffleInfo.fromJson(Map<String, dynamic> json) {
    return RaffleInfo(
      raffleName: json['raffle_name'] ?? 'Unknown Raffle',
      drawDate: json['draw_date'],
      status: json['status'] ?? 'unknown',
      description: json['description'],
      ticketTypes: (json['ticket_types'] as List?)
              ?.map((t) => TicketType.fromJson(t))
              .toList() ??
          [],
      categories: (json['categories'] as List?)
              ?.map((c) => CategoryInfo.fromJson(c))
              .toList() ??
          [],
      statistics: TicketStatistics.fromJson(json['statistics'] ?? {}),
    );
  }
}

class TicketType {
  final String type;
  final int price;
  final int maxPrize;
  final String category;

  TicketType({
    required this.type,
    required this.price,
    required this.maxPrize,
    required this.category,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      type: json['type'] ?? '',
      price: json['price'] ?? 0,
      maxPrize: json['max_prize'] ?? 0,
      category: json['category'] ?? '',
    );
  }
}

class CategoryInfo {
  final String category;
  final int price;
  final int available;

  CategoryInfo({
    required this.category,
    required this.price,
    required this.available,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      available: json['available'] ?? 0,
    );
  }
}

class TicketStatistics {
  final int totalTickets;
  final int availableTickets;
  final int soldTickets;

  TicketStatistics({
    required this.totalTickets,
    required this.availableTickets,
    required this.soldTickets,
  });

  factory TicketStatistics.fromJson(Map<String, dynamic> json) {
    return TicketStatistics(
      totalTickets: json['total_tickets'] ?? 0,
      availableTickets: json['available_tickets'] ?? 0,
      soldTickets: json['sold_tickets'] ?? 0,
    );
  }
}
