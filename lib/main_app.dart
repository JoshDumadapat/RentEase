import 'package:flutter/material.dart';
import 'package:rentease_app/screens/home/home_page.dart';
import 'package:rentease_app/screens/search/search_page.dart';
import 'package:rentease_app/screens/add_property/add_property_page.dart';
import 'package:rentease_app/screens/notifications/notifications_page.dart';
import 'package:rentease_app/screens/profile/profile_page.dart';
import 'package:rentease_app/widgets/bottom_navigation_bar.dart';

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
    const AddPropertyPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  void _onNavTap(int index) {
    if (index != _currentBottomNavIndex) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {
        _currentBottomNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

