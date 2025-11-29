import 'package:flutter/material.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/notifications/notifications_page.dart';
import 'package:rentease_app/screens/profile/widgets/user_info_section.dart';
import 'package:rentease_app/screens/profile/widgets/user_stats_section.dart';
import 'package:rentease_app/screens/profile/widgets/property_list_section.dart';
import 'package:rentease_app/screens/profile/widgets/favorites_section.dart';
import 'package:rentease_app/screens/profile/widgets/settings_section.dart';

/// Profile Page
/// 
/// Main profile screen where users can:
/// - View and edit their account information
/// - See their properties and favorites
/// - Access notifications shortcut
/// - Manage account settings
/// - Logout
/// 
/// Features:
/// - Pull-to-refresh
/// - Modern, minimal design
/// - Light/Dark mode support
/// - Responsive layout
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  List<ListingModel> _userProperties = [];
  List<ListingModel> _favorites = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load user profile data
  /// In production, this would fetch from API
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Load mock data
    final allListings = ListingModel.getMockListings();
    
    setState(() {
      _user = UserModel.getMockUser();
      // Get user's properties (mock: first 3 listings)
      _userProperties = allListings.take(3).toList();
      // Get favorites (mock: last 2 listings)
      _favorites = allListings.skip(4).take(2).toList();
      _isLoading = false;
    });
  }

  /// Refresh profile data (pull-to-refresh)
  Future<void> _refreshProfile() async {
    await _loadProfileData();
  }

  /// Navigate to property details
  void _navigateToProperty(ListingModel listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsPage(listing: listing),
      ),
    );
  }

  /// Navigate to notifications page
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }

  /// Handle edit profile action
  void _handleEditProfile() {
    // Note: Navigation to edit profile page will be implemented when backend is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon')),
    );
  }

  /// Handle logout action
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Note: Actual logout logic will be implemented when authentication is integrated
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  /// Handle settings action
  void _handleSettings() {
    // Note: Navigation to settings page will be implemented when needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: _isLoading && _user == null
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Failed to load profile'))
              : RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // App Bar
                      SliverAppBar(
                        expandedHeight: 0,
                        floating: true,
                        pinned: true,
                        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                        elevation: 0,
                        title: const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        centerTitle: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            color: Colors.black87,
                            onPressed: _handleSettings,
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                      
                      // Profile Content
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Info Section
                            UserInfoSection(
                              user: _user!,
                              onEditProfile: _handleEditProfile,
                            ),
                        
                        const SizedBox(height: 24),
                        
                            // User Stats Section
                            UserStatsSection(
                              user: _user!,
                              onNotificationsTap: _navigateToNotifications,
                            ),
                        
                        const SizedBox(height: 32),
                        
                        // My Properties Section
                        PropertyListSection(
                          properties: _userProperties,
                          onPropertyTap: _navigateToProperty,
                          onAddProperty: () {
                            // Note: Navigation to add property page - feature available in bottom nav
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add property feature available in bottom nav'),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Favorites Section
                        FavoritesSection(
                          favorites: _favorites,
                          onPropertyTap: _navigateToProperty,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Settings & Account Management
                        SettingsSection(
                          onLogout: _handleLogout,
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

