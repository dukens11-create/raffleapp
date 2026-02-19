class Seller {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? department;
  final String status; // pending, approved, rejected
  final int totalSales;
  final double commissionEarned;
  final int activeTickets;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  Seller({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.department,
    required this.status,
    this.totalSales = 0,
    this.commissionEarned = 0.0,
    this.activeTickets = 0,
    this.createdAt,
    this.approvedAt,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      department: json['department'],
      status: json['status'] ?? 'pending',
      totalSales: json['total_sales'] ?? 0,
      commissionEarned: (json['commission_earned'] ?? 0).toDouble(),
      activeTickets: json['active_tickets'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'department': department,
      'status': status,
      'total_sales': totalSales,
      'commission_earned': commissionEarned,
      'active_tickets': activeTickets,
      'created_at': createdAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}

class SellerStatistics {
  final int totalSales;
  final double totalRevenue;
  final double totalCommission;
  final int activeTickets;
  final int soldTickets;
  final List<CategorySales> categorySales;
  final List<DailySales> dailySales;

  SellerStatistics({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalCommission,
    required this.activeTickets,
    required this.soldTickets,
    required this.categorySales,
    required this.dailySales,
  });

  factory SellerStatistics.fromJson(Map<String, dynamic> json) {
    return SellerStatistics(
      totalSales: json['total_sales'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalCommission: (json['total_commission'] ?? 0).toDouble(),
      activeTickets: json['active_tickets'] ?? 0,
      soldTickets: json['sold_tickets'] ?? 0,
      categorySales: (json['category_sales'] as List?)
              ?.map((e) => CategorySales.fromJson(e))
              .toList() ??
          [],
      dailySales: (json['daily_sales'] as List?)
              ?.map((e) => DailySales.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategorySales {
  final String category;
  final int count;
  final double revenue;

  CategorySales({
    required this.category,
    required this.count,
    required this.revenue,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) {
    return CategorySales(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class DailySales {
  final DateTime date;
  final int count;
  final double revenue;

  DailySales({
    required this.date,
    required this.count,
    required this.revenue,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}
