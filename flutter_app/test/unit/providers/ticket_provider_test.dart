import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/providers/ticket_provider.dart';

void main() {
  group('TicketProvider', () {
    late TicketProvider ticketProvider;

    setUp(() {
      ticketProvider = TicketProvider();
    });

    test('should create TicketProvider instance', () {
      expect(ticketProvider, isNotNull);
      expect(ticketProvider, isA<TicketProvider>());
    });

    test('should load tickets on initialization', () {
      expect(ticketProvider.tickets, isA<List>());
      expect(ticketProvider.isLoading, false);
    });

    group('loadTickets', () {
      test('should load tickets from constants', () {
        ticketProvider.loadTickets();
        
        expect(ticketProvider.tickets, isNotNull);
        expect(ticketProvider.isLoading, false);
      });
    });

    group('scratchTicket', () {
      test('should scratch a ticket and return prize', () {
        ticketProvider.loadTickets();
        
        if (ticketProvider.tickets.isNotEmpty) {
          final ticketId = ticketProvider.tickets.first.id;
          final prize = ticketProvider.scratchTicket(ticketId);
          
          expect(prize, isNotNull);
          expect(ticketProvider.scratchedTickets.containsKey(ticketId), true);
        }
      });

      test('should store scratched ticket result', () {
        ticketProvider.loadTickets();
        
        if (ticketProvider.tickets.isNotEmpty) {
          final ticketId = ticketProvider.tickets.first.id;
          final prize = ticketProvider.scratchTicket(ticketId);
          
          expect(ticketProvider.getScratchedPrize(ticketId), equals(prize));
        }
      });
    });

    group('getScratchedPrize', () {
      test('should return null for non-scratched ticket', () {
        final prize = ticketProvider.getScratchedPrize('non-existent');
        
        expect(prize, null);
      });

      test('should return prize for scratched ticket', () {
        ticketProvider.loadTickets();
        
        if (ticketProvider.tickets.isNotEmpty) {
          final ticketId = ticketProvider.tickets.first.id;
          ticketProvider.scratchTicket(ticketId);
          
          final prize = ticketProvider.getScratchedPrize(ticketId);
          expect(prize, isNotNull);
        }
      });
    });

    group('clearScratchedTickets', () {
      test('should clear all scratched tickets', () {
        ticketProvider.loadTickets();
        
        if (ticketProvider.tickets.isNotEmpty) {
          final ticketId = ticketProvider.tickets.first.id;
          ticketProvider.scratchTicket(ticketId);
          
          expect(ticketProvider.scratchedTickets.isNotEmpty, true);
          
          ticketProvider.clearScratchedTickets();
          expect(ticketProvider.scratchedTickets.isEmpty, true);
        }
      });
    });
  });
}
