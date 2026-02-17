import 'raffle.dart';
import 'ticket_category.dart';

class RaffleInfo {
  final Raffle raffle;
  final List<TicketCategory> categories;
  final RaffleStats stats;

  RaffleInfo({
    required this.raffle,
    required this.categories,
    required this.stats,
  });

  factory RaffleInfo.fromJson(Map<String, dynamic> json) {
    return RaffleInfo(
      raffle: Raffle.fromJson(json['raffle']),
      categories: (json['categories'] as List)
          .map((cat) => TicketCategory.fromJson(cat))
          .toList(),
      stats: RaffleStats.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raffle': raffle.toJson(),
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }

  TicketCategory? getCategoryByCode(String code) {
    try {
      return categories.firstWhere((cat) => cat.categoryCode == code);
    } catch (e) {
      return null;
    }
  }

  List<TicketCategory> get availableCategories => 
    categories.where((cat) => cat.isAvailable).toList();
}

class RaffleStats {
  final int totalTickets;
  final int soldTickets;
  final int availableTickets;

  RaffleStats({
    required this.totalTickets,
    required this.soldTickets,
    required this.availableTickets,
  });

  factory RaffleStats.fromJson(Map<String, dynamic> json) {
    return RaffleStats(
      totalTickets: json['total_tickets'] as int,
      soldTickets: json['sold_tickets'] as int,
      availableTickets: json['available_tickets'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_tickets': totalTickets,
      'sold_tickets': soldTickets,
      'available_tickets': availableTickets,
    };
  }

  double get soldPercentage => 
    totalTickets > 0 ? (soldTickets / totalTickets) * 100 : 0;
    
  double get availablePercentage => 
    totalTickets > 0 ? (availableTickets / totalTickets) * 100 : 0;
}
