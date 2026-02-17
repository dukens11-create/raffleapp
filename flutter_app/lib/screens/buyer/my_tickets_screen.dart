import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/my_tickets_provider.dart';
import '../../widgets/raffle_ticket_card.dart';
import '../../widgets/loading_indicator.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tikè Mwen'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MyTicketsProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<MyTicketsProvider>(
        builder: (context, ticketProvider, child) {
          // Show phone input if no phone is set
          if (ticketProvider.currentPhone == null) {
            return _buildPhoneInput();
          }

          // Show loading
          if (ticketProvider.isLoading) {
            return const LoadingIndicator(message: 'Chajman tikè ou yo...');
          }

          // Show error
          if (ticketProvider.error != null) {
            return ErrorDisplay(
              error: ticketProvider.error!,
              onRetry: () => ticketProvider.refresh(),
            );
          }

          // Show empty state
          if (!ticketProvider.hasTickets) {
            return EmptyState(
              icon: Icons.confirmation_number,
              title: 'Pa gen tikè',
              subtitle: 'Ou poko achte tikè ak nimewo sa a',
              action: ElevatedButton(
                onPressed: () {
                  ticketProvider.clear();
                  _phoneController.clear();
                },
                child: const Text('Eseye yon lòt nimewo'),
              ),
            );
          }

          // Show tickets list
          return RefreshIndicator(
            onRefresh: () => ticketProvider.refresh(),
            child: Column(
              children: [
                // Phone info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nimewo Telefòn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              ticketProvider.currentPhone!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ticketProvider.clear();
                          _phoneController.clear();
                        },
                        child: const Text('Chanje'),
                      ),
                    ],
                  ),
                ),

                // Tickets count
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ticketProvider.ticketCount} Tikè',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Filter options
                      DropdownButton<String>(
                        value: 'all',
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tout Tikè'),
                          ),
                          DropdownMenuItem(
                            value: 'sold',
                            child: Text('Tikè Vandi'),
                          ),
                        ],
                        onChanged: (value) {
                          // Filter logic here
                        },
                      ),
                    ],
                  ),
                ),

                // Tickets list
                Expanded(
                  child: ListView.builder(
                    itemCount: ticketProvider.myTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = ticketProvider.myTickets[index];
                      return RaffleTicketCard(
                        ticket: ticket,
                        showStatus: true,
                        showBuyer: true,
                        onTap: () => _showTicketDetails(context, ticket),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_android,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Antre Nimewo Telefòn Ou',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Antre nimewo telefòn ou te itilize pou achte tikè yo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Nimewo Telefòn',
              hintText: '509-XXXX-XXXX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final phone = _phoneController.text.trim();
                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tanpri antre yon nimewo telefòn'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                context.read<MyTicketsProvider>().loadTicketsByPhone(phone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Chèche Tikè Mwen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(BuildContext context, ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Detay Tikè',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ticket details
                  _buildDetailCard('Nimewo Tikè', ticket.ticketNumber, Icons.confirmation_number),
                  const SizedBox(height: 12),
                  _buildDetailCard('Kategori', ticket.category, Icons.category),
                  const SizedBox(height: 12),
                  _buildDetailCard('Pri', '${ticket.price.toStringAsFixed(0)} HTG', Icons.attach_money),
                  const SizedBox(height: 12),
                  _buildDetailCard('Estati', ticket.status, Icons.info),
                  
                  if (ticket.buyerName != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard('Non', ticket.buyerName!, Icons.person),
                  ],
                  
                  if (ticket.buyerPhone != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard('Telefòn', ticket.buyerPhone!, Icons.phone),
                  ],
                  
                  if (ticket.department != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard('Depatman', ticket.department!, Icons.location_on),
                  ],

                  if (ticket.soldAt != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'Dat Acha',
                      _formatDate(ticket.soldAt!),
                      Icons.calendar_today,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement QR code display
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kòd QR ap vini byento'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Montre QR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Fèmen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
