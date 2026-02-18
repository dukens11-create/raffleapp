import 'package:flutter/material.dart';
import 'tabs/raffle_info_tab.dart';
import 'tabs/purchase_tab.dart';
import 'tabs/my_tickets_tab.dart';
import 'tabs/verify_ticket_tab.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
          ],
        ),
      ),
    );
  }
}
