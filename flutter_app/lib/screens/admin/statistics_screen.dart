import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/statistics_provider.dart';
import 'package:raffle_app/widgets/stat_card.dart';
import 'package:raffle_app/widgets/charts/category_pie_chart.dart';
import 'package:raffle_app/widgets/charts/department_bar_chart.dart';
import 'package:raffle_app/widgets/charts/seller_leaderboard.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  Future<void> _refreshStatistics() async {
    await context.read<StatisticsProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show date range filter dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatistics,
          ),
        ],
      ),
      body: Consumer<StatisticsProvider>(
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
                  Text(
                    'Error loading statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshStatistics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
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
            onRefresh: _refreshStatistics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  Text(
                    'Overview',
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
                        title: 'Total Tickets',
                        value: stats.totalTickets.toString(),
                        icon: Icons.confirmation_number,
                        color: Colors.blue,
                        subtitle: '${stats.totalAvailable} available',
                      ),
                      StatCard(
                        title: 'Total Sold',
                        value: stats.totalSold.toString(),
                        icon: Icons.sell,
                        color: Colors.green,
                      ),
                      StatCard(
                        title: 'Total Revenue',
                        value: '${stats.totalRevenue.toStringAsFixed(0)} HTG',
                        icon: Icons.attach_money,
                        color: Colors.purple,
                      ),
                      StatCard(
                        title: 'Active Raffles',
                        value: stats.activeRaffles.toString(),
                        icon: Icons.casino,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sales by Category
                  Text(
                    'Sales by Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CategoryPieChart(
                        categoryStats: stats.categoryStats,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Department Performance
                  if (stats.departmentStats.isNotEmpty) ...[
                    Text(
                      'Department Performance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DepartmentBarChart(
                          departmentStats: stats.departmentStats,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Top Sellers
                  if (stats.sellerStats.isNotEmpty) ...[
                    Text(
                      'Top Sellers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SellerLeaderboard(
                      sellerStats: stats.sellerStats,
                      maxItems: 10,
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
}
