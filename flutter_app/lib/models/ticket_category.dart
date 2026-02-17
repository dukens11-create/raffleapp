class TicketCategory {
  final String categoryCode;
  final String categoryName;
  final double price;
  final String? color;
  final int onlineAvailable;
  final int onlineTotal;

  TicketCategory({
    required this.categoryCode,
    required this.categoryName,
    required this.price,
    this.color,
    required this.onlineAvailable,
    required this.onlineTotal,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      categoryCode: json['category_code'] as String,
      categoryName: json['category_name'] as String,
      price: (json['price'] as num).toDouble(),
      color: json['color'] as String?,
      onlineAvailable: json['online_available'] as int,
      onlineTotal: json['online_total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_code': categoryCode,
      'category_name': categoryName,
      'price': price,
      'color': color,
      'online_available': onlineAvailable,
      'online_total': onlineTotal,
    };
  }

  bool get isAvailable => onlineAvailable > 0;
  bool get isSoldOut => onlineAvailable == 0;
  
  double get availabilityPercentage => 
    onlineTotal > 0 ? (onlineAvailable / onlineTotal) * 100 : 0;
}
