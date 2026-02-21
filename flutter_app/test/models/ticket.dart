import 'package:raffle_app/models/ticket_data.dart';

/// Test-only ticket model used by test fixtures.
///
/// Implements [TicketData] so it can be passed to [TicketProvider] methods.
class Ticket implements TicketData {
  @override
  final String id;
  @override
  final String ticketNumber;
  final String raffleId;
  final String categoryId;
  @override
  final String status;
  @override
  final double price;
  final String? buyerId;
  @override
  final DateTime createdAt;
  final DateTime? soldAt;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.raffleId,
    required this.categoryId,
    required this.status,
    required this.price,
    this.buyerId,
    required this.createdAt,
    this.soldAt,
  });

  /// [TicketData.category] maps to [categoryId] for this test model.
  @override
  String get category => categoryId;

  Ticket copyWith({
    String? id,
    String? ticketNumber,
    String? raffleId,
    String? categoryId,
    String? status,
    double? price,
    String? buyerId,
    DateTime? createdAt,
    DateTime? soldAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      raffleId: raffleId ?? this.raffleId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      price: price ?? this.price,
      buyerId: buyerId ?? this.buyerId,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
    );
  }
}
