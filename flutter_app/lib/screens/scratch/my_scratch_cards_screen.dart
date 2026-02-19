import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/scratch_ticket.dart';
import '../../providers/scratch_provider.dart';
import 'scratch_card_screen.dart';

class MyScratchCardsScreen extends StatefulWidget {
  const MyScratchCardsScreen({Key? key}) : super(key: key);

  @override
  State<MyScratchCardsScreen> createState() => _MyScratchCardsScreenState();
}

class _MyScratchCardsScreenState extends State<MyScratchCardsScreen> {
  final _phoneController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    setState(() => _hasSearched = true);
    await context.read<ScratchProvider>().loadTickets(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scratch Cards'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Phone lookup form
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Your Scratch Tickets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _loadTickets(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loadTickets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Search',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: Consumer<ScratchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.clearError();
                              _loadTickets();
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!_hasSearched) {
                  return _buildEmptyPrompt();
                }

                if (provider.tickets.isEmpty) {
                  return _buildNoTickets();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.tickets.length,
                  itemBuilder: (context, index) {
                    return _TicketListItem(
                      ticket: provider.tickets[index],
                      phone: _phoneController.text.trim(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎫', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'Find Your Scratch Tickets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your phone number above to find purchased scratch tickets.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTickets() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😢', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'No Scratch Tickets Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Purchase scratch tickets from the Scratch & Win section.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Individual ticket list item
// ============================================================
class _TicketListItem extends StatelessWidget {
  final ScratchTicket ticket;
  final String phone;

  const _TicketListItem({required this.ticket, required this.phone});

  Color _getStatusColor() {
    if (!ticket.isScratched) return Colors.amber.shade700;
    if (ticket.claimed) return Colors.blue.shade700;
    if (ticket.hasPrize) return Colors.green.shade700;
    return Colors.grey.shade600;
  }

  String _getStatusLabel() {
    if (!ticket.isScratched) return 'Scratch Me!';
    if (ticket.claimed) return 'Claimed';
    if (ticket.hasPrize) return 'Won!';
    return 'No Prize';
  }

  String _getIcon() {
    if (!ticket.isScratched) return '🎰';
    if (ticket.claimed) return '✅';
    if (ticket.hasPrize) return '🎉';
    return '😢';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScratchCardScreen(
                ticket: ticket,
                phone: phone,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(_getIcon(), style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ticket.displayCategory} Ticket',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.shortRef,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (ticket.createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        ticket.createdAt!.toLocal().toString().split('.').first,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor().withOpacity(0.4)),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
