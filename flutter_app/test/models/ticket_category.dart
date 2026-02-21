/// Test-only ticket category model used by test fixtures.
class TicketCategory {
  final String id;
  final String name;
  final String code;
  final double price;
  final String description;

  TicketCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.description,
  });
}
