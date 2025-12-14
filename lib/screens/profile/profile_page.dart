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
import 'package:rentease_app/screens/profile/widgets/date_filter_sheet.dart' show DateFilterOption, DateFilterSheet;
import 'package:rentease_app/screens/profile/widgets/profile_skeleton.dart';
import 'package:rentease_app/screens/add_property/add_property_page.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/screens/profile/share_profile_qr_page.dart';
import 'package:rentease_app/screens/profile/edit_profile_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/admin/admin_dashboard_page.dart';

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
  final String? userId; // Optional: if provided, view that user's profile instead of current user
  
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  List<ListingModel> _userProperties = [];
  List<ListingModel> _allUserProperties = []; // Store original unfiltered list
  List<ListingModel> _favorites = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String _selectedTab = 'properties'; // 'properties' or 'favorites'
  bool _isAdmin = false;
  
  // Filter state
  DateFilterOption? _currentFilter;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminAuthUtils.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
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

    // Add minimum delay to show skeleton (only if data loads quickly)
    final loadStart = DateTime.now();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final targetUserId = widget.userId ?? firebaseUser?.uid;
      
      if (targetUserId == null) {
        setState(() {
          _user = null;
          _isLoading = false;
        });
        return;
      }

      // Get user data from Firestore
      final userService = BUserService();
      final userData = await userService.getUserData(targetUserId);

      // Get user's listings
      final listingService = BListingService();
      final listingsData = await listingService.getListingsByUser(targetUserId);

      // Get user's favorites (only if viewing own profile)
      final favoritesData = widget.userId == null 
          ? await listingService.getUserFavorites(targetUserId)
          : <Map<String, dynamic>>[];

      // Build UserModel from Firestore data
      UserModel? user;
      if (userData != null) {
        // Debug: Log username from Firestore
        debugPrint('🔍 [ProfilePage] Fetched userData username: ${userData['username']}');
        
        user = UserModel.fromFirestore(userData, targetUserId);
        
        // Debug: Log parsed username
        debugPrint('🔍 [ProfilePage] Parsed UserModel username: ${user.username}');
        
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
        final displayName = firebaseUser?.displayName ?? 
            (userData != null ? '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}'.trim() : null) ??
            firebaseUser?.email?.split('@')[0] ?? 'User';
        
        user = UserModel(
          id: targetUserId,
          email: userData?['email'] as String? ?? firebaseUser?.email ?? '',
          displayName: displayName,
          phone: userData?['phone'] as String?,
          profileImageUrl: userData?['profileImageUrl'] as String? ?? firebaseUser?.photoURL,
          joinedDate: userData?['createdAt'] != null 
              ? (userData!['createdAt'] as Timestamp).toDate()
              : firebaseUser?.metadata.creationTime,
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
        user = user.copyWith(
          profileImageUrl: user.profileImageUrl ?? firebaseUser?.photoURL,
          joinedDate: joinedDate ?? user.joinedDate,
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

      // Ensure minimum skeleton display time (600ms) for smooth UX
      final loadDuration = DateTime.now().difference(loadStart);
      final minDelay = const Duration(milliseconds: 600);
      if (loadDuration < minDelay) {
        await Future.delayed(minDelay - loadDuration);
      }

      if (mounted) {
        setState(() {
          _user = user;
          _allUserProperties = userProperties; // Store original list
          _userProperties = userProperties; // Display list (will be filtered)
          _favorites = favorites;
          _isLoading = false;
        });
        // Apply current filter if any
        if (_currentFilter != null) {
          _applyFilter(_currentFilter, _filterFromDate, _filterToDate);
        }
      }
    } catch (_) {
      // Ensure minimum skeleton display time even on error
      final loadDuration = DateTime.now().difference(loadStart);
      final minDelay = const Duration(milliseconds: 600);
      if (loadDuration < minDelay) {
        await Future.delayed(minDelay - loadDuration);
      }

      if (mounted) {
        setState(() {
          _user = null;
          _allUserProperties = [];
          _userProperties = [];
          _favorites = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh profile data (pull-to-refresh)
  Future<void> _refreshProfile() async {
    await _loadProfileData();
  }

  /// Apply date filter to properties list
  void _applyFilter(DateFilterOption? filter, DateTime? fromDate, DateTime? toDate) {
    if (filter == null || filter == DateFilterOption.all) {
      setState(() {
        _userProperties = List.from(_allUserProperties);
        _currentFilter = null;
        _filterFromDate = null;
        _filterToDate = null;
      });
      return;
    }

    final now = DateTime.now();
    DateTime? filterStart;
    DateTime? filterEnd;

    switch (filter) {
      case DateFilterOption.today:
        filterStart = DateTime(now.year, now.month, now.day);
        filterEnd = now;
        break;
      case DateFilterOption.lastWeek:
        filterStart = now.subtract(const Duration(days: 7));
        filterEnd = now;
        break;
      case DateFilterOption.specificDate:
        if (fromDate != null) {
          filterStart = DateTime(fromDate.year, fromDate.month, fromDate.day);
        }
        if (toDate != null) {
          filterEnd = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
        } else if (fromDate != null) {
          // If only fromDate is set, filter for that single day
          filterEnd = DateTime(fromDate.year, fromDate.month, fromDate.day, 23, 59, 59);
        }
        break;
      case DateFilterOption.all:
        // Already handled above
        break;
    }

    setState(() {
      _currentFilter = filter;
      _filterFromDate = fromDate;
      _filterToDate = toDate;

      if (filterStart == null && filterEnd == null) {
        _userProperties = List.from(_allUserProperties);
      } else {
        _userProperties = _allUserProperties.where((property) {
          final propertyDate = property.postedDate;
          
          if (filterStart != null && filterEnd != null) {
            return propertyDate.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
                   propertyDate.isBefore(filterEnd.add(const Duration(seconds: 1)));
          } else if (filterStart != null) {
            return propertyDate.isAfter(filterStart.subtract(const Duration(seconds: 1)));
          } else if (filterEnd != null) {
            return propertyDate.isBefore(filterEnd.add(const Duration(seconds: 1)));
          }
          
          return true;
        }).toList();
      }
    });
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
  Future<void> _handleEditProfile() async {
    if (_user == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _user!),
      ),
    );
    
    // Refresh profile if edit was successful
    if (result == true) {
      _loadProfileData();
    }
  }

  /// Handle share profile action
  void _handleShareProfile() {
    if (_user == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareProfileQRPage(user: _user!),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show skeleton only during initial loading
    if (_isLoading && _user == null) {
      return ProfileSkeleton(isDark: isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: _user == null
          ? Center(
              child: Text(
                'Failed to load profile',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            )
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
                        scrolledUnderElevation: 0,
                        surfaceTintColor: Colors.transparent,
                        title: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        centerTitle: false,
                        actions: [
                          if (_isAdmin)
                            IconButton(
                              icon: const Icon(Icons.admin_panel_settings),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminDashboardPage(),
                                  ),
                                );
                              },
                              tooltip: 'Admin Dashboard',
                            ),
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
                              onShareProfile: _handleShareProfile,
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
                                      initialFilter: _currentFilter,
                                      initialFromDate: _filterFromDate,
                                      initialToDate: _filterToDate,
                                      onFilterSelected: (filter, fromDate, toDate) {
                                        _applyFilter(filter, fromDate, toDate);
                                        
                                        // Show feedback message
                                        String message = 'Filter applied: ';
                                        switch (filter) {
                                          case DateFilterOption.all:
                                            message += 'All Time';
                                            break;
                                          case DateFilterOption.today:
                                            message += 'Today';
                                            break;
                                          case DateFilterOption.lastWeek:
                                            message += 'Last Week';
                                            break;
                                          case DateFilterOption.specificDate:
                                            if (fromDate != null && toDate != null) {
                                              message += '${fromDate.day}/${fromDate.month}/${fromDate.year} - ${toDate.day}/${toDate.month}/${toDate.year}';
                                            } else if (fromDate != null) {
                                              message += '${fromDate.day}/${fromDate.month}/${fromDate.year}';
                                            } else {
                                              message += 'Custom Date Range';
                                            }
                                            break;
                                          case null:
                                            message += 'All Time';
                                            break;
                                        }
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBarUtils.buildThemedSnackBar(
                                            context,
                                            message,
                                            duration: const Duration(seconds: 2),
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

