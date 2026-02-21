/// Abstract interface for ticket data used by [TicketProvider].
///
/// Both production and test ticket models implement this interface so that
/// [TicketProvider] can store and query tickets without depending on a
/// specific concrete class.
abstract class TicketData {
  String get id;
  String get ticketNumber;
  String get category;
  double get price;
  String get status;
  DateTime get createdAt;
}
