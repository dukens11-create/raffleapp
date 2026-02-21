/// Test-only raffle model used by test fixtures.
class Raffle {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime drawDate;
  final String status;
  final int totalTickets;
  final int availableTickets;

  Raffle({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.drawDate,
    required this.status,
    required this.totalTickets,
    required this.availableTickets,
  });
}
