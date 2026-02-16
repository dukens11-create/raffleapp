import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/scratch/ticket_gallery_screen.dart';
import 'config/app_theme.dart';

/// Standalone entry point for Scratch Tickets app
/// This allows the scratch tickets feature to run independently
void main() {
  runApp(const ScratchTicketsApp());
}

class ScratchTicketsApp extends StatelessWidget {
  const ScratchTicketsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: MaterialApp(
        title: 'Grate Genyen - Scratch Tickets',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const TicketGalleryScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
