import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/auth_provider.dart';
import 'package:raffle_app/providers/ticket_provider.dart';
import 'package:raffle_app/screens/auth/login_screen.dart';
import 'package:raffle_app/screens/admin/admin_dashboard.dart';
import 'package:raffle_app/screens/seller/seller_dashboard.dart';
import 'package:raffle_app/screens/buyer/buyer_portal.dart';
import 'package:raffle_app/screens/scratch/ticket_gallery_screen.dart';
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
          '/scratch': (context) => const TicketGalleryScreen(),
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
          default:
            return const BuyerPortal();
        }
      },
    );
  }
}
