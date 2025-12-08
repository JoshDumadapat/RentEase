import 'package:flutter/material.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';
import 'package:rentease_app/screens/settings/settings_page.dart';

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

  void _handleDarkMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dark mode feature coming soon')),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
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
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black87),
      offset: const Offset(0, 40), // Position right below the three dots
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      color: Colors.grey[50], // Lighter background tone
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'settings',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: 105,
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: Colors.grey[700], size: 18),
                const SizedBox(width: 10),
                const Text('Settings', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'dark_mode',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: 105,
            child: Row(
              children: [
                Icon(Icons.dark_mode_outlined, color: Colors.grey[700], size: 18),
                const SizedBox(width: 10),
                const Text('Dark Mode', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: 105,
            child: Row(
              children: [
                Icon(Icons.logout_outlined, color: Colors.red[700], size: 18),
                const SizedBox(width: 10),
                Text('Logout', style: TextStyle(color: Colors.red[700], fontSize: 14)),
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
            _handleDarkMode(context);
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
    );
  }
}

