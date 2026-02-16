import 'package:flutter/material.dart';

class BuyerPortal extends StatefulWidget {
  const BuyerPortal({super.key});

  @override
  State<BuyerPortal> createState() => _BuyerPortalState();
}

class _BuyerPortalState extends State<BuyerPortal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Show cart
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Grate Genyen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Browse and purchase raffle tickets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Featured Raffles Section
            const Text(
              'Available Raffles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Raffle Categories
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildRaffleCard('BASIC', '50 HTG', '5,000 HTG', 'XYZ (1/2)', 'Available Soon', const Color(0xFF10b981)),
                _buildRaffleCard('PREMIUM', '100 HTG', '15,000 HTG', 'EFG', 'Available Soon', const Color(0xFF7c3aed)),
                _buildRaffleCard('BRONZE', '250 HTG', '50,000 HTG', 'EFG (Front 1/2)', 'Available Soon', const Color(0xFFea580c)),
                _buildRaffleCard('SILVER', '500 HTG', '150,000 HTG', 'ABC (Front 1/2)', 'Available Soon', const Color(0xFF94a3b8)),
                _buildRaffleCard('GOLD', '1,000 HTG', '250,000 HTG', 'ABC (Back 1/2)', 'Available Soon', const Color(0xFFf59e0b)),
                _buildRaffleCard('DIAMOND', '5,000 HTG', '1,000,000 HTG', 'EFG (Back 1/2)', 'Available Soon', const Color(0xFF06b6d4)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Verify Ticket Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify Your Ticket',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Check if you\'ve won!'),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Ticket Number',
                        hintText: 'Enter your ticket number',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            // Verify ticket
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'My Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildRaffleCard(String title, String price, String maxPrize, String category, String status, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigate to raffle details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title raffle details')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.confirmation_number, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Max Prize:',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                maxPrize,
                style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
