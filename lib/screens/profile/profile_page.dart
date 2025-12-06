import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/profile/widgets/user_info_section.dart';
import 'package:rentease_app/screens/profile/widgets/user_stats_section.dart';
import 'package:rentease_app/screens/profile/widgets/property_list_section.dart';
import 'package:rentease_app/screens/profile/widgets/favorites_section.dart';
import 'package:rentease_app/screens/profile/widgets/property_actions_card.dart';
import 'package:rentease_app/screens/profile/widgets/date_filter_sheet.dart';
import 'package:rentease_app/screens/add_property/add_property_page.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';

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
  String _selectedTab = 'properties'; // 'properties' or 'favorites'

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

  /// Load user profile data from Firestore
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        setState(() {
          _user = null;
          _isLoading = false;
        });
        return;
      }

      // Get user data from Firestore
      final userService = BUserService();
      final userData = await userService.getUserData(firebaseUser.uid);

      // Get user's listings
      final listingService = BListingService();
      final listingsData = await listingService.getListingsByUser(firebaseUser.uid);

      // Get user's favorites
      final favoritesData = await listingService.getUserFavorites(firebaseUser.uid);

      // Build UserModel from Firestore data
      UserModel? user;
      if (userData != null) {
        user = UserModel.fromFirestore(userData, firebaseUser.uid);
        // Add sample bio if not present
        if (user.bio == null || user.bio!.isEmpty) {
          user = user.copyWith(
            bio: 'Property owner and real estate enthusiast. Always happy to help!',
          );
        }
        // Add sample verified status if not present
        if (!user.isVerified) {
          user = user.copyWith(
            isVerified: true, // Sample verified status for testing
          );
        }
      } else {
        // Fallback: create UserModel from Firebase Auth data
        final displayName = firebaseUser.displayName ?? 
            (userData != null ? '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}'.trim() : null) ??
            firebaseUser.email?.split('@')[0] ?? 'User';
        
        user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: displayName,
          phone: userData?['phone'] as String?,
          profileImageUrl: userData?['profileImageUrl'] as String? ?? firebaseUser.photoURL,
          joinedDate: firebaseUser.metadata.creationTime,
          bio: 'Property owner and real estate enthusiast. Always happy to help!',
          isVerified: true, // Sample verified status for testing
        );
      }

      // Convert listings data to ListingModel
      // If no properties from Firestore, use sample data for demonstration
      List<ListingModel> userProperties;
      if (listingsData.isEmpty) {
        // Use sample data from mock listings (first 2-3 listings as user properties)
        final mockListings = ListingModel.getMockListings();
        userProperties = mockListings.take(2).toList();
      } else {
        userProperties = listingsData
            .map((data) => ListingModel.fromMap(data))
            .toList();
      }

      // Convert favorites data to ListingModel
      // If no favorites from Firestore, use sample data for demonstration
      List<ListingModel> favorites;
      if (favoritesData.isEmpty) {
        // Use sample data from mock listings (first 3 listings as favorites)
        final mockListings = ListingModel.getMockListings();
        favorites = mockListings.take(3).toList();
      } else {
        favorites = favoritesData
            .map((data) => ListingModel.fromMap(data))
            .toList();
      }

      // Parse joined date
      DateTime? joinedDate;
      if (userData != null && userData['createdAt'] != null) {
        final timestamp = userData['createdAt'];
        if (timestamp is Timestamp) {
          joinedDate = timestamp.toDate();
        }
      }
      // Update user with joined date and ensure photo URL is set
      if (joinedDate != null || user.profileImageUrl == null) {
        user = UserModel(
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          phone: user.phone,
          profileImageUrl: user.profileImageUrl ?? firebaseUser.photoURL,
          joinedDate: joinedDate ?? user.joinedDate,
          bio: user.bio, // Preserve bio
          isVerified: user.isVerified, // Preserve verified status
        );
      }
      
      // Ensure bio is set (add sample bio if still missing)
      if (user.bio == null || user.bio!.isEmpty) {
        user = user.copyWith(
          bio: 'Property owner and real estate enthusiast. Always happy to help!',
        );
      }
      
      // Ensure verified status is set (add sample verified for testing)
      if (!user.isVerified) {
        user = user.copyWith(
          isVerified: true, // Sample verified status for testing
        );
      }

      setState(() {
        _user = user;
        _userProperties = userProperties;
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _user = null;
        _userProperties = [];
        _favorites = [];
        _isLoading = false;
      });
    }
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

  /// Handle edit profile action
  void _handleEditProfile() {
    // Note: Navigation to edit profile page will be implemented when backend is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon')),
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
                          ThreeDotsMenu(),
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
                              onStatTap: (tab) {
                                setState(() {
                                  _selectedTab = tab;
                                });
                              },
                            ),
                        
                        const SizedBox(height: 20),
                        
                        // Property Actions Card (only show for Properties tab)
                        if (_selectedTab == 'properties')
                          PropertyActionsCard(
                            onAddProperty: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddPropertyPage(),
                                ),
                              );
                            },
                            onFilter: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => DraggableScrollableSheet(
                                  initialChildSize: 0.36,
                                  minChildSize: 0.23,
                                  maxChildSize: 0.8,
                                  builder: (context, scrollController) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: DateFilterSheet(
                                      onFilterSelected: (filter, fromDate, toDate) {
                                        // Handle date filter selection
                                        // You can filter the properties list here based on the selected date filter
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Filter applied: ${filter?.toString().split('.').last ?? 'All'}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        
                        if (_selectedTab == 'properties') const SizedBox(height: 20),
                        
                        // My Properties Section (only show when Properties tab is selected)
                        if (_selectedTab == 'properties')
                          PropertyListSection(
                            properties: _userProperties,
                            onPropertyTap: _navigateToProperty,
                          ),
                        
                        // Favorites Section (only show when Favorites tab is selected)
                        if (_selectedTab == 'favorites')
                          FavoritesSection(
                            favorites: _favorites,
                            onPropertyTap: _navigateToProperty,
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

