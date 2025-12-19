import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/screens/home/home_page.dart';
import 'package:rentease_app/screens/search/search_page.dart';
import 'package:rentease_app/screens/notifications/notifications_page.dart';
import 'package:rentease_app/screens/profile/profile_page.dart';
import 'package:rentease_app/widgets/bottom_navigation_bar.dart';
import 'package:rentease_app/widgets/post_type_selection_modal.dart';
import 'package:rentease_app/services/notification_service.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentBottomNavIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;
  StreamSubscription<User?>? _authStateSubscription;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const SizedBox.shrink(), // Placeholder for Add Post (will show modal instead)
    const NotificationsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize notification service and set up real-time listener
    _notificationService.initialize();
    _notificationService.addListener(_onNotificationUpdate);
    // Initial update of unread count
    _updateUnreadCount();
    
    // Also listen to auth state changes to reinitialize when user logs in
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        // Reinitialize notification service when user logs in
        _notificationService.initialize();
        _updateUnreadCount();
      } else if (user == null && mounted) {
        // Clear notifications when user logs out
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _notificationService.removeListener(_onNotificationUpdate);
    _notificationService.dispose();
    super.dispose();
  }

  void _onNotificationUpdate() {
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    if (mounted) {
      setState(() {
        _unreadNotificationCount = _notificationService.unreadCount;
      });
    }
  }

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
      
      // If switching TO search tab (index 1), refresh search data to get newly added listings
      if (index == 1 && _currentBottomNavIndex != 1) {
        // SearchPage will refresh when it detects tab change
      }
      
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
        unreadNotificationCount: _unreadNotificationCount,
      ),
    );
  }
}
