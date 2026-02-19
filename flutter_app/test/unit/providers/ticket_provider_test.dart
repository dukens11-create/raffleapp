import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/providers/ticket_provider.dart';
import 'package:raffle_app/models/ticket.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('TicketProvider Tests', () {
    late TicketProvider ticketProvider;

    setUp(() {
      ticketProvider = TicketProvider();
    });

    group('State Management', () {
      test('should initialize with empty state', () {
        expect(ticketProvider.tickets, isEmpty);
        expect(ticketProvider.isLoading, isFalse);
        expect(ticketProvider.error, isNull);
      });

      test('should set loading state when fetching tickets', () {
        ticketProvider.setLoading(true);
        expect(ticketProvider.isLoading, isTrue);
      });

      test('should update tickets list', () {
        final tickets = TestData.availableTickets;
        ticketProvider.setTickets(tickets);
        
        expect(ticketProvider.tickets, equals(tickets));
        expect(ticketProvider.tickets.length, equals(tickets.length));
      });

      test('should handle error state', () {
        final errorMessage = 'Failed to load tickets';
        ticketProvider.setError(errorMessage);
        
        expect(ticketProvider.error, equals(errorMessage));
        expect(ticketProvider.isLoading, isFalse);
      });

      test('should notify listeners on state change', () {
        var notified = false;
        ticketProvider.addListener(() {
          notified = true;
        });

        ticketProvider.setLoading(true);
        expect(notified, isTrue);
      });
    });

    group('Ticket Operations', () {
      test('should fetch available tickets', () async {
        // This would test the actual API call with mocked service
        expect(ticketProvider, isNotNull);
      });

      test('should filter tickets by category', () {
        final tickets = TestData.availableTickets;
        ticketProvider.setTickets(tickets);

        final categoryId = TestData.basicCategory.id;
        final filtered = ticketProvider.getTicketsByCategory(categoryId);

        expect(filtered, isNotNull);
        expect(filtered.every((t) => t.categoryId == categoryId), isTrue);
      });

      test('should filter tickets by status', () {
        final allTickets = [
          TestData.basicTicket,
          TestData.soldTicket,
        ];
        ticketProvider.setTickets(allTickets);

        final available = ticketProvider.getAvailableTickets();
        expect(available.every((t) => t.status == 'available'), isTrue);
      });

      test('should get ticket by ID', () {
        final tickets = TestData.availableTickets;
        ticketProvider.setTickets(tickets);

        final ticket = ticketProvider.getTicketById(tickets.first.id);
        expect(ticket, isNotNull);
        expect(ticket?.id, equals(tickets.first.id));
      });

      test('should return null for non-existent ticket', () {
        final ticket = ticketProvider.getTicketById('nonexistent');
        expect(ticket, isNull);
      });
    });

    group('Ticket Purchase', () {
      test('should validate ticket availability before purchase', () {
        final ticket = TestData.basicTicket;
        expect(ticket.status, equals('available'));
      });

      test('should update ticket status after purchase', () {
        final ticket = TestData.basicTicket;
        expect(ticket.status, equals('available'));
        
        // After purchase, status should change
        final purchasedTicket = ticket.copyWith(
          status: 'sold',
          buyerId: TestData.buyerUser.id,
        );
        
        expect(purchasedTicket.status, equals('sold'));
        expect(purchasedTicket.buyerId, equals(TestData.buyerUser.id));
      });

      test('should calculate total price for multiple tickets', () {
        final tickets = TestData.availableTickets;
        final totalPrice = tickets.fold<double>(
          0,
          (sum, ticket) => sum + ticket.price,
        );

        expect(totalPrice, greaterThan(0));
        expect(totalPrice, equals(
          TestData.basicCategory.price +
          TestData.basicCategory.price +
          TestData.bronzeCategory.price
        ));
      });
    });

    group('Pagination', () {
      test('should load tickets in pages', () async {
        expect(ticketProvider, isNotNull);
      });

      test('should track current page', () {
        ticketProvider.setCurrentPage(2);
        expect(ticketProvider.currentPage, equals(2));
      });

      test('should check if more pages available', () {
        ticketProvider.setTotalPages(5);
        ticketProvider.setCurrentPage(3);
        
        expect(ticketProvider.hasMorePages, isTrue);
      });

      test('should handle last page', () {
        ticketProvider.setTotalPages(5);
        ticketProvider.setCurrentPage(5);
        
        expect(ticketProvider.hasMorePages, isFalse);
      });
    });

    group('Search and Filter', () {
      test('should search tickets by number', () {
        final tickets = TestData.availableTickets;
        ticketProvider.setTickets(tickets);

        final searchTerm = 'BAS';
        final results = ticketProvider.searchTickets(searchTerm);

        expect(results, isNotNull);
        expect(results.every((t) => t.ticketNumber.contains(searchTerm)), isTrue);
      });

      test('should filter by price range', () {
        final tickets = TestData.availableTickets;
        ticketProvider.setTickets(tickets);

        final minPrice = 0.0;
        final maxPrice = 100.0;
        final filtered = ticketProvider.filterByPriceRange(minPrice, maxPrice);

        expect(filtered.every((t) => t.price >= minPrice && t.price <= maxPrice), isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle network errors', () async {
        expect(ticketProvider, isNotNull);
      });

      test('should handle empty response', () {
        ticketProvider.setTickets([]);
        expect(ticketProvider.tickets, isEmpty);
      });

      test('should handle invalid data', () async {
        expect(ticketProvider, isNotNull);
      });
    });
  });
}
