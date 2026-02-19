import 'package:flutter/material.dart';
import 'package:raffle_app/models/statistics.dart';

class SellerLeaderboard extends StatelessWidget {
  final List<SellerStat> sellerStats;
  final int maxItems;

  const SellerLeaderboard({
    Key? key,
    required this.sellerStats,
    this.maxItems = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sellerStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No seller data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final topSellers = sellerStats.take(maxItems).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topSellers.length,
      itemBuilder: (context, index) {
        final seller = topSellers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              seller.sellerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${seller.ticketsSold} tickets sold'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${seller.revenue.toStringAsFixed(2)} HTG',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Commission: ${seller.commission.toStringAsFixed(2)}',
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
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.orange; // Bronze
      default:
        return Colors.blue;
    }
  }
}
