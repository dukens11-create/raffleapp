import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/models/ticket_admin.dart';

void main() {
  group('TicketAdmin.fromJson', () {
    test('constructs instance with all fields present', () {
      final json = {
        'id': 1,
        'ticket_number': 'T-001',
        'barcode': 'BC-001',
        'category': 'BAS',
        'price': 50.0,
        'status': 'AVAILABLE',
        'seller_id': 2,
        'seller_name': 'John',
        'buyer_phone': '555-1234',
        'buyer_name': 'Jane',
        'department': 'North',
        'available_online': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'sold_at': null,
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket.id, 1);
      expect(ticket.ticketNumber, 'T-001');
      expect(ticket.barcode, 'BC-001');
      expect(ticket.category, 'BAS');
      expect(ticket.price, 50.0);
      expect(ticket.status, 'AVAILABLE');
      expect(ticket.sellerName, 'John');
      expect(ticket.buyerPhone, '555-1234');
      expect(ticket.buyerName, 'Jane');
      expect(ticket.department, 'North');
      expect(ticket.availableOnline, true);
      expect(ticket.soldAt, isNull);
    });

    test('constructs instance with optional admin-only fields missing', () {
      // Minimal JSON – admin-only fields (barcode, price) may be absent;
      // created_at is always required (consistent with Ticket.fromJson)
      final json = {
        'id': 5,
        'ticket_number': 'T-005',
        'category': 'PRM',
        'status': 'AVAILABLE',
        'available_online': false,
        'created_at': '2024-06-15T12:00:00.000Z',
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket.id, 5);
      // barcode falls back to empty string
      expect(ticket.barcode, '');
      // price falls back to 0.0
      expect(ticket.price, 0.0);
      expect(ticket.sellerName, isNull);
      expect(ticket.buyerName, isNull);
      expect(ticket.soldAt, isNull);
    });

    test('throws ArgumentError when created_at is missing', () {
      final json = {
        'id': 9,
        'ticket_number': 'T-009',
        'category': 'BAS',
        'status': 'AVAILABLE',
        'available_online': true,
        // created_at intentionally omitted
      };

      expect(() => TicketAdmin.fromJson(json), throwsA(isA<ArgumentError>()));
    });

    test('parses sold_at when present', () {
      final json = {
        'id': 3,
        'ticket_number': 'T-003',
        'barcode': 'BC-003',
        'category': 'GLD',
        'price': 1000.0,
        'status': 'SOLD',
        'available_online': false,
        'created_at': '2024-01-01T00:00:00.000Z',
        'sold_at': '2024-03-10T08:30:00.000Z',
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket.isSold, true);
      expect(ticket.soldAt, DateTime.parse('2024-03-10T08:30:00.000Z'));
    });
  });
}
