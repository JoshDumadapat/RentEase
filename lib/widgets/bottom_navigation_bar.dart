import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/home_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/home_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/search_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/search_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/add_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/add_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/notifications_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/notifications_filled.svg',
              isSelected: true,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/profile_outlined.svg',
              isSelected: false,
            ),
            activeIcon: _NavIcon(
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

class _NavIcon extends StatelessWidget {
  final String assetPath;
  final bool isSelected;

  const _NavIcon({
    required this.assetPath,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isSelected ? const Color(0xFF4DAEDB) : Colors.grey,
        BlendMode.srcIn,
      ),
    );
  }
}
