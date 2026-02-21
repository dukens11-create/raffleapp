import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/models/ticket.dart';
import 'package:raffle_app/models/ticket_admin.dart';

void main() {
  group('TicketAdmin.fromJson', () {
    test('constructs a valid instance from a full JSON payload', () {
      final json = {
        'id': 1,
        'ticket_number': 'BAS-001',
        'barcode': 'ABC123',
        'category': 'BAS',
        'price': 50.0,
        'status': 'available',
        'seller_id': 2,
        'seller_name': 'John Doe',
        'buyer_phone': '+50912345678',
        'buyer_name': 'Jane Doe',
        'department': 'Nord',
        'available_online': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'sold_at': '2024-01-02T00:00:00.000Z',
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket.id, 1);
      expect(ticket.ticketNumber, 'BAS-001');
      expect(ticket.barcode, 'ABC123');
      expect(ticket.category, 'BAS');
      expect(ticket.price, 50.0);
      expect(ticket.status, 'available');
      expect(ticket.sellerId, 2);
      expect(ticket.sellerName, 'John Doe');
      expect(ticket.buyerPhone, '+50912345678');
      expect(ticket.buyerName, 'Jane Doe');
      expect(ticket.department, 'Nord');
      expect(ticket.availableOnline, true);
      expect(ticket.soldAt, isNotNull);
    });

    test('constructs a valid instance even when optional admin fields are missing', () {
      final json = {
        'id': 2,
        'ticket_number': 'PRM-001',
        'status': 'available',
        'category': 'PRM',
        'created_at': '2024-03-01T10:00:00.000Z',
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket.id, 2);
      expect(ticket.ticketNumber, 'PRM-001');
      // Falls back to empty string when barcode is absent
      expect(ticket.barcode, '');
      // Falls back to 0.0 when price is absent
      expect(ticket.price, 0.0);
      expect(ticket.sellerId, isNull);
      expect(ticket.sellerName, isNull);
      expect(ticket.buyerPhone, isNull);
      expect(ticket.buyerName, isNull);
      expect(ticket.department, isNull);
      expect(ticket.availableOnline, false);
      expect(ticket.soldAt, isNull);
    });

    test('parses price correctly from integer JSON value', () {
      final json = {
        'id': 3,
        'ticket_number': 'GLD-001',
        'barcode': 'XYZ789',
        'category': 'GLD',
        'price': 1000,
        'status': 'sold',
        'available_online': 1,
        'created_at': '2024-02-01T00:00:00.000Z',
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket.price, 1000.0);
      expect(ticket.availableOnline, true);
    });

    test('is a subtype of Ticket', () {
      final json = {
        'id': 4,
        'ticket_number': 'BRZ-001',
        'barcode': 'BRZ456',
        'category': 'BRZ',
        'price': 250.0,
        'status': 'available',
        'available_online': false,
        'created_at': '2024-01-15T00:00:00.000Z',
      };

      final ticket = TicketAdmin.fromJson(json);

      expect(ticket, isA<TicketAdmin>());
      // Verify polymorphic use as Ticket
      expect(ticket, isA<Ticket>());
    });
  });
}
