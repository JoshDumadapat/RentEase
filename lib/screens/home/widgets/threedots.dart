import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/services/theme_service.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';
import 'package:rentease_app/screens/settings/settings_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

/// Three dots menu widget with dropdown options
class ThreeDotsMenu extends StatelessWidget {
  const ThreeDotsMenu({super.key});

  // Menu action handlers
  void _handleSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Logout',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Logout failed: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;
    
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      offset: const Offset(0, 40), // Position right below the three dots
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      color: isDark ? Colors.grey[800] : Colors.white,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'settings',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: 105,
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: isDark ? Colors.white : Colors.grey[700],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'dark_mode',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Consumer<ThemeService>(
            builder: (context, themeService, child) {
              final isDarkMode = themeService.themeMode == ThemeMode.dark;
              
              return SizedBox(
                width: 140,
                child: Row(
                  children: [
                    // Outline icon matching settings icon style
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        key: ValueKey<bool>(isDarkMode),
                        color: isDark ? Colors.white : Colors.grey[700],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            child: Text(
                              isDarkMode ? 'Light Mode' : 'Dark Mode',
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            child: Text(
                              isDarkMode ? 'Switch to light' : 'Switch to dark',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        PopupMenuDivider(
          height: 1,
          color: isDark ? Colors.grey[700] : Colors.grey[300],
        ),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: 105,
            child: Row(
              children: [
                Icon(
                  Icons.logout_outlined,
                  color: isDark ? Colors.red[300] : Colors.red[700],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: isDark ? Colors.red[300] : Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'settings':
            _handleSettings(context);
            break;
          case 'dark_mode':
            Provider.of<ThemeService>(context, listen: false).toggleTheme();
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
    );
  }
}


