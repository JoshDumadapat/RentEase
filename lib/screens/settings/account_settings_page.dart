import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/screens/settings/change_password_page.dart';
import 'package:rentease_app/screens/settings/change_email_page.dart';
import 'package:rentease_app/screens/settings/change_phone_page.dart';
import 'package:rentease_app/screens/settings/backup_settings_page.dart';
import 'package:rentease_app/screens/settings/verification_settings_page.dart';
import 'package:rentease_app/screens/settings/delete_account_page.dart';
import 'package:rentease_app/screens/settings/deactivate_account_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            _SettingsGroup(
              title: 'Personal Information',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  ),
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  subtitle: _auth.currentUser?.email ?? 'Not set',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangeEmailPage()),
                  ),
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.phone_outlined,
                  title: 'Change Phone',
                  subtitle: 'Update your phone number',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePhonePage()),
                  ),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security & Backup Section
            _SettingsGroup(
              title: 'Security & Backup',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.backup_outlined,
                  title: 'Backup Settings',
                  subtitle: 'Add backup email and phone',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BackupSettingsPage()),
                  ),
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Verification Settings',
                  subtitle: 'Configure account verification',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerificationSettingsPage()),
                  ),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Account Actions Section
            _SettingsGroup(
              title: 'Account Actions',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.pause_circle_outline,
                  title: 'Deactivate Account',
                  subtitle: 'Temporarily disable your account',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeactivateAccountPage()),
                  ),
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeleteAccountPage()),
                  ),
                  isDark: isDark,
                  isDestructive: true,
                ),
              ],
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
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ] : [
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
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Colors.red[600]
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? Colors.red[600]
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

