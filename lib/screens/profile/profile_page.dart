import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';
import 'package:rentease_app/screens/add_looking_for_post/add_looking_for_post_screen.dart';
import 'package:rentease_app/screens/profile/widgets/user_info_section.dart';
import 'package:rentease_app/screens/profile/widgets/user_stats_section.dart';
import 'package:rentease_app/screens/profile/widgets/property_list_section.dart';
import 'package:rentease_app/screens/profile/widgets/looking_for_post_list_section.dart';
import 'package:rentease_app/screens/profile/widgets/favorites_section.dart';
import 'package:rentease_app/screens/profile/widgets/property_actions_card.dart';
import 'package:rentease_app/screens/profile/widgets/looking_for_actions_card.dart';
import 'package:rentease_app/screens/profile/widgets/date_filter_sheet.dart' show DateFilterOption, DateFilterSheet;
import 'package:rentease_app/screens/profile/widgets/profile_skeleton.dart';
import 'package:rentease_app/screens/add_property/add_property_page.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/screens/profile/share_profile_qr_page.dart';
import 'package:rentease_app/screens/profile/edit_profile_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/widgets/subscription_promotion_card.dart';
import 'package:rentease_app/screens/subscription/subscription_page.dart';
import 'package:rentease_app/screens/chat/chats_list_page.dart';
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

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  UserModel? _user;
  List<ListingModel> _userProperties = [];
  List<ListingModel> _allUserProperties = []; // Store original unfiltered list
  List<ListingModel> _favorites = [];
  List<LookingForPostModel> _lookingForPosts = [];
  List<LookingForPostModel> _allLookingForPosts = []; // Store original unfiltered list
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String _selectedTab = 'properties'; // 'properties', 'favorites', 'lookingFor', or 'followers'
  bool _isAdmin = false;
  
  // Check if viewing own profile or another user's profile
  bool get _isVisitorView => widget.userId != null;
  
  // Filter state
  DateFilterOption? _currentFilter;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  DateFilterOption? _currentLookingForFilter;
  DateTime? _filterLookingForFromDate;
  DateTime? _filterLookingForToDate;
  
  // Real-time listener for favorites count
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;
  Stream<List<Map<String, dynamic>>>? _favoritesStream;
  
  // Real-time streams for posts and properties
  Stream<List<Map<String, dynamic>>>? _lookingForPostsStream;
  Stream<List<Map<String, dynamic>>>? _propertiesStream;
  
  // Real-time listeners for counts
  StreamSubscription<QuerySnapshot>? _propertiesSubscription;
  StreamSubscription<QuerySnapshot>? _lookingForPostsSubscription;
  
  // Real-time listener for user verification status
  StreamSubscription<DocumentSnapshot>? _userVerificationSubscription;
  
  // Subscription promotion card state
  bool _showSubscriptionCard = true;
  bool _currentUserIsVerified = false; // Track current logged-in user's verification status

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reset tab to properties if viewing another user's profile
    if (widget.userId != null) {
      _selectedTab = 'properties';
    }
    _loadCurrentUserVerificationStatus();
    _loadProfileData();
    _checkAdminStatus();
    // Only setup favorites for own profile
    if (widget.userId == null) {
      _setupFavoritesListener();
      _setupFavoritesStream();
    }
    _setupPropertiesStream();
    _setupLookingForPostsStream();
    _setupPropertiesCountListener();
    _setupLookingForPostsCountListener();
    _setupVerificationStatusListener();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminAuthUtils.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  /// Load current logged-in user's verification status
  Future<void> _loadCurrentUserVerificationStatus() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return;
    }
    
    try {
      final userService = BUserService();
      final userData = await userService.getUserData(firebaseUser.uid);
      if (mounted && userData != null) {
        setState(() {
          _currentUserIsVerified = userData['isVerified'] == true;
        });
      }
    } catch (e) {
      debugPrint('❌ [ProfilePage] Error loading current user verification status: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _favoritesSubscription?.cancel();
    _propertiesSubscription?.cancel();
    _lookingForPostsSubscription?.cancel();
    _userVerificationSubscription?.cancel();
    _favoritesStream = null;
    _propertiesStream = null;
    _lookingForPostsStream = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh profile data when app comes back to foreground
    // This ensures counts update after user favorites items in other screens
    if (state == AppLifecycleState.resumed) {
      _loadProfileData();
    }
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

      // Get user's "Looking For" posts
      final lookingForPostService = BLookingForPostService();
      final lookingForPostsData = await lookingForPostService.getLookingForPostsByUser(targetUserId);

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
        // Use actual verification status from Firestore (no forced verification)
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
          isVerified: userData?['isVerified'] == true, // Use actual verification status from Firestore
        );
      }

      // Convert listings data to ListingModel
      // Use real data from Firestore (no mock data fallback)
      final userProperties = listingsData
          .map((data) => ListingModel.fromMap(data))
          .toList();

      // Convert favorites data to ListingModel
      // Use real data from Firestore (no mock data fallback)
      final favorites = favoritesData
          .map((data) => ListingModel.fromMap(data))
          .toList();

      // Convert "Looking For" posts data to LookingForPostModel
      final lookingForPosts = lookingForPostsData
          .map((data) => LookingForPostModel.fromMap(data))
          .toList();

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
      
      // Use actual verification status from Firestore (no forced verification)

      // Calculate dynamic counts from actual data
      final propertiesCount = userProperties.length;
      final favoritesCount = favorites.length;
      final lookingForPostsCount = lookingForPosts.length;

      // Update user with dynamic counts
      user = user.copyWith(
        propertiesCount: propertiesCount,
        favoritesCount: favoritesCount,
        lookingForPostsCount: lookingForPostsCount,
      );

      // Ensure minimum skeleton display time (600ms) for smooth UX
      final loadDuration = DateTime.now().difference(loadStart);
      final minDelay = const Duration(milliseconds: 600);
      if (loadDuration < minDelay) {
        await Future.delayed(minDelay - loadDuration);
      }

      if (mounted) {
        setState(() {
          _user = user;
          // Only update properties if stream is not available
          // Otherwise, stream will handle real-time updates
          if (_propertiesStream == null) {
            _allUserProperties = userProperties; // Store original list
            _userProperties = userProperties; // Display list (will be filtered)
          }
          // Only update favorites if stream is not available (for other user's profile)
          // Otherwise, stream will handle real-time updates
          if (widget.userId != null || _favoritesStream == null) {
            _favorites = favorites;
          }
          // Always update cached posts initially for fallback
          // Stream will update in real-time, but we need initial data for display
          _allLookingForPosts = lookingForPosts; // Store original list
          _lookingForPosts = lookingForPosts; // Display list (will be filtered)
          _isLoading = false;
        });
        // Re-setup streams if user changed
        _setupFavoritesStream();
        _setupPropertiesStream();
        _setupLookingForPostsStream();
        _setupPropertiesCountListener();
        _setupLookingForPostsCountListener();
        // Apply current filter if any
        if (_currentFilter != null) {
          _applyFilter(_currentFilter, _filterFromDate, _filterToDate);
        }
        if (_currentLookingForFilter != null) {
          _applyLookingForFilter(_currentLookingForFilter, _filterLookingForFromDate, _filterLookingForToDate);
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
          _lookingForPosts = [];
          _allLookingForPosts = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Setup real-time listener for favorites count
  void _setupFavoritesListener() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    // Only listen if viewing own profile
    if (targetUserId == null || widget.userId != null) {
      return;
    }
    
    _favoritesSubscription?.cancel();
    _favoritesSubscription = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: targetUserId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final favoritesCount = snapshot.docs.length;
        setState(() {
          // Update user's favorites count in real-time
          if (_user != null) {
            _user = _user!.copyWith(favoritesCount: favoritesCount);
          }
        });
      }
    }, onError: (error) {
      debugPrint('❌ [ProfilePage] Error listening to favorites count: $error');
    });
  }
  
  /// Setup real-time stream for favorites list
  void _setupFavoritesStream() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    // Only setup stream if viewing own profile
    if (targetUserId == null || widget.userId != null) {
      return;
    }
    
    final listingService = BListingService();
    _favoritesStream = listingService.getUserFavoritesStream(targetUserId);
  }
  
  /// Setup real-time stream for properties list
  void _setupPropertiesStream() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    if (targetUserId == null) {
      return;
    }
    
    final listingService = BListingService();
    _propertiesStream = listingService.getListingsByUserStream(targetUserId);
  }
  
  /// Setup real-time stream for Looking For posts list
  void _setupLookingForPostsStream() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    if (targetUserId == null) {
      return;
    }
    
    try {
      final lookingForPostService = BLookingForPostService();
      _lookingForPostsStream = lookingForPostService.getLookingForPostsByUserStream(targetUserId);
    } catch (e) {
      debugPrint('❌ [ProfilePage] Error setting up Looking For posts stream: $e');
      _lookingForPostsStream = null;
    }
  }
  
  /// Setup real-time listener for properties count
  void _setupPropertiesCountListener() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    if (targetUserId == null) {
      return;
    }
    
    _propertiesSubscription?.cancel();
    _propertiesSubscription = FirebaseFirestore.instance
        .collection('listings')
        .where('userId', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Count only non-draft listings
        final propertiesCount = snapshot.docs
            .where((doc) => doc.data()['isDraft'] == false)
            .length;
        setState(() {
          // Update user's properties count in real-time
          if (_user != null) {
            _user = _user!.copyWith(propertiesCount: propertiesCount);
          }
        });
      }
    }, onError: (error) {
      debugPrint('❌ [ProfilePage] Error listening to properties count: $error');
    });
  }
  
  /// Setup real-time listener for Looking For posts count
  void _setupLookingForPostsCountListener() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    if (targetUserId == null) {
      return;
    }
    
    _lookingForPostsSubscription?.cancel();
    _lookingForPostsSubscription = FirebaseFirestore.instance
        .collection('lookingForPosts')
        .where('userId', isEqualTo: targetUserId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final lookingForPostsCount = snapshot.docs.length;
        setState(() {
          // Update user's Looking For posts count in real-time
          if (_user != null) {
            _user = _user!.copyWith(lookingForPostsCount: lookingForPostsCount);
          }
        });
      }
    }, onError: (error) {
      debugPrint('❌ [ProfilePage] Error listening to Looking For posts count: $error');
    });
  }

  /// Setup real-time listener for user verification status
  /// This updates the verified status immediately when it changes in Firestore
  void _setupVerificationStatusListener() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    // Only listen if viewing own profile
    if (targetUserId == null || widget.userId != null) {
      return;
    }
    
    _userVerificationSubscription?.cancel();
    _userVerificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        final data = snapshot.data();
        final isVerified = data?['isVerified'] as bool? ?? false;
        
        // Update user's verification status in real-time
        if (_user != null && _user!.isVerified != isVerified) {
          setState(() {
            _user = _user!.copyWith(isVerified: isVerified);
            _currentUserIsVerified = isVerified; // Also update current user's verification status
          });
          
          // Show success message if just verified
          if (isVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBarUtils.buildThemedSnackBar(
                context,
                '🎉 Your account is now verified!',
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }, onError: (error) {
      debugPrint('❌ [ProfilePage] Error listening to verification status: $error');
    });
  }

  /// Refresh profile data (pull-to-refresh)
  Future<void> _refreshProfile() async {
    await _loadProfileData();
  }

  /// Apply filter to posts list without setState (for use during build)
  List<LookingForPostModel> _applyFilterToPosts(
    List<LookingForPostModel> posts,
    DateFilterOption? filter,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (filter == null || filter == DateFilterOption.all) {
      return List.from(posts);
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
          filterEnd = DateTime(fromDate.year, fromDate.month, fromDate.day, 23, 59, 59);
        }
        break;
      case DateFilterOption.all:
        return List.from(posts);
    }

    if (filterStart == null && filterEnd == null) {
      return List.from(posts);
    }

    return posts.where((post) {
      final postDate = post.postedDate;
      
      if (filterStart != null && filterEnd != null) {
        return postDate.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
               postDate.isBefore(filterEnd.add(const Duration(seconds: 1)));
      } else if (filterStart != null) {
        return postDate.isAfter(filterStart.subtract(const Duration(seconds: 1)));
      } else if (filterEnd != null) {
        return postDate.isBefore(filterEnd.add(const Duration(seconds: 1)));
      }
      
      return true;
    }).toList();
  }

  /// Apply filter to properties list without setState (for use during build)
  List<ListingModel> _applyFilterToProperties(
    List<ListingModel> properties,
    DateFilterOption? filter,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (filter == null || filter == DateFilterOption.all) {
      return List.from(properties);
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
          filterEnd = DateTime(fromDate.year, fromDate.month, fromDate.day, 23, 59, 59);
        }
        break;
      case DateFilterOption.all:
        return List.from(properties);
    }

    if (filterStart == null && filterEnd == null) {
      return List.from(properties);
    }

    return properties.where((property) {
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

  /// Apply date filter to looking for posts list
  void _applyLookingForFilter(DateFilterOption? filter, DateTime? fromDate, DateTime? toDate) {
    if (filter == null || filter == DateFilterOption.all) {
      setState(() {
        _lookingForPosts = List.from(_allLookingForPosts);
        _currentLookingForFilter = null;
        _filterLookingForFromDate = null;
        _filterLookingForToDate = null;
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
      _currentLookingForFilter = filter;
      _filterLookingForFromDate = fromDate;
      _filterLookingForToDate = toDate;

      if (filterStart == null && filterEnd == null) {
        _lookingForPosts = List.from(_allLookingForPosts);
      } else {
        _lookingForPosts = _allLookingForPosts.where((post) {
          final postDate = post.postedDate;
          
          if (filterStart != null && filterEnd != null) {
            return postDate.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
                   postDate.isBefore(filterEnd.add(const Duration(seconds: 1)));
          } else if (filterStart != null) {
            return postDate.isAfter(filterStart.subtract(const Duration(seconds: 1)));
          } else if (filterEnd != null) {
            return postDate.isBefore(filterEnd.add(const Duration(seconds: 1)));
          }
          
          return true;
        }).toList();
      }
    });
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
  Future<void> _navigateToProperty(ListingModel listing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsPage(listing: listing),
      ),
    );
    // Refresh profile data when returning from details page
    // This ensures counts update if user favorited/unfavorited the property
    if (mounted) {
      await _loadProfileData();
    }
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

  /// Handle edit property action (from My Properties only)
  Future<void> _handleEditProperty(ListingModel listing) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPropertyPage(
          listingId: listing.id,
          listing: listing,
        ),
      ),
    );
    
    // Refresh profile data if property was updated
    if (result != null && mounted) {
      await _loadProfileData();
    }
  }

  /// Navigate to looking for post details
  Future<void> _navigateToLookingForPost(LookingForPostModel post) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => LookingForPostDetailPage(post: post),
      ),
    );
    
    // Refresh profile data when returning from details page
    if (mounted) {
      await _loadProfileData();
    }
  }

  /// Handle edit looking for post action
  Future<void> _handleEditLookingForPost(LookingForPostModel post) async {
    final result = await Navigator.push<LookingForPostModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddLookingForPostScreen(post: post),
      ),
    );
    
    // Refresh profile data if post was updated
    if (result != null && mounted) {
      await _loadProfileData();
    }
  }

  /// Handle delete looking for post action
  Future<void> _handleDeleteLookingForPost(LookingForPostModel post) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Post?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this "Looking For" post?\n\nThis action cannot be undone.',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Delete the post
      final lookingForPostService = BLookingForPostService();
      await lookingForPostService.deleteLookingForPost(post.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Optimistically remove from UI
        setState(() {
          _lookingForPosts.removeWhere((p) => p.id == post.id);
          _allLookingForPosts.removeWhere((p) => p.id == post.id);
          // Update user counts
          if (_user != null) {
            _user = _user!.copyWith(
              lookingForPostsCount: _lookingForPosts.length,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Post deleted successfully',
            duration: const Duration(seconds: 2),
          ),
        );

        // Refresh after a delay to ensure UI consistency
        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            await _loadProfileData();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting post: ${e.toString()}',
          ),
        );
        
        // Refresh to restore UI if deletion failed
        await _loadProfileData();
      }
    }
  }

  /// Build properties section with real-time stream
  Widget _buildPropertiesSection() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    // If no stream available, use static list
    if (targetUserId == null || _propertiesStream == null) {
      return PropertyListSection(
        properties: _userProperties,
        onPropertyTap: _navigateToProperty,
        onEdit: _handleEditProperty,
        onDelete: _handleDeleteProperty,
      );
    }
    
    // Use StreamBuilder for real-time updates
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _propertiesStream,
      builder: (context, snapshot) {
        // Show loading state only on initial load
        if (snapshot.connectionState == ConnectionState.waiting && _userProperties.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Handle errors
        if (snapshot.hasError) {
          debugPrint('❌ [ProfilePage] Error in properties stream: ${snapshot.error}');
          // Fallback to cached properties on error
          return PropertyListSection(
            properties: _userProperties,
            onPropertyTap: _navigateToProperty,
            onEdit: _handleEditProperty,
            onDelete: _handleDeleteProperty,
          );
        }
        
        // Convert stream data to ListingModel list
        final properties = (snapshot.data ?? [])
            .map((data) => ListingModel.fromMap(data))
            .toList();
        
        // Update cached properties for fallback and filtering (without setState during build)
        _allUserProperties = properties;
        
        // Apply current filter if any (without calling setState during build)
        List<ListingModel> filteredProperties = _applyFilterToProperties(properties, _currentFilter, _filterFromDate, _filterToDate);
        
        // Update display list after filtering (without setState during build)
        _userProperties = filteredProperties;
        
        return PropertyListSection(
          properties: filteredProperties,
          onPropertyTap: _navigateToProperty,
          onEdit: _handleEditProperty,
          onDelete: _handleDeleteProperty,
        );
      },
    );
  }
  
  /// Build Looking For posts section with real-time stream
  Widget _buildLookingForPostsSection() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    // If no stream available, use static list
    if (targetUserId == null || _lookingForPostsStream == null) {
      return LookingForPostListSection(
        posts: _lookingForPosts,
        onPostTap: _navigateToLookingForPost,
        onEdit: _handleEditLookingForPost,
        onDelete: _handleDeleteLookingForPost,
      );
    }
    
    // Use StreamBuilder for real-time updates
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _lookingForPostsStream?.handleError((error) {
        debugPrint('❌ [ProfilePage] Stream error caught: $error');
        // Return empty list on error to prevent stream from crashing
        return <Map<String, dynamic>>[];
      }),
      builder: (context, snapshot) {
        // Show loading state only on initial load
        if (snapshot.connectionState == ConnectionState.waiting && _lookingForPosts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Handle errors - if stream fails, disable it and use async loading
        if (snapshot.hasError) {
          debugPrint('❌ [ProfilePage] Error in Looking For posts stream: ${snapshot.error}');
          // Disable stream on error to prevent repeated errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _lookingForPostsStream = null;
              });
            }
          });
          // Fallback to cached posts on error
          return LookingForPostListSection(
            posts: _lookingForPosts,
            onPostTap: _navigateToLookingForPost,
            onEdit: _handleEditLookingForPost,
            onDelete: _handleDeleteLookingForPost,
          );
        }
        
        // Convert stream data to LookingForPostModel list
        final posts = (snapshot.data ?? [])
            .map((data) {
              try {
                return LookingForPostModel.fromMap(data);
              } catch (e) {
                debugPrint('❌ [ProfilePage] Error parsing post: $e, data: $data');
                return null;
              }
            })
            .whereType<LookingForPostModel>()
            .toList();
        
        // Update cached posts for fallback and filtering (without setState during build)
        _allLookingForPosts = posts;
        
        // Apply current filter if any (without calling setState during build)
        List<LookingForPostModel> filteredPosts = _applyFilterToPosts(posts, _currentLookingForFilter, _filterLookingForFromDate, _filterLookingForToDate);
        
        // Update display list after filtering (without setState during build)
        _lookingForPosts = filteredPosts;
        
        return LookingForPostListSection(
          posts: filteredPosts,
          onPostTap: _navigateToLookingForPost,
          onEdit: _handleEditLookingForPost,
          onDelete: _handleDeleteLookingForPost,
        );
      },
    );
  }

  /// Build favorites section with real-time stream
  Widget _buildFavoritesSection() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final targetUserId = widget.userId ?? firebaseUser?.uid;
    
    // If viewing another user's profile or no stream available, use static list
    if (targetUserId == null || widget.userId != null || _favoritesStream == null) {
      return FavoritesSection(
        favorites: _favorites,
        onPropertyTap: _navigateToProperty,
        onFavoriteRemoved: () {
          // Refresh profile data when a favorite is removed
          _loadProfileData();
        },
      );
    }
    
    // Use StreamBuilder for real-time updates
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _favoritesStream,
      builder: (context, snapshot) {
        // Show loading state only on initial load
        if (snapshot.connectionState == ConnectionState.waiting && _favorites.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Handle errors
        if (snapshot.hasError) {
          debugPrint('❌ [ProfilePage] Error in favorites stream: ${snapshot.error}');
          // Fallback to cached favorites on error
          return FavoritesSection(
            favorites: _favorites,
            onPropertyTap: _navigateToProperty,
            onFavoriteRemoved: () {
              _loadProfileData();
            },
          );
        }
        
        // Convert stream data to ListingModel list
        final favorites = (snapshot.data ?? [])
            .map((data) => ListingModel.fromMap(data))
            .toList();
        
        // Update cached favorites for fallback
        _favorites = favorites;
        
        return FavoritesSection(
          favorites: favorites,
          onPropertyTap: _navigateToProperty,
          onFavoriteRemoved: () {
            // Stream will automatically update, no need to reload
          },
        );
      },
    );
  }

  /// Handle delete property action (from My Properties only)
  Future<void> _handleDeleteProperty(ListingModel listing) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Property?',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${listing.title}"?\n\nYou can undo this action for 4 seconds after deletion.',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Get full listing data before deletion (for undo)
    final listingService = BListingService();
    Map<String, dynamic>? listingData;
    try {
      listingData = await listingService.getListing(listing.id);
      if (listingData == null) {
        throw Exception('Listing not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading property data: ${e.toString()}',
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Delete the listing
      await listingService.deleteListing(listing.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Optimistically remove from UI
        setState(() {
          _userProperties.removeWhere((p) => p.id == listing.id);
          _allUserProperties.removeWhere((p) => p.id == listing.id);
          // Update user counts
          if (_user != null) {
            _user = _user!.copyWith(
              propertiesCount: _userProperties.length,
            );
          }
        });

        // Show snackbar with undo button
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Property deleted',
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF00B8E6), // Theme color for undo
              onPressed: () async {
                // Dismiss the snackbar immediately
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                
                // Show loading
                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );
                }

                try {
                  // Restore the listing using the saved data with the same document ID
                  final firestore = FirebaseFirestore.instance;
                  await firestore.collection('listings').doc(listing.id).set(listingData!);

                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    // Refresh profile data to restore the property
                    await _loadProfileData();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBarUtils.buildThemedSnackBar(
                        context,
                        'Property restored',
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBarUtils.buildThemedSnackBar(
                        context,
                        'Error restoring property: ${e.toString()}',
                      ),
                    );
                    
                    // Refresh to update UI even if restore failed
                    await _loadProfileData();
                  }
                }
              },
            ),
          ),
        );

        // Refresh after 4 seconds to ensure UI consistency
        // (This is safe even if undo was pressed, it will just reload the restored data)
        Future.delayed(const Duration(seconds: 4), () async {
          if (mounted) {
            await _loadProfileData();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting property: ${e.toString()}',
          ),
        );
        
        // Refresh to restore UI if deletion failed
        await _loadProfileData();
      }
    }
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
                          Builder(
                            builder: (context) {
                              final theme = Theme.of(context);
                              final isDark = theme.brightness == Brightness.dark;
                              return IconButton(
                                icon: Image.asset(
                                  'assets/chat.png',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.chat_bubble_outline,
                                      size: 22,
                                      color: isDark ? Colors.white : Colors.black87,
                                    );
                                  },
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ChatsListPage(),
                                    ),
                                  );
                                },
                                tooltip: 'Messages',
                              );
                            },
                          ),
                          const SizedBox(width: 2),
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
                              isVisitorView: widget.userId != null, // True if viewing another user's profile
                            ),
                        
                        const SizedBox(height: 16),
                        
                        // Subscription Promotion Card (only show on own profile if current user is NOT verified)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: (_showSubscriptionCard && 
                                  widget.userId == null && // Only show on own profile
                                  _user != null && 
                                  !_currentUserIsVerified) // Check logged-in user's verification status
                              ? Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: SubscriptionPromotionCard(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const SubscriptionPage(),
                                            ),
                                          );
                                        },
                                        onDismiss: () {
                                          setState(() {
                                            _showSubscriptionCard = false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        
                            // User Stats Section
                            UserStatsSection(
                              user: _user!,
                              listingIds: _userProperties.map((p) => p.id).toList(),
                              hideFavorites: widget.userId != null, // Hide favorites for visitors
                              onStatTap: (tab) {
                                // Don't allow visitors to access favorites tab
                                if (widget.userId != null && tab == 'favorites') {
                                  return;
                                }
                                setState(() {
                                  _selectedTab = tab;
                                });
                              },
                            ),
                        
                        const SizedBox(height: 20),
                        
                        // Property Actions Card (only show for Properties tab and own profile)
                        if (_selectedTab == 'properties' && widget.userId == null)
                          PropertyActionsCard(
                            onAddProperty: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddPropertyPage(),
                                ),
                              );
                              
                              // If a listing was published, refresh the profile data
                              if (result != null && mounted) {
                                debugPrint('🔄 [ProfilePage] Listing published, refreshing data...');
                                await _loadProfileData();
                              }
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
                          _buildPropertiesSection(),
                        
                        // Favorites Section (only show when Favorites tab is selected and viewing own profile)
                        if (_selectedTab == 'favorites' && widget.userId == null)
                          _buildFavoritesSection(),
                        
                        // Looking For Posts Actions Card (only show for Looking For tab and own profile)
                        if (_selectedTab == 'lookingFor' && widget.userId == null)
                          LookingForActionsCard(
                            onAddPost: () async {
                              final result = await Navigator.push<LookingForPostModel>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddLookingForPostScreen(),
                                ),
                              );
                              
                              // If a post was created, refresh the profile data
                              if (result != null && mounted) {
                                await _loadProfileData();
                              }
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
                                      initialFilter: _currentLookingForFilter,
                                      initialFromDate: _filterLookingForFromDate,
                                      initialToDate: _filterLookingForToDate,
                                      onFilterSelected: (filter, fromDate, toDate) {
                                        _applyLookingForFilter(filter, fromDate, toDate);
                                        
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
                        
                        if (_selectedTab == 'lookingFor') const SizedBox(height: 20),
                        
                        // Looking For Posts Section (only show when Looking For tab is selected)
                        if (_selectedTab == 'lookingFor')
                          _buildLookingForPostsSection(),
                        
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

