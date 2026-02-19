import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/ticket_card.dart';
import 'scratch_screen.dart';
import 'my_scratch_cards_screen.dart';

class TicketGalleryScreen extends StatelessWidget {
  const TicketGalleryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 GRATE GENYEN'),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyScratchCardsScreen()),
              );
            },
            icon: const Icon(Icons.casino_outlined, color: Colors.white, size: 18),
            label: const Text('My Cards', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<TicketProvider>(
          builder: (context, ticketProvider, child) {
            if (ticketProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return Column(
              children: [
                // Header Message
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Chwazi yon tikè epi grate pou wè si ou genyen!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose a ticket and scratch to win!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ticket Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: ticketProvider.tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = ticketProvider.tickets[index];
                      return TicketCard(
                        ticket: ticket,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScratchScreen(ticket: ticket),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
