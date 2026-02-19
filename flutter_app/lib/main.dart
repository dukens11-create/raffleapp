import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/auth_provider.dart';
import 'package:raffle_app/providers/ticket_provider.dart';
import 'package:raffle_app/providers/raffle_provider.dart';
import 'package:raffle_app/providers/buyer_ticket_provider.dart';
import 'package:raffle_app/providers/payment_provider.dart';
import 'package:raffle_app/providers/my_tickets_provider.dart';
import 'package:raffle_app/providers/cart_provider.dart';
import 'package:raffle_app/providers/statistics_provider.dart';
import 'package:raffle_app/providers/seller_provider.dart';
import 'package:raffle_app/providers/admin_ticket_provider.dart';
import 'package:raffle_app/providers/seller_sales_provider.dart';
import 'package:raffle_app/screens/auth/login_screen.dart';
import 'package:raffle_app/screens/admin/admin_dashboard.dart';
import 'package:raffle_app/screens/seller/seller_dashboard.dart';
import 'package:raffle_app/screens/buyer/buyer_portal.dart';
import 'package:raffle_app/screens/buyer/home_screen.dart';
import 'package:raffle_app/screens/buyer/ticket_selection_screen.dart';
import 'package:raffle_app/screens/buyer/checkout_screen.dart';
import 'package:raffle_app/screens/scratch/ticket_gallery_screen.dart';
import 'package:raffle_app/screens/shared/qr_scanner_screen.dart';
import 'package:raffle_app/screens/payment/payment_method_screen.dart';
import 'package:raffle_app/screens/admin/statistics_screen.dart';
import 'package:raffle_app/screens/admin/seller_list_screen.dart';
import 'package:raffle_app/screens/admin/seller_approval_screen.dart';
import 'package:raffle_app/screens/seller/my_sales_screen.dart';
import 'package:raffle_app/screens/seller/seller_stats_screen.dart';
import 'package:raffle_app/screens/seller/commission_screen.dart';
import 'package:raffle_app/config/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => RaffleProvider()),
        ChangeNotifierProvider(create: (_) => BuyerTicketProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => MyTicketsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => SellerProvider()),
        ChangeNotifierProvider(create: (_) => AdminTicketProvider()),
        ChangeNotifierProvider(create: (_) => SellerSalesProvider()),
      ],
      child: MaterialApp(
        title: 'Grate Genyen',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/seller': (context) => const SellerDashboard(),
          '/buyer': (context) => const BuyerPortal(),
          '/buyer-home': (context) => const BuyerHomeScreen(),
          '/scratch': (context) => const TicketGalleryScreen(),
          // Ticket purchasing flow
          '/tickets/browse': (context) => const TicketSelectionScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/qr-scanner': (context) => const QRScannerScreen(),
          // Admin routes
          '/admin/statistics': (context) => const StatisticsScreen(),
          '/admin/sellers': (context) => const SellerListScreen(),
          '/admin/sellers/approval': (context) => const SellerApprovalScreen(),
          // Seller routes
          '/seller/sales': (context) => const MySalesScreen(),
          '/seller/stats': (context) => const SellerStatsScreen(),
          '/seller/commission': (context) => const CommissionScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }
        
        // Route based on user role
        switch (auth.userRole) {
          case 'admin':
            return const AdminDashboard();
          case 'seller':
            return const SellerDashboard();
          case 'buyer':
            return const BuyerHomeScreen();
          default:
            // For unauthenticated users, show the new buyer home
            return const BuyerHomeScreen();
        }
      },
    );
  }
}
