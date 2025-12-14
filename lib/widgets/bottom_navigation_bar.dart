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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final unselectedIconColor = isDark ? Colors.white : Colors.grey;
    final shadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.08);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
        backgroundColor: backgroundColor,
        selectedItemColor: const Color(0xFF4DAEDB),
        unselectedItemColor: unselectedIconColor,
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
              isDark: isDark,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/home_filled.svg',
              isSelected: true,
              isDark: isDark,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/search_outlined.svg',
              isSelected: false,
              isDark: isDark,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/search_filled.svg',
              isSelected: true,
              isDark: isDark,
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
              child: _NavIcon(
                assetPath: 'assets/icons/navbar/add_outlined.svg',
                isSelected: false,
                isDark: isDark,
              ),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: _NavIcon(
                assetPath: 'assets/icons/navbar/add_filled.svg',
                isSelected: true,
                isDark: isDark,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/notifications_outlined.svg',
              isSelected: false,
              isDark: isDark,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/notifications_filled.svg',
              isSelected: true,
              isDark: isDark,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(
              assetPath: 'assets/icons/navbar/profile_outlined.svg',
              isSelected: false,
              isDark: isDark,
            ),
            activeIcon: _NavIcon(
              assetPath: 'assets/icons/navbar/profile_filled.svg',
              isSelected: true,
              isDark: isDark,
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
  final bool isDark;

  const _NavIcon({
    required this.assetPath,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Selected icons always use the theme color
    // Unselected icons: white in dark mode, grey in light mode
    final iconColor = isSelected 
        ? const Color(0xFF4DAEDB)
        : (isDark ? Colors.white : Colors.grey);
    
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
