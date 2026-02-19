import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/seller_provider.dart';
import 'package:raffle_app/widgets/stat_card.dart';

class SellerDetailsScreen extends StatefulWidget {
  final int sellerId;

  const SellerDetailsScreen({Key? key, required this.sellerId})
      : super(key: key);

  @override
  State<SellerDetailsScreen> createState() => _SellerDetailsScreenState();
}

class _SellerDetailsScreenState extends State<SellerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SellerProvider>();
      provider.loadSellerDetails(widget.sellerId);
      provider.loadSellerStatistics(widget.sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Details'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              }
            },
          ),
        ],
      ),
      body: Consumer<SellerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final seller = provider.selectedSeller;
          final stats = provider.sellerStatistics;

          if (seller == null) {
            return const Center(child: Text('Seller not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seller Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: _getStatusColor(seller.status),
                              child: Text(
                                seller.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seller.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(seller.status.toUpperCase()),
                                    backgroundColor: _getStatusColor(seller.status)
                                        .withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildInfoRow('Phone', seller.phone),
                        if (seller.email != null)
                          _buildInfoRow('Email', seller.email!),
                        if (seller.department != null)
                          _buildInfoRow('Department', seller.department!),
                        if (seller.createdAt != null)
                          _buildInfoRow(
                            'Registered',
                            _formatDate(seller.createdAt!),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      value: seller.totalSales.toString(),
                      icon: Icons.sell,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Commission',
                      value: '${seller.commissionEarned.toStringAsFixed(0)} HTG',
                      icon: Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Active Tickets',
                      value: seller.activeTickets.toString(),
                      icon: Icons.confirmation_number,
                      color: Colors.orange,
                    ),
                    if (stats != null)
                      StatCard(
                        title: 'Total Revenue',
                        value: '${stats.totalRevenue.toStringAsFixed(0)} HTG',
                        icon: Icons.attach_money,
                        color: Colors.purple,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                if (seller.status == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveSeller(seller.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve Seller'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _rejectSeller(seller.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject Seller'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Future<void> _approveSeller(int sellerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Seller'),
        content: const Text('Are you sure you want to approve this seller?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SellerProvider>();
      final success = await provider.approveSeller(sellerId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller approved successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to approve seller')),
          );
        }
      }
    }
  }

  Future<void> _rejectSeller(int sellerId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Seller'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter reason...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty && mounted) {
      final provider = context.read<SellerProvider>();
      final success = await provider.rejectSeller(sellerId, reason);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller rejected')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to reject seller')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Seller'),
        content: const Text(
          'Are you sure you want to delete this seller? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SellerProvider>();
      final success = await provider.deleteSeller(widget.sellerId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seller deleted successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to delete seller')),
          );
        }
      }
    }
  }
}
