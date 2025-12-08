import 'package:flutter/material.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';

/// Settings Page
/// 
/// Full-screen settings page where users can:
/// - Manage account settings (password, email, phone)
/// - Configure app settings (notifications, theme)
/// - Logout
/// - Delete account
/// 
/// Features:
/// - Modern, clean design
/// - Light/Dark mode support
/// - Consistent with app design language
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Account deletion will be implemented when backend is ready
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete account feature coming soon'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            _SettingsGroup(
              title: 'Account',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password feature coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change email feature coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.phone_outlined,
                  title: 'Change Phone',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change phone feature coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // App Settings
            _SettingsGroup(
              title: 'App',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Theme toggle coming soon (currently: ${value ? "Dark" : "Light"})'),
                        ),
                      );
                    },
                  ),
                  isDark: isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _SettingsGroup(
              title: 'About',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of service coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: Colors.red[300]!,
                    width: 1.5,
                  ),
                  foregroundColor: Colors.red[700],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delete Account Button
            Center(
              child: TextButton(
                onPressed: () => _handleDeleteAccount(context),
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isDark;

  const _SettingsGroup({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDark;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final item = ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                )
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );

    // Add divider if not the last item
    return Column(
      children: [
        item,
        if (onTap != null) // Only add divider for tappable items
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
      ],
    );
  }
}

