import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/seller_provider.dart';
import 'package:raffle_app/screens/admin/seller_details_screen.dart';

class SellerListScreen extends StatefulWidget {
  const SellerListScreen({Key? key}) : super(key: key);

  @override
  State<SellerListScreen> createState() => _SellerListScreenState();
}

class _SellerListScreenState extends State<SellerListScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProvider>().loadSellers();
    });
  }

  Future<void> _refreshSellers() async {
    await context.read<SellerProvider>().loadSellers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sellers'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Sellers')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: Consumer<SellerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
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
                    onPressed: _refreshSellers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final sellers = _filterStatus == 'all'
              ? provider.sellers
              : provider.sellers
                  .where((s) => s.status == _filterStatus)
                  .toList();

          if (sellers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No sellers found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshSellers,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sellers.length,
              itemBuilder: (context, index) {
                final seller = sellers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(seller.status),
                      child: Text(
                        seller.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      seller.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(seller.phone),
                        if (seller.department != null)
                          Text('Dept: ${seller.department}'),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            seller.status.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getStatusColor(seller.status)
                              .withOpacity(0.2),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${seller.totalSales} sales',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${seller.commissionEarned.toStringAsFixed(2)} HTG',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SellerDetailsScreen(sellerId: seller.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
