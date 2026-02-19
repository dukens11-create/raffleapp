class Statistics {
  final int totalTickets;
  final int totalSold;
  final int totalAvailable;
  final double totalRevenue;
  final int activeRaffles;
  final int pendingTransactions;
  final List<CategoryStat> categoryStats;
  final List<DepartmentStat> departmentStats;
  final List<SellerStat> sellerStats;

  Statistics({
    required this.totalTickets,
    required this.totalSold,
    required this.totalAvailable,
    required this.totalRevenue,
    required this.activeRaffles,
    required this.pendingTransactions,
    required this.categoryStats,
    required this.departmentStats,
    required this.sellerStats,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalTickets: json['total_tickets'] ?? 0,
      totalSold: json['total_sold'] ?? 0,
      totalAvailable: json['total_available'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      activeRaffles: json['active_raffles'] ?? 0,
      pendingTransactions: json['pending_transactions'] ?? 0,
      categoryStats: (json['category_stats'] as List?)
              ?.map((e) => CategoryStat.fromJson(e))
              .toList() ??
          [],
      departmentStats: (json['department_stats'] as List?)
              ?.map((e) => DepartmentStat.fromJson(e))
              .toList() ??
          [],
      sellerStats: (json['seller_stats'] as List?)
              ?.map((e) => SellerStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategoryStat {
  final String category;
  final int total;
  final int sold;
  final int available;
  final double revenue;

  CategoryStat({
    required this.category,
    required this.total,
    required this.sold,
    required this.available,
    required this.revenue,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? '',
      total: json['total'] ?? 0,
      sold: json['sold'] ?? 0,
      available: json['available'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class DepartmentStat {
  final String department;
  final int ticketsSold;
  final double revenue;
  final int activeTickets;

  DepartmentStat({
    required this.department,
    required this.ticketsSold,
    required this.revenue,
    required this.activeTickets,
  });

  factory DepartmentStat.fromJson(Map<String, dynamic> json) {
    return DepartmentStat(
      department: json['department'] ?? '',
      ticketsSold: json['tickets_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      activeTickets: json['active_tickets'] ?? 0,
    );
  }
}

class SellerStat {
  final int? sellerId;
  final String sellerName;
  final int ticketsSold;
  final double revenue;
  final double commission;

  SellerStat({
    this.sellerId,
    required this.sellerName,
    required this.ticketsSold,
    required this.revenue,
    required this.commission,
  });

  factory SellerStat.fromJson(Map<String, dynamic> json) {
    return SellerStat(
      sellerId: json['seller_id'],
      sellerName: json['seller_name'] ?? 'Unknown',
      ticketsSold: json['tickets_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
    );
  }
}
