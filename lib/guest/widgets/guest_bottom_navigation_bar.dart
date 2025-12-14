import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Guest-specific bottom navigation bar - completely isolated from main app navigation
/// This ensures guest UI navigation doesn't interfere with authenticated user navigation
/// Handles navigation between guest screens (home, search, notifications, profile)
class GuestBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GuestBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Always use white background - guest UI ignores dark mode
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4DAEDB),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        iconSize: 24,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/home_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/home_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/search_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/search_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: _GuestNavIcon(
                assetPath: 'assets/icons/navbar/add_outlined.svg',
                isSelected: false,
              ),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: _GuestNavIcon(
                assetPath: 'assets/icons/navbar/add_filled.svg',
                isSelected: true,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/notifications_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/notifications_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/profile_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _GuestNavIcon(
              assetPath: 'assets/icons/navbar/profile_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}

/// Guest-specific navigation icon widget - isolated from main app
/// Always uses light mode colors (guest UI ignores dark mode)
class _GuestNavIcon extends StatelessWidget {
  final String assetPath;
  final bool isSelected;

  const _GuestNavIcon({
    required this.assetPath,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Selected icons use theme color, unselected icons use grey (always light mode)
    final iconColor = isSelected 
        ? const Color(0xFF4DAEDB)
        : Colors.grey;
    
    return SvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        iconColor,
        BlendMode.srcIn,
      ),
    );
  }
}
