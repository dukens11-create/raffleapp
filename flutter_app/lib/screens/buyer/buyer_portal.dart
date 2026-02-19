import 'package:flutter/material.dart';
import 'tabs/raffle_info_tab.dart';
import 'tabs/purchase_tab.dart';
import 'tabs/my_tickets_tab.dart';
import 'tabs/verify_ticket_tab.dart';
import 'buyer_scratch_list_screen.dart';

class BuyerPortal extends StatefulWidget {
  const BuyerPortal({super.key});

  @override
  State<BuyerPortal> createState() => _BuyerPortalState();
}

class _BuyerPortalState extends State<BuyerPortal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    setState(() {
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buyer Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Raffle Info',
            ),
            Tab(
              icon: Icon(Icons.shopping_cart_outlined),
              text: 'Purchase',
            ),
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'My Tickets',
            ),
            Tab(
              icon: Icon(Icons.verified_outlined),
              text: 'Verify',
            ),
            Tab(
              icon: Icon(Icons.casino_outlined),
              text: 'My Scratch Cards',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            RaffleInfoTab(onTabChange: _changeTab),
            const PurchaseTab(),
            const MyTicketsTab(),
            const VerifyTicketTab(),
            _ScratchCardsEntryTab(
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BuyerScratchListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple tab widget that offers a button to navigate to the scratch list screen.
class _ScratchCardsEntryTab extends StatelessWidget {
  final VoidCallback onOpen;
  const _ScratchCardsEntryTab({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎟️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text(
              'Tikè Grate Mwen',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Wè tout tikè grate ou yo epi grate yo pou wè si ou genyen!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Text('🎰', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Ouvri Tikè Grate Mwen',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


