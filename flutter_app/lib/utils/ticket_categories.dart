/// Raffle ticket categories with pricing information
/// 
/// Matches the backend implementation with 6 standard categories
class TicketCategory {
  final String code;
  final String name;
  final double priceHTG;
  final String description;

  const TicketCategory({
    required this.code,
    required this.name,
    required this.priceHTG,
    required this.description,
  });

  String get displayName => '$code - $name ($priceHTG HTG)';
  
  String get shortDisplay => '$code - $priceHTG HTG';
}

class TicketCategories {
  /// All 6 ticket categories
  static const List<TicketCategory> all = [
    TicketCategory(
      code: 'BAS',
      name: 'Basic',
      priceHTG: 50.0,
      description: 'Entry level ticket',
    ),
    TicketCategory(
      code: 'PRM',
      name: 'Premium',
      priceHTG: 100.0,
      description: 'Premium ticket with better odds',
    ),
    TicketCategory(
      code: 'BRZ',
      name: 'Bronze',
      priceHTG: 250.0,
      description: 'Bronze level ticket',
    ),
    TicketCategory(
      code: 'SLV',
      name: 'Silver',
      priceHTG: 500.0,
      description: 'Silver level ticket',
    ),
    TicketCategory(
      code: 'GLD',
      name: 'Gold',
      priceHTG: 1000.0,
      description: 'Gold level ticket with premium benefits',
    ),
    TicketCategory(
      code: 'DIA',
      name: 'Diamond',
      priceHTG: 5000.0,
      description: 'Exclusive diamond ticket',
    ),
  ];

  /// Get category by code
  static TicketCategory? getByCode(String code) {
    try {
      return all.firstWhere((cat) => cat.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get category price by code
  static double getPrice(String code) {
    final category = getByCode(code);
    return category?.priceHTG ?? 0.0;
  }

  /// Get all category codes
  static List<String> getCodes() {
    return all.map((cat) => cat.code).toList();
  }

  /// Check if category code is valid
  static bool isValid(String code) {
    return all.any((cat) => cat.code == code);
  }
}
