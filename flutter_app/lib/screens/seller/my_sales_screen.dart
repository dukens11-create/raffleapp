import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/seller_sales_provider.dart';
import 'package:intl/intl.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({Key? key}) : super(key: key);

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerSalesProvider>().loadMySales();
    });
  }

  Future<void> _refresh() async {
    await context.read<SellerSalesProvider>().loadMySales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
            },
          ),
        ],
      ),
      body: Consumer<SellerSalesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.sales.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error ?? ''),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final sales = provider.sales;

          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No sales yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your sales will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(
                        sale['category'] ?? '',
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Ticket #${sale['ticket_number'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${sale['category'] ?? 'N/A'}'),
                        Text('Buyer: ${sale['buyer_name'] ?? 'N/A'}'),
                        Text(
                          _formatDateTime(sale['sold_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sale['price'] ?? 0} HTG',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (sale['commission'] != null)
                          Text(
                            'Commission: ${sale['commission']} HTG',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'BAS':
        return Colors.blue;
      case 'PRM':
        return Colors.green;
      case 'BRZ':
        return Colors.orange;
      case 'SLV':
        return Colors.grey;
      case 'GLD':
        return Colors.amber;
      case 'DIA':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime.toString());
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (e) {
      return 'N/A';
    }
  }
}
