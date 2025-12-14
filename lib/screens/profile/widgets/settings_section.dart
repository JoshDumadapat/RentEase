import 'package:flutter/material.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

/// Settings Section Widget
/// 
/// Displays account management options:
/// - Account settings (change password, email/phone)
/// - App settings (theme, notifications)
/// - Logout button
/// - Optional: Delete account
class SettingsSection extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsSection({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Account Settings
          _SettingsGroup(
            title: 'Account',
            isDark: isDark,
            items: [
              _SettingsItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // Note: Navigation to change password page will be implemented when backend is ready
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
                  // Note: Navigation to change email page will be implemented when backend is ready
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBarUtils.buildThemedSnackBar(context, 'Change email feature coming soon'),
                  );
                },
                isDark: isDark,
              ),
              _SettingsItem(
                icon: Icons.phone_outlined,
                title: 'Change Phone',
                onTap: () {
                  // Note: Navigation to change phone page will be implemented when backend is ready
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBarUtils.buildThemedSnackBar(context, 'Change phone feature coming soon'),
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
                  // Note: Navigation to notification settings will be implemented when needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBarUtils.buildThemedSnackBar(context, 'Notification settings coming soon'),
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
                    // Note: Theme toggle functionality will be implemented when theme management is added
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBarUtils.buildThemedSnackBar(
                        context,
                        'Theme toggle coming soon (currently: ${value ? "Dark" : "Light"})',
                      ),
                    );
                  },
                ),
                isDark: isDark,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
          
          // Delete Account (Optional)
          Center(
            child: TextButton(
              onPressed: () {
                // Note: Delete account confirmation dialog will be implemented when backend is ready
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBarUtils.buildThemedSnackBar(context, 'Delete account feature coming soon'),
                );
              },
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
        ],
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
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
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
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
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

