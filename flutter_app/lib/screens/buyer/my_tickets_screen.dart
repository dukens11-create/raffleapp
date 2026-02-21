import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/my_tickets_provider.dart';
import '../../widgets/language_switcher.dart';
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
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('my_tickets_title')),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          const LanguageSwitcher(),
          const SizedBox(width: 4),
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
            return _buildPhoneInput(locale);
          }

          // Show loading
          if (ticketProvider.isLoading) {
            return LoadingIndicator(message: locale.translate('loading_my_tickets'));
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
              title: locale.translate('no_tickets_phone'),
              subtitle: locale.translate('no_tickets_phone_sub'),
              action: ElevatedButton(
                onPressed: () {
                  ticketProvider.clear();
                  _phoneController.clear();
                },
                child: Text(locale.translate('try_another_number')),
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
                            Text(
                              locale.translate('phone_label'),
                              style: const TextStyle(
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
                        child: Text(locale.translate('change')),
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
                        '${ticketProvider.ticketCount} ${locale.translate('ticket_count_label')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Filter options
                      DropdownButton<String>(
                        value: 'all',
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(locale.translate('all_tickets_filter')),
                          ),
                          DropdownMenuItem(
                            value: 'sold',
                            child: Text(locale.translate('sold_tickets_filter')),
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
                        onTap: () => _showTicketDetails(context, ticket, locale),
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

  Widget _buildPhoneInput(LocaleProvider locale) {
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
          Text(
            locale.translate('enter_phone'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('phone_subtitle'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: locale.translate('phone_label'),
              hintText: locale.translate('phone_hint'),
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
                    SnackBar(
                      content: Text(locale.translate('phone_required')),
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
              child: Text(
                locale.translate('search_my_tickets'),
                style: const TextStyle(
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

  void _showTicketDetails(BuildContext context, ticket, LocaleProvider locale) {
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
                  Text(
                    locale.translate('ticket_details'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ticket details
                  _buildDetailCard(locale.translate('ticket_number'), ticket.ticketNumber, Icons.confirmation_number),
                  const SizedBox(height: 12),
                  _buildDetailCard(locale.translate('category'), ticket.category, Icons.category),
                  const SizedBox(height: 12),
                  _buildDetailCard(locale.translate('price'), '${ticket.price.toStringAsFixed(0)} HTG', Icons.attach_money),
                  const SizedBox(height: 12),
                  _buildDetailCard(locale.translate('status'), ticket.status, Icons.info),
                  
                  if (ticket.buyerName != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(locale.translate('buyer_name'), ticket.buyerName!, Icons.person),
                  ],
                  
                  if (ticket.buyerPhone != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(locale.translate('buyer_phone'), ticket.buyerPhone!, Icons.phone),
                  ],
                  
                  if (ticket.department != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(locale.translate('department'), ticket.department!, Icons.location_on),
                  ],

                  if (ticket.soldAt != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      locale.translate('purchase_date'),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(locale.translate('qr_coming_soon')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code),
                          label: Text(locale.translate('show_qr')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: Text(locale.translate('close')),
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
