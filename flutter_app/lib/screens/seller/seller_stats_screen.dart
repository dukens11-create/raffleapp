import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/seller_sales_provider.dart';
import 'package:raffle_app/widgets/stat_card.dart';

class SellerStatsScreen extends StatefulWidget {
  const SellerStatsScreen({Key? key}) : super(key: key);

  @override
  State<SellerStatsScreen> createState() => _SellerStatsScreenState();
}

class _SellerStatsScreenState extends State<SellerStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerSalesProvider>().loadMyStatistics();
    });
  }

  Future<void> _refresh() async {
    await context.read<SellerSalesProvider>().loadMyStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Consumer<SellerSalesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.statistics == null) {
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

          final stats = provider.statistics;
          if (stats == null) {
            return const Center(child: Text('No statistics available'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview
                  Text(
                    'Performance Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        title: 'Total Sales',
                        value: stats.totalSales.toString(),
                        icon: Icons.sell,
                        color: Colors.blue,
                      ),
                      StatCard(
                        title: 'Revenue',
                        value: '${stats.totalRevenue.toStringAsFixed(0)} HTG',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                      StatCard(
                        title: 'Commission',
                        value: '${stats.totalCommission.toStringAsFixed(0)} HTG',
                        icon: Icons.account_balance_wallet,
                        color: Colors.purple,
                      ),
                      StatCard(
                        title: 'Active Tickets',
                        value: stats.activeTickets.toString(),
                        icon: Icons.confirmation_number,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sales by Category
                  if (stats.categorySales.isNotEmpty) ...[
                    Text(
                      'Sales by Category',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.categorySales.length,
                        itemBuilder: (context, index) {
                          final sale = stats.categorySales[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getCategoryColor(sale.category),
                              child: Text(
                                sale.category.substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(sale.category),
                            subtitle: Text('${sale.count} tickets'),
                            trailing: Text(
                              '${sale.revenue.toStringAsFixed(2)} HTG',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Daily Sales
                  if (stats.dailySales.isNotEmpty) ...[
                    Text(
                      'Recent Daily Sales',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.dailySales.take(7).length,
                        itemBuilder: (context, index) {
                          final sale = stats.dailySales[index];
                          return ListTile(
                            title: Text(_formatDate(sale.date)),
                            subtitle: Text('${sale.count} tickets'),
                            trailing: Text(
                              '${sale.revenue.toStringAsFixed(2)} HTG',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
