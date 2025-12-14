import 'package:flutter/material.dart';
import 'package:rentease_app/screens/home/home_page.dart';
import 'package:rentease_app/screens/search/search_page.dart';
import 'package:rentease_app/screens/notifications/notifications_page.dart';
import 'package:rentease_app/screens/profile/profile_page.dart';
import 'package:rentease_app/widgets/bottom_navigation_bar.dart';
import 'package:rentease_app/widgets/post_type_selection_modal.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentBottomNavIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const SizedBox.shrink(), // Placeholder for Add Post (will show modal instead)
    const NotificationsPage(),
    const ProfilePage(),
  ];

  void _onNavTap(int index) {
    // If Add Post button (index 2) is tapped, show modal instead
    if (index == 2) {
      showPostTypeSelectionModal(context);
      // Don't change the current index, keep the previous tab selected
      return;
    }

    // For other tabs, navigate normally
    if (index != _currentBottomNavIndex) {
      // CRITICAL FIX: Do NOT use popUntil((route) => route.isFirst)
      // This was causing navigation to pop back to GuestApp when switching tabs
      // IndexedStack handles tab switching and preserves state independently
      // Each tab maintains its own navigation stack, so we don't need to pop
      // when switching tabs - just update the index
      setState(() {
        _currentBottomNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentBottomNavIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
