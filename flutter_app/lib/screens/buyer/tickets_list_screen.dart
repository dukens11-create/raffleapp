import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/buyer_ticket_provider.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/raffle_ticket_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/pagination_controls.dart';

class TicketsListScreen extends StatefulWidget {
  final String? initialCategory;

  const TicketsListScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProvider = context.read<BuyerTicketProvider>();
      if (widget.initialCategory != null) {
        ticketProvider.filterByCategory(widget.initialCategory);
      } else {
        ticketProvider.loadTickets();
      }
    });

    // Load more when scrolling to bottom
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final ticketProvider = context.read<BuyerTicketProvider>();
      if (ticketProvider.hasMorePages && !ticketProvider.isLoading) {
        ticketProvider.loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tikè Disponib'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter bar
          _buildCategoryFilter(),

          // Tickets list
          Expanded(
            child: Consumer<BuyerTicketProvider>(
              builder: (context, ticketProvider, child) {
                if (ticketProvider.isLoading && !ticketProvider.hasTickets) {
                  return const LoadingIndicator(message: 'Chajman tikè...');
                }

                if (ticketProvider.error != null && !ticketProvider.hasTickets) {
                  return ErrorDisplay(
                    error: ticketProvider.error!,
                    onRetry: () => ticketProvider.refresh(),
                  );
                }

                if (!ticketProvider.hasTickets) {
                  return const EmptyState(
                    icon: Icons.confirmation_number,
                    title: 'Pa gen tikè disponib',
                    subtitle: 'Tanpri eseye yon lòt kategori',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ticketProvider.refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: ticketProvider.tickets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == ticketProvider.tickets.length) {
                        // Show loading indicator at bottom when loading more
                        if (ticketProvider.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        // Show "end of list" message
                        if (!ticketProvider.hasMorePages) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Ou wè tout tikè yo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final ticket = ticketProvider.tickets[index];
                      return RaffleTicketCard(
                        ticket: ticket,
                        onTap: () {
                          _showTicketDetails(ticket);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Pagination controls
          Consumer<BuyerTicketProvider>(
            builder: (context, ticketProvider, child) {
              if (!ticketProvider.hasTickets) return const SizedBox.shrink();

              return PaginationControls(
                currentPage: ticketProvider.currentPage,
                totalPages: ticketProvider.totalPages,
                isLoading: ticketProvider.isLoading,
                onPreviousPage: () {
                  ticketProvider.loadTickets(
                    page: ticketProvider.currentPage - 1,
                  );
                },
                onNextPage: () {
                  ticketProvider.loadTickets(
                    page: ticketProvider.currentPage + 1,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer2<BuyerTicketProvider, RaffleProvider>(
      builder: (context, ticketProvider, raffleProvider, child) {
        final categories = raffleProvider.raffleInfo?.categories ?? [];
        
        return Container(
          height: 60,
          color: Colors.grey[100],
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              _buildFilterChip(
                context,
                'Tout',
                ticketProvider.selectedCategory == null,
                () => ticketProvider.filterByCategory(null),
              ),
              ...categories.map((category) {
                final isSelected = ticketProvider.selectedCategory == category.categoryCode;
                return _buildFilterChip(
                  context,
                  category.categoryCode,
                  isSelected,
                  () => ticketProvider.filterByCategory(category.categoryCode),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtre Tikè'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chwazi kategori:'),
              const SizedBox(height: 16),
              Consumer<RaffleProvider>(
                builder: (context, raffleProvider, child) {
                  final categories = raffleProvider.raffleInfo?.categories ?? [];
                  return Column(
                    children: [
                      ListTile(
                        title: const Text('Tout Kategori'),
                        onTap: () {
                          context.read<BuyerTicketProvider>().filterByCategory(null);
                          Navigator.pop(context);
                        },
                      ),
                      ...categories.map((category) {
                        return ListTile(
                          title: Text(category.categoryCode),
                          subtitle: Text(category.onlineAvailable > 0 ? 'Disponib' : 'EPUIZE'),
                          onTap: () {
                            context.read<BuyerTicketProvider>()
                                .filterByCategory(category.categoryCode);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fèmen'),
            ),
          ],
        );
      },
    );
  }

  void _showTicketDetails(ticket) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detay Tikè',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Nimewo Tikè', ticket.ticketNumber),
              const SizedBox(height: 12),
              _buildDetailRow('Kategori', ticket.category),
              const SizedBox(height: 12),
              _buildDetailRow('Pri', '${ticket.price.toStringAsFixed(0)} HTG'),
              const SizedBox(height: 12),
              _buildDetailRow('Estati', ticket.status),
              if (ticket.department != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Depatman', ticket.department!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Fèmen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
