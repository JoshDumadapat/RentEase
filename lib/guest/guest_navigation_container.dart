import 'package:flutter/material.dart';
import 'package:rentease_app/guest/guest_home_page.dart';
import 'package:rentease_app/guest/guest_search_page.dart';
import 'package:rentease_app/guest/guest_notifications_page.dart';
import 'package:rentease_app/guest/guest_profile_page.dart';
import 'package:rentease_app/guest/widgets/guest_bottom_navigation_bar.dart';
import 'package:rentease_app/guest/widgets/sign_in_required_modal.dart';

/// COMPLETELY ISOLATED GUEST NAVIGATION CONTAINER
/// This manages all guest screens with proper navigation state
/// Completely separate from MainApp to prevent any navigation bugs
class GuestNavigationContainer extends StatefulWidget {
  const GuestNavigationContainer({super.key});

  @override
  State<GuestNavigationContainer> createState() => _GuestNavigationContainerState();
}

class _GuestNavigationContainerState extends State<GuestNavigationContainer> {
  // Guest navigation index - completely isolated from MainApp
  int _guestNavIndex = 0;

  // Guest screens - completely isolated from main app screens
  final List<Widget> _guestPages = [
    const GuestHomePage(),
    const GuestSearchPage(),
    const SizedBox.shrink(), // Placeholder for Add Post (will show modal instead)
    const GuestNotificationsPage(),
    const GuestProfilePage(),
  ];

  void _onGuestNavTap(int index) {
    // If Add Post button (index 2) is tapped, show modal instead
    if (index == 2) {
      SignInRequiredModal.show(
        context,
        message: 'Sign up to create a post',
      );
      // Don't change the current index, keep the previous tab selected
      return;
    }

    // For other tabs, navigate normally
    if (index != _guestNavIndex) {
      // CRITICAL: Do NOT use popUntil - IndexedStack handles tab switching
      // Each tab maintains its own navigation stack independently
      // Just update the index to switch tabs
      setState(() {
        _guestNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _guestNavIndex,
        children: _guestPages,
      ),
      bottomNavigationBar: GuestBottomNavigationBar(
        currentIndex: _guestNavIndex,
        onTap: _onGuestNavTap,
      ),
    );
  }
}
