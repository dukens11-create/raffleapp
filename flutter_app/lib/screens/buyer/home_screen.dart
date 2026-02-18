import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/loading_indicator.dart';
import 'tickets_list_screen.dart';
import 'my_tickets_screen.dart';
import 'payment_screen.dart';
import 'qr_scanner_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load raffle info when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RaffleProvider>().loadRaffleInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          TicketsListScreen(),
          MyTicketsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Akèy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tikè',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Achte',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grate Genyen'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RaffleProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<RaffleProvider>(
        builder: (context, raffleProvider, child) {
          if (raffleProvider.isLoading && !raffleProvider.hasData) {
            return const LoadingIndicator(message: 'Chajman enfòmasyon...');
          }

          if (raffleProvider.error != null && !raffleProvider.hasData) {
            return ErrorDisplay(
              error: raffleProvider.error!,
              onRetry: () => raffleProvider.refresh(),
            );
          }

          final raffleInfo = raffleProvider.raffleInfo;
          if (raffleInfo == null) {
            return const EmptyState(
              icon: Icons.inbox,
              title: 'Pa gen tiraj aktif',
              subtitle: 'Tanpri, retounen pi ta',
            );
          }

          return RefreshIndicator(
            onRefresh: () => raffleProvider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner with Raffle Info
                  _buildWelcomeBanner(context, raffleInfo),
                  const SizedBox(height: 24),

                  // Statistics
                  _buildStatistics(raffleInfo),
                  const SizedBox(height: 24),

                  // Ticket Categories
                  const Text(
                    'Kategori Tikè Disponib',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCategoriesGrid(context, raffleInfo),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, raffleInfo) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Byenvini nan Grate Genyen!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            raffleInfo.raffle.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (raffleInfo.raffle.description != null) ...[
            const SizedBox(height: 4),
            Text(
              raffleInfo.raffle.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Tiraj: ${_formatDate(raffleInfo.raffle.drawDate)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(raffleInfo) {
    final stats = raffleInfo.stats;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Tikè',
            stats.totalTickets.toString(),
            Icons.confirmation_number,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Disponib',
            stats.availableTickets.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Vandi',
            stats.soldTickets.toString(),
            Icons.shopping_cart,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, raffleInfo) {
    final categories = raffleInfo.categories;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, category) {
    final isAvailable = category.isAvailable;
    final color = _getCategoryColor(category.categoryCode);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isAvailable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      initialCategory: category.categoryCode,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.confirmation_number,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.categoryCode,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.price.toStringAsFixed(0)} HTG',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAvailable ? 'Disponib' : 'EPUIZE',
                style: TextStyle(
                  fontSize: 12,
                  color: isAvailable ? Colors.green : Colors.red,
                  fontWeight: isAvailable ? FontWeight.w500 : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksyon Rapid',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          'Achte Tikè',
          'Chwazi epi peye tikè w',
          Icons.shopping_cart,
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'Wè Tikè Mwen',
          'Tcheke tikè ou achte',
          Icons.receipt_long,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyTicketsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'Skane Kòd QR',
          'Verifye tikè ak kòd QR',
          Icons.qr_code_scanner,
          Colors.purple,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QRScannerScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String code) {
    switch (code) {
      case 'ABC':
        return Colors.blue;
      case 'EFG':
        return Colors.purple;
      case 'JKL':
        return Colors.orange;
      case 'XYZ':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
