import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/services/theme_service.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';
import 'package:rentease_app/screens/settings/account_settings_page.dart';
import 'package:rentease_app/screens/settings/privacy_policy_page.dart';
import 'package:rentease_app/screens/settings/terms_of_service_page.dart';
import 'package:rentease_app/dialogs/confirmation_dialog.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/widgets/subscription_promotion_card.dart';
import 'package:rentease_app/screens/subscription/subscription_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (mounted) {
          setState(() {
            _isVerified = userDoc.data()?['isVerified'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showLogoutDialog(context);

    if (!confirmed) return;

    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Logout failed: $e'),
      );
    }
  }

  void _showUserManual() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Manual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ManualSection(
                      title: 'Navigation',
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: [
                        _ManualItem(
                          title: 'Tabs: Listings & Looking For',
                          description:
                              'At the top of the Home page are two tabs:\n'
                              '• Listings – all available rental properties\n'
                              '• Looking For – posts from users searching for a place\n'
                              'Tap a tab to switch and scroll to view items.',
                        ),
                        _ManualItem(
                          title: 'Bottom Navigation Bar',
                          description:
                              'Visible on every page:\n'
                              '• Home – return to Home\n'
                              '• Search – open the Search page\n'
                              '• Add Post – create a listing or "Looking For" request\n'
                              '• Notifications – view alerts\n'
                              '• Profile – access your profile and account options',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ManualSection(
                      title: 'Searching for Properties',
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: [
                        _ManualItem(
                          title: 'Basic Search',
                          description:
                              'Tap Search, type keywords (e.g., "Makati," "2 BR"), and results update automatically. Tap a property to view details.',
                        ),
                        _ManualItem(
                          title: 'Advanced Filters',
                          description:
                              'Tap the Filter icon:\n'
                              '• Set Price Range, Bedrooms, Bathrooms, and Property Type\n'
                              '• Select Amenities (Wi-Fi, Parking, Furnished, etc.)\n'
                              'Tap Apply Filters to update results. Tap Reset to clear all filters.',
                        ),
                        _ManualItem(
                          title: 'Property Details',
                          description:
                              'Tap any property card. Swipe photos left/right; tap a photo to view full screen.\n\n'
                              'Information Displayed:\n'
                              '• Title, description\n'
                              '• Address and location\n'
                              '• Monthly price\n'
                              '• Specs (bedrooms, bathrooms, area)\n'
                              '• Amenities & availability\n'
                              '• Owner information\n'
                              '• Comments section\n\n'
                              'Actions:\n'
                              '• Save to Favorites: tap the heart icon\n'
                              '• Contact Owner: tap Contact Owner, type a message, and send\n'
                              '• Share Listing: tap the Share icon\n'
                              '• Add Comment: type your comment and tap Post',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ManualSection(
                      title: 'Listing a Property',
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: [
                        _ManualItem(
                          title: 'Start',
                          description:
                              'Tap Add Post → List a Property. Fill the 3-step form.',
                        ),
                        _ManualItem(
                          title: 'Step 1 – Basic Info',
                          description:
                              'Enter title, property type, description, bedrooms, bathrooms, and area.',
                        ),
                        _ManualItem(
                          title: 'Step 2 – Photos',
                          description:
                              'Add photos via Camera or Gallery. Upload multiple images, reorder them, and set a cover.',
                        ),
                        _ManualItem(
                          title: 'Step 3 – Price & Location',
                          description:
                              'Enter monthly rent, full address, set the map location, select amenities, choose availability date, and confirm contact info. Tap Publish.\n\n'
                              'Your listing appears under My Properties in your Profile.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ManualSection(
                      title: 'Creating a "Looking For" Post',
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: [
                        _ManualItem(
                          title: 'How to Create',
                          description:
                              'Tap Add Post → Looking For a Place. Provide preferred location, property type, budget range, move-in date, and a short description. Tap Post.\n\n'
                              'Your request appears in the Looking For tab, and landlords can contact you.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ManualSection(
                      title: 'Notifications',
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: [
                        _ManualItem(
                          title: 'Viewing Notifications',
                          description:
                              'Tap the Notifications icon to see:\n'
                              '• New messages\n'
                              '• Responses to your "Looking For" post\n'
                              '• Viewing requests\n'
                              '• Saved property updates\n'
                              '• System notices\n\n'
                              'Tap any notification to open the related page. Pull down to refresh.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ManualSection(
                      title: 'Profile Management',
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: [
                        _ManualItem(
                          title: 'Access Profile',
                          description:
                              'Access via the Profile icon.\n\n'
                              'What You See:\n'
                              '• Profile photo, name, email, phone\n'
                              '• Stats (listed properties, favorites)\n'
                              '• My Properties\n'
                              '• Favorites\n'
                              '• Settings & Logout',
                        ),
                        _ManualItem(
                          title: 'Edit Profile',
                          description: 'Tap Edit Profile, update your info or photo, and tap Save.',
                        ),
                        _ManualItem(
                          title: 'My Properties',
                          description: 'View, edit, and manage your listings.',
                        ),
                        _ManualItem(
                          title: 'Favorites',
                          description:
                              'View saved properties; swipe left to remove or tap the heart on the property details page.',
                        ),
                        _ManualItem(
                          title: 'Logging Out',
                          description: 'Tap Logout → confirm.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      SnackBarUtils.buildThemedSnackBar(context, 'Delete account feature coming soon'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
            // Account Management - Single clickable card
            _AccountManagementCard(
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage(),
                  ),
                );
              },
            ),
            
            // Subscription Promotion Card (only show if not verified)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: (!_isLoading && !_isVerified)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SubscriptionPromotionCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubscriptionPage(),
                            ),
                          );
                        },
                        showDismissButton: false,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 24),
            
            // App Settings
            _SettingsGroup(
              title: 'App Settings',
              isDark: isDark,
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBarUtils.buildThemedSnackBar(context, 'Notification settings coming soon'),
                    );
                  },
                  isDark: isDark,
                ),
                _EnhancedThemeToggle(
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
                  icon: Icons.book_outlined,
                  title: 'User Manual',
                  onTap: () => _showUserManual(),
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServicePage(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
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
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(),
                icon: Icon(
                  Icons.logout,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1.5,
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
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 8,
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
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red[600]
            : (isDark ? Colors.grey[300] : Colors.grey[700]),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? Colors.red[600]
              : (isDark ? Colors.white : Colors.black87),
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

    return item;
  }
}

class _EnhancedThemeToggle extends StatelessWidget {
  final bool isDark;

  const _EnhancedThemeToggle({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDarkMode = themeService.isDarkMode;
        const Color _themeColorDark = Color(0xFF00B8E6);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              themeService.toggleTheme();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? _themeColorDark.withOpacity(0.2)
                          : Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDarkMode
                          ? _themeColorDark
                          : Colors.amber[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDarkMode ? 'Dark mode' : 'Light mode',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDarkMode
                          ? _themeColorDark
                          : Colors.grey[300],
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          left: isDarkMode ? 22 : 2,
                          top: 2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              size: 16,
                              color: isDarkMode ? _themeColorDark : Colors.amber[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountManagementCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AccountManagementCard({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Account Management',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your password, email, phone, and account preferences',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualSection extends StatelessWidget {
  final String title;
  final List<_ManualItem> content;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _ManualSection({
    required this.title,
    required this.content,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        ...content.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _ManualItem {
  final String title;
  final String description;

  _ManualItem({
    required this.title,
    required this.description,
  });
}

