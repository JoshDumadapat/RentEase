import 'package:flutter/material.dart';
import 'package:rentease_app/guest/guest_navigation_container.dart';

/// Completely isolated Guest App - prevents any interference with MainApp navigation
/// This ensures guest UI is completely separate from authenticated user navigation
/// Uses GuestNavigationContainer to manage all guest screens with proper navigation
class GuestApp extends StatelessWidget {
  const GuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentEase Guest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D1FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      themeMode: ThemeMode.light, // Force light mode always, ignore device dark mode
      home: const GuestNavigationContainer(),
      debugShowCheckedModeBanner: false,
      // Prevent back navigation to previous screens
      builder: (context, child) {
        return PopScope(
          canPop: false, // Prevent back navigation - guest should only exit through sign in
          child: child!,
        );
      },
    );
  }
}
