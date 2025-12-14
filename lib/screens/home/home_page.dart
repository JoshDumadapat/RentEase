import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:rentease_app/models/category_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/models/comment_model.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/backend/BFavoriteService.dart';
import 'package:rentease_app/backend/BReviewService.dart';
import 'package:rentease_app/backend/BHiddenPostService.dart';
import 'package:rentease_app/backend/BCommentService.dart';
import 'package:rentease_app/screens/posts/posts_page.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';
import 'package:rentease_app/screens/home/widgets/home_skeleton.dart';
import 'package:rentease_app/screens/home/widgets/looking_for_skeleton.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/widgets/ad_card_widget.dart';
import 'package:rentease_app/models/ad_model.dart';
import 'package:rentease_app/screens/chat/chats_list_page.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF); // Light background (like blue[50])
const Color _themeColorLight2 = Color(0xFFB3F0FF); // Light background (like blue[100])
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isLoadingLookingFor = true;
  bool _isFirstTimeUser = true;
  final ScrollController _listingsScrollController = ScrollController();
  final ScrollController _lookingForScrollController = ScrollController();
  static bool _hasAnimatedOnce = false; // Track if animations have been shown

  final List<CategoryModel> _categories = CategoryModel.getMockCategories();
  List<ListingModel> _listings = [];
  List<LookingForPostModel> _lookingForPosts = [];
  
  // Pagination state for listings
  DocumentSnapshot? _lastListingDocument;
  bool _hasMoreListings = true;
  bool _isLoadingMoreListings = false;
  int _listingsPageOffset = 0; // Track how many listings we've already shown
  
  // Pagination state for looking for posts
  DocumentSnapshot? _lastPostDocument;
  bool _hasMorePosts = true;
  bool _isLoadingMorePosts = false;
  
  // Backend services
  final BListingService _listingService = BListingService();
  final BLookingForPostService _lookingForPostService = BLookingForPostService();
  final BReviewService _reviewService = BReviewService();
  final BHiddenPostService _hiddenPostService = BHiddenPostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabControllerChanged);
    _checkFirstTimeUser();
    _setupScrollListeners();
    _loadInitialData();
  }
  
  void _setupScrollListeners() {
    // Listen to scroll position for listings
    _listingsScrollController.addListener(() {
      if (_listingsScrollController.position.pixels >=
          _listingsScrollController.position.maxScrollExtent * 0.8) {
        // Load more when 80% scrolled
        if (!_isLoadingMoreListings && _hasMoreListings) {
          _loadMoreListings();
        }
      }
    });
    
    // Listen to scroll position for looking for posts
    _lookingForScrollController.addListener(() {
      if (_lookingForScrollController.position.pixels >=
          _lookingForScrollController.position.maxScrollExtent * 0.8) {
        // Load more when 80% scrolled
        if (!_isLoadingMorePosts && _hasMorePosts) {
          _loadMoreLookingForPosts();
        }
      }
    });
  }
  
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadInitialListings(),
      _loadInitialLookingForPosts(),
    ]);
  }
  
  Future<void> _loadInitialListings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _listings = []; // Clear old data
        _lastListingDocument = null;
        _hasMoreListings = true;
        _listingsPageOffset = 0; // Reset offset
      });
    }
    
    try {
      final result = await _listingService.getListingsPaginated(
        limit: 12,
        lastDocument: null,
        randomize: true,
      );
      
      final listingsData = result['listings'] as List<Map<String, dynamic>>;
      _lastListingDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMoreListings = result['hasMore'] as bool;
      
      debugPrint('📊 [HomePage] Loaded ${listingsData.length} listings from pagination');
      
      // Convert to ListingModel and fetch ratings
      final listings = await Future.wait(
        listingsData.map((data) async {
          // Fetch actual review count and average rating FIRST, before creating ListingModel
          String listingId = data['id'] as String? ?? '';
          int actualCount = 0;
          double actualAverageRating = 0.0;
          
          try {
            actualCount = await _reviewService.getReviewCount(listingId);
            debugPrint('🔍 [HomePage] Fetching rating for $listingId: reviewCount=$actualCount');
            
            if (actualCount > 0) {
              actualAverageRating = await _reviewService.getAverageRating(listingId);
              debugPrint('✅ [HomePage] Fetched rating for $listingId: $actualAverageRating (from $actualCount reviews)');
            } else {
              debugPrint('📊 [HomePage] No reviews found for $listingId');
            }
          } catch (e, stackTrace) {
            debugPrint('⚠️ [HomePage] Error fetching review data for $listingId: $e');
            debugPrint('📚 Stack trace: $stackTrace');
          }
          
          // Update data map with fetched values BEFORE creating ListingModel
          final updatedData = Map<String, dynamic>.from(data);
          updatedData['reviewCount'] = actualCount;
          updatedData['averageRating'] = actualAverageRating; // Already a double from getAverageRating
          
          debugPrint('🔧 [HomePage] Creating ListingModel for $listingId with: reviewCount=$actualCount, averageRating=$actualAverageRating');
          
          // Create ListingModel with updated data
          final listing = ListingModel.fromMap(updatedData);
          
          // Verify the values were set correctly
          if ((listing.reviewCount != actualCount) || (listing.averageRating - actualAverageRating).abs() > 0.01) {
            debugPrint('⚠️ [HomePage] WARNING: ListingModel values mismatch for $listingId!');
            debugPrint('   Expected: reviewCount=$actualCount, averageRating=$actualAverageRating');
            debugPrint('   Got: reviewCount=${listing.reviewCount}, averageRating=${listing.averageRating}');
          } else {
            debugPrint('✅ [HomePage] Verified listing $listingId: reviewCount=${listing.reviewCount}, averageRating=${listing.averageRating}');
          }
          
          return listing;
        }),
      );
      
      if (mounted) {
        setState(() {
          _listings = listings;
          _isLoading = false;
          _listingsPageOffset = listings.length;
        });
        debugPrint('✅ [HomePage] Set ${listings.length} listings in state. Total listings available: ${listings.length}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [HomePage] Error loading initial listings: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _listings = [];
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreListings() async {
    if (_isLoadingMoreListings || !_hasMoreListings) return;
    
    setState(() {
      _isLoadingMoreListings = true;
    });
    
    try {
      final result = await _listingService.getListingsPaginated(
        limit: 12,
        lastDocument: _lastListingDocument,
        randomize: true,
      );
      
      final listingsData = result['listings'] as List<Map<String, dynamic>>;
      _lastListingDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMoreListings = result['hasMore'] as bool;
      
      // Convert to ListingModel and fetch ratings
      final newListings = await Future.wait(
        listingsData.map((data) async {
          // Fetch actual review count and average rating FIRST, before creating ListingModel
          String listingId = data['id'] as String? ?? '';
          int actualCount = 0;
          double actualAverageRating = 0.0;
          
          try {
            actualCount = await _reviewService.getReviewCount(listingId);
            if (actualCount > 0) {
              actualAverageRating = await _reviewService.getAverageRating(listingId);
            }
          } catch (e) {
            debugPrint('⚠️ [HomePage] Error fetching review data for $listingId: $e');
          }
          
          // Update data map with fetched values BEFORE creating ListingModel
          final updatedData = Map<String, dynamic>.from(data);
          updatedData['reviewCount'] = actualCount;
          updatedData['averageRating'] = actualAverageRating;
          
          // Create ListingModel with updated data
          return ListingModel.fromMap(updatedData);
        }),
      );
      
      if (mounted) {
        setState(() {
          _listings.addAll(newListings);
          _isLoadingMoreListings = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [HomePage] Error loading more listings: $e');
      if (mounted) {
        setState(() {
          _isLoadingMoreListings = false;
        });
      }
    }
  }
  
  Future<void> _loadInitialLookingForPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingLookingFor = true;
        _lookingForPosts = []; // Clear old data
        _lastPostDocument = null;
        _hasMorePosts = true;
      });
    }
    
    try {
      final result = await _lookingForPostService.getLookingForPostsPaginated(
        limit: 12,
        lastDocument: null,
        randomize: true,
      );
      
      final postsData = result['posts'] as List<Map<String, dynamic>>;
      _lastPostDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMorePosts = result['hasMore'] as bool;
      
      // Filter out hidden posts
      final currentUserId = _auth.currentUser?.uid;
      List<LookingForPostModel> posts = postsData
          .map((data) => LookingForPostModel.fromMap(data))
          .toList();
      
      if (currentUserId != null && posts.isNotEmpty) {
        final hiddenPostIds = await _hiddenPostService.getHiddenPostIds(currentUserId);
        posts = posts.where((post) => !hiddenPostIds.contains(post.id)).toList();
      }
      
      if (mounted) {
        setState(() {
          _lookingForPosts = posts;
          _isLoadingLookingFor = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [HomePage] Error loading initial looking for posts: $e');
      if (mounted) {
        setState(() {
          _lookingForPosts = [];
          _isLoadingLookingFor = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreLookingForPosts() async {
    if (_isLoadingMorePosts || !_hasMorePosts) return;
    
    setState(() {
      _isLoadingMorePosts = true;
    });
    
    try {
      final result = await _lookingForPostService.getLookingForPostsPaginated(
        limit: 12,
        lastDocument: _lastPostDocument,
        randomize: true,
      );
      
      final postsData = result['posts'] as List<Map<String, dynamic>>;
      _lastPostDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMorePosts = result['hasMore'] as bool;
      
      // Filter out hidden posts
      final currentUserId = _auth.currentUser?.uid;
      List<LookingForPostModel> newPosts = postsData
          .map((data) => LookingForPostModel.fromMap(data))
          .toList();
      
      if (currentUserId != null && newPosts.isNotEmpty) {
        final hiddenPostIds = await _hiddenPostService.getHiddenPostIds(currentUserId);
        newPosts = newPosts.where((post) => !hiddenPostIds.contains(post.id)).toList();
      }
      
      if (mounted) {
        setState(() {
          _lookingForPosts.addAll(newPosts);
          _isLoadingMorePosts = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [HomePage] Error loading more looking for posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingMorePosts = false;
        });
      }
    }
  }

  void _onTabControllerChanged() {
    // Update UI when tab changes programmatically (e.g., when navigating after adding a post)
    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToTopAndRefresh(int tabIndex) {
    if (tabIndex == 0) {
      // Listings tab - scroll to top and refresh
      if (_listingsScrollController.hasClients) {
        _listingsScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _refreshListings();
    } else if (tabIndex == 1) {
      // Looking For tab - scroll to top and refresh
      if (_lookingForScrollController.hasClients) {
        _lookingForScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _refreshLookingFor();
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time_user') ?? true;
    if (mounted) {
      setState(() {
        _isFirstTimeUser = isFirstTime;
      });
      // Mark as not first-time user after first view
      if (isFirstTime) {
        await prefs.setBool('is_first_time_user', false);
      }
    }
  }

  @override
  bool get wantKeepAlive => true; // Preserve scroll position when navigating away


  // Exposed for children (e.g., post creation screens) to add new content to the top of feeds.
  void addNewListing(ListingModel listing) {
    setState(() {
      _listings.insert(0, listing);
    });
    // Ensure Listings tab is active so the user sees the new post, similar to Facebook.
    _tabController.animateTo(0);
  }

  void addNewLookingForPost(LookingForPostModel post) {
    setState(() {
      _lookingForPosts.insert(0, post);
    });
    _tabController.animateTo(1);
  }

  @override
  void dispose() {
    _listingsScrollController.dispose();
    _lookingForScrollController.dispose();
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final Color unselectedTabColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    
    if (_isLoading) {
      return HomeSkeleton(isDark: isDark, isFirstTimeUser: _isFirstTimeUser);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Fixed App Bar
          AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 200,
            leading: Container(
              padding: const EdgeInsets.only(left: 16.0),
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/sign_in_up/signlogo.png',
                height: 38,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.home, color: _themeColor, size: 32);
                },
              ),
            ),
            actions: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/chat_icon.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : Colors.black87,
                    BlendMode.srcIn,
                  ),
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
              ),
              const SizedBox(width: 4),
              const ThreeDotsMenu(),
              const SizedBox(width: 8),
            ],
          ),
          // Fixed Tabs below App Bar - always visible
          Container(
            color: backgroundColor,
            padding: const EdgeInsets.only(top: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 40,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: _themeColorDark,
                    unselectedLabelColor: unselectedTabColor,
                    indicatorColor: _themeColorDark,
                    indicatorWeight: 2.5,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: const [
                      Tab(text: 'Listings'),
                      Tab(text: 'Looking For'),
                    ],
                    onTap: (index) {
                      // If tapping the already-selected tab, scroll to top and refresh
                      if (index == _tabController.index) {
                        _scrollToTopAndRefresh(index);
                      }
                    },
                  ),
                ),
                // Shadow only at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -8,
                  height: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildListingsTab(), _buildLookingForTab()],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshListings() async {
    // Scroll to top if not already at top
    if (_listingsScrollController.hasClients && _listingsScrollController.offset > 0) {
      await _listingsScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    // Reload initial data
    await _loadInitialListings();
  }

  Widget _buildListingsTab() {
    return _ListingsSection(
      categories: _categories,
      listings: _listings,
      scrollController: _listingsScrollController,
      onRefresh: _refreshListings,
      hasAnimatedOnce: _hasAnimatedOnce,
      isFirstTimeUser: _isFirstTimeUser,
      isLoadingMore: _isLoadingMoreListings,
      hasMore: _hasMoreListings,
      onLoadMore: _loadMoreListings,
    );
  }

  Future<void> _refreshLookingFor() async {
    // Scroll to top if not already at top
    if (_lookingForScrollController.hasClients && _lookingForScrollController.offset > 0) {
      await _lookingForScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    // Reload initial data
    await _loadInitialLookingForPosts();
  }

  Widget _buildLookingForTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_isLoadingLookingFor) {
      return LookingForSkeleton(isDark: isDark);
    }
    return _LookingForSection(
      posts: _lookingForPosts,
      scrollController: _lookingForScrollController,
      onRefresh: _refreshLookingFor,
      isLoadingMore: _isLoadingMorePosts,
      hasMore: _hasMorePosts,
      onLoadMore: _loadMoreLookingForPosts,
    );
  }
}

class _ListingsSection extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<ListingModel> listings;
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final bool hasAnimatedOnce;
  final bool isFirstTimeUser;
  final bool isLoadingMore;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;

  const _ListingsSection({
    required this.categories,
    required this.listings,
    this.scrollController,
    this.onRefresh,
    required this.hasAnimatedOnce,
    required this.isFirstTimeUser,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.onLoadMore,
  });

  @override
  State<_ListingsSection> createState() => _ListingsSectionState();
}

class _ListingsSectionState extends State<_ListingsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve scroll position when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          if (widget.isFirstTimeUser)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: _AnimatedFadeSlide(
                  delay: 0,
                  skipAnimation: widget.hasAnimatedOnce,
                  child: _WelcomeSection(),
                ),
              ),
            ),
          if (widget.isFirstTimeUser)
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (!widget.isFirstTimeUser)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedFadeSlide(
              delay: widget.isFirstTimeUser ? 100 : 0,
              skipAnimation: widget.hasAnimatedOnce,
              child: _FeaturedCategoriesSection(
                categories: widget.categories,
                isFirstTimeUser: widget.isFirstTimeUser,
                onCategoryTap: (category) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostsPage(category: category),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(
            child: _AnimatedFadeSlide(
              delay: 200,
              skipAnimation: widget.hasAnimatedOnce,
              child: _VisitListingsSection(
                listings: widget.listings,
                onListingTap: (listing) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingDetailsPage(listing: listing),
                    ),
                  );
                },
              ),
            ),
          ),
          // Loading more indicator
          if (widget.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          // "Continue to see more" message
          if (!widget.isLoadingMore && widget.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
                child: GestureDetector(
                  onTap: widget.onLoadMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    decoration: BoxDecoration(
                      color: _themeColorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _themeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward, color: _themeColorDark, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Continue to see more',
                          style: TextStyle(
                            color: _themeColorDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to RentEase!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: subtextColor,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Start your '),
              TextSpan(
                text: 'journey',
                style: TextStyle(
                  color: _themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const TextSpan(text: ' by choosing your '),
              TextSpan(
                text: 'property preference.',
                style: TextStyle(
                  color: _themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedCategoriesSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategoryTap;
  final bool isFirstTimeUser;

  const _FeaturedCategoriesSection({
    required this.categories,
    required this.onCategoryTap,
    required this.isFirstTimeUser,
  });

  @override
  Widget build(BuildContext context) {
    final houseRentals = categories.firstWhere(
      (cat) => cat.name == 'House Rentals',
      orElse: () => categories[0],
    );
    final apartments = categories.firstWhere(
      (cat) => cat.name == 'Apartments',
      orElse: () => categories[1],
    );
    final condoRentals = categories.firstWhere(
      (cat) => cat.name == 'Condo Rentals',
      orElse: () => categories[4],
    );
    final rooms = categories.firstWhere(
      (cat) => cat.name == 'Rooms',
      orElse: () => categories[2],
    );
    final boardingHouse = categories.firstWhere(
      (cat) => cat.name == 'Boarding House',
      orElse: () => categories[3],
    );
    final studentDorms = categories.firstWhere(
      (cat) => cat.name == 'Student Dorms',
      orElse: () => categories[5],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedFadeSlide(
              delay: isFirstTimeUser ? 200 : 50,
              skipAnimation: _HomePageState._hasAnimatedOnce,
              child: _LargeCategoryCard(
                category: houseRentals,
                onTap: () => onCategoryTap(houseRentals),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _AnimatedFadeSlide(
                        delay: isFirstTimeUser ? 300 : 100,
                        skipAnimation: _HomePageState._hasAnimatedOnce,
                        child: _TallCategoryCard(
                          category: apartments,
                          onTap: () => onCategoryTap(apartments),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedFadeSlide(
                        delay: isFirstTimeUser ? 400 : 150,
                        skipAnimation: _HomePageState._hasAnimatedOnce,
                        child: _SmallCategoryCard(
                          category: condoRentals,
                          onTap: () => onCategoryTap(condoRentals),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _AnimatedFadeSlide(
                        delay: isFirstTimeUser ? 350 : 120,
                        skipAnimation: _HomePageState._hasAnimatedOnce,
                        child: _SmallCategoryCard(
                          category: rooms,
                          onTap: () => onCategoryTap(rooms),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedFadeSlide(
                        delay: isFirstTimeUser ? 450 : 180,
                        skipAnimation: _HomePageState._hasAnimatedOnce,
                        child: _SmallCategoryCard(
                          category: boardingHouse,
                          onTap: () => onCategoryTap(boardingHouse),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedFadeSlide(
                        delay: isFirstTimeUser ? 500 : 200,
                        skipAnimation: _HomePageState._hasAnimatedOnce,
                        child: _SmallCategoryCard(
                          category: studentDorms,
                          onTap: () => onCategoryTap(studentDorms),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _LargeCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: AssetImage(category.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _themeColorLight2,
                    child: const Center(
                      child: Icon(Icons.home, size: 60, color: _themeColor),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TallCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _TallCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double tallCardHeight = 140 + 12 + 140;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: tallCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: AssetImage(category.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _themeColorLight2,
                    child: const Center(
                      child: Icon(Icons.home, size: 50, color: _themeColor),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _SmallCategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: AssetImage(category.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: _themeColorLight2,
                    child: const Center(
                      child: Icon(Icons.home, size: 40, color: _themeColor),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitListingsSection extends StatelessWidget {
  final List<ListingModel> listings;
  final Function(ListingModel) onListingTap;

  const _VisitListingsSection({
    required this.listings,
    required this.onListingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visit Listings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Listings from Trusted users',
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (listings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.home_outlined, size: 64, color: subtextColor),
                  const SizedBox(height: 16),
                  Text(
                    'No listings available',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new listings',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Builder(
            builder: (context) {
              // Calculate total items including ads (insert ad every 6 listings)
              final int adInterval = 6;
              final int adCount = (listings.length / adInterval).floor();
              final int totalItemCount = listings.length + adCount;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: totalItemCount,
                itemBuilder: (context, index) {
                  // Ads appear after every 6 listings: at positions 6, 13, 20, 27, etc.
                  // Pattern: (index + 1) % 7 == 0 means it's an ad position (after 6 items)
                  final bool isAdPosition = (index + 1) % 7 == 0 && index >= 6;
                  
                  if (isAdPosition) {
                    // Check if we haven't exceeded the maximum number of ads
                    final int adNumber = (index + 1) ~/ 7 - 1;
                    if (adNumber < adCount) {
                      // Rotate through different ads
                      final ad = AdModel.getAdByIndex(adNumber);
                      return AdCardWidget(
                        ad: ad,
                        onTap: () {
                          // Handle ad tap - could navigate to brand URL
                        },
                      );
                    }
                  }
                  
                  // Calculate the actual listing index
                  // Count how many ads appear before this index
                  final int adsBeforeIndex = (index + 1) ~/ 7;
                  final int listingIndex = index - adsBeforeIndex;
                  
                  if (listingIndex >= listings.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final listing = listings[listingIndex];
                  return Padding(
                    key: ValueKey(listing.id),
                    padding: EdgeInsets.only(
                      bottom: index == totalItemCount - 1 ? 0 : 20,
                    ),
                    child: _AnimatedFadeSlide(
                      delay: 400 + (listingIndex * 80), // Staggered animation with more spacing
                      child: _ModernListingCard(
                        listing: listing,
                        onTap: () => onListingTap(listing),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _ModernListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const _ModernListingCard({required this.listing, required this.onTap});

  /// Build image widget that handles both network and asset images
  Widget _buildListingImage(String imagePath) {
    final isNetworkImage = imagePath.startsWith('http://') || 
                           imagePath.startsWith('https://');
    
    if (isNetworkImage) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.grey[400],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          );
        },
      );
    } else {
      // Asset image
      return Image(
        image: AssetImage(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: _themeColor.withValues(alpha: 0.1),
        highlightColor: _themeColor.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: listing.imagePaths.isNotEmpty
                          ? _buildListingImage(listing.imagePaths[0])
                          : Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (listing.imagePaths.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_library,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${listing.imagePaths.length - 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? _themeColorDark.withValues(alpha: 0.25)
                                    : _themeColorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                listing.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark 
                                      ? _themeColorDark
                                      : _themeColorDark,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              listing.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: subtextColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        // Average Rating Stars - Always show if there are reviews
                        Builder(
                          builder: (context) {
                            // Debug: Log the rating value being displayed
                            if (listing.reviewCount > 0) {
                              debugPrint('🎨 [HomePage UI] Displaying rating for ${listing.id}: reviewCount=${listing.reviewCount}, averageRating=${listing.averageRating}');
                            }
                            
                            if (listing.reviewCount > 0) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    listing.averageRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: constraints.maxWidth * 0.6,
                              child: Text(
                                listing.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtextColor,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₱${listing.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: _themeColorDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'per month',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtextColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              listing.ownerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (listing.isOwnerVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _themeColorDark.withValues(alpha: 0.2), // Glowing blue background
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: _themeColorDark, // Blue icon
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _HeartActionIcon(
                          listing: listing,
                          favoriteCount: listing.favoriteCount,
                        ),
                        _ModernActionIcon(
                          assetPath: 'assets/icons/navbar/comment_outlined.svg',
                          count: listing.reviewCount,
                          onTap: () {
                            debugPrint('🔍 [HomePage] Comment icon tapped - reviewCount: ${listing.reviewCount}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListingDetailsPage(
                                  listing: listing,
                                  initialTab: 1, // Open Review tab
                                ),
                              ),
                            );
                          },
                        ),
                        _ModernActionIcon(
                          assetPath: 'assets/icons/navbar/share_outlined.svg',
                          count: 0, // Share doesn't need a count
                          onTap: () {
                            _showShareModal(context, listing);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareModal(BuildContext context, ListingModel listing) {
    final listingLink = 'https://rentease.app/listing/${listing.id}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _ShareOption(
                    iconPath: 'assets/icons/navbar/share_outlined.svg',
                    title: 'Copy link',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: listingLink));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBarUtils.buildThemedSnackBar(
                          context,
                          'Link copied to clipboard',
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ShareOption(
                    iconPath: 'assets/icons/navbar/share_outlined.svg',
                    title: 'Share to other apps',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(listingLink, subject: listing.title);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeartActionIcon extends StatefulWidget {
  final ListingModel listing;
  final int favoriteCount;

  const _HeartActionIcon({
    required this.listing,
    required this.favoriteCount,
  });

  @override
  State<_HeartActionIcon> createState() => _HeartActionIconState();
}

class _HeartActionIconState extends State<_HeartActionIcon>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  int _currentCount = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final BFavoriteService _favoriteService = BFavoriteService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _listingSubscription;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.favoriteCount;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _checkIfFavorite();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _listingSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Setup realtime listener for favorite count updates
  void _setupRealtimeListener() {
    _listingSubscription = _firestore
        .collection('listings')
        .doc(widget.listing.id)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        final data = snapshot.data()!;
        final favoriteCount = (data['favoriteCount'] as num?)?.toInt() ?? 0;
        if (mounted) {
          setState(() {
            _currentCount = favoriteCount;
          });
        }
      }
    }, onError: (error) {
      debugPrint('❌ [_HeartActionIcon] Error listening to listing: $error');
    });
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final isFav = await _favoriteService.isFavorite(user.uid, widget.listing.id);
      if (mounted) {
        setState(() {
          _isSaved = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleTap() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(
          context,
          'Please sign in to save favorites',
        ),
      );
      return;
    }

    // Optimistic update
    final previousState = _isSaved;
    final previousCount = _currentCount;
    
    setState(() {
      _isSaved = !_isSaved;
      _currentCount = _isSaved ? _currentCount + 1 : _currentCount - 1;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      if (_isSaved) {
        await _favoriteService.addFavorite(
          userId: user.uid,
          listingId: widget.listing.id,
        );
        // Realtime listener will update the count automatically
      } else {
        await _favoriteService.removeFavorite(
          userId: user.uid,
          listingId: widget.listing.id,
        );
        // Realtime listener will update the count automatically
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isSaved = previousState;
          _currentCount = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error updating favorite',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _themeColor.withValues(alpha: 0.1),
        highlightColor: _themeColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  final iconColor = _isSaved
                      ? const Color(0xFFE91E63)
                      : const Color(0xFFB0B0B0);
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SvgPicture.asset(
                      _isSaved
                          ? 'assets/icons/navbar/heart_filled.svg'
                          : 'assets/icons/navbar/heart_outlined.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _themeColorDark,
                  ),
                )
              else
                Text(
                  _currentCount.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: _isSaved
                        ? const Color(0xFFE91E63)
                        : const Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernActionIcon extends StatelessWidget {
  final String assetPath;
  final int count;
  final VoidCallback onTap;

  const _ModernActionIcon({
    required this.assetPath,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _themeColor.withValues(alpha: 0.1),
        highlightColor: _themeColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                assetPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  const Color(0xFFB0B0B0),
                  BlendMode.srcIn,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;

  const _ShareOption({
    required this.iconPath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.black87,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LookingForSection extends StatefulWidget {
  final List<LookingForPostModel> posts;
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final bool isLoadingMore;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;

  const _LookingForSection({
    required this.posts,
    this.scrollController,
    this.onRefresh,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.onLoadMore,
  });

  @override
  State<_LookingForSection> createState() => _LookingForSectionState();
}

class _LookingForSectionState extends State<_LookingForSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve scroll position when navigating away

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
        // Header Section
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final textColor = isDark ? Colors.white : Colors.black87;
              
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Row(
                  children: [
                    Text(
                      'Looking For',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.posts.length} posts',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Posts List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == widget.posts.length - 1 ? 16 : 16,
                ),
                child: _LookingForPostCard(post: widget.posts[index]),
              );
            }, childCount: widget.posts.length),
          ),
        ),
        // Loading more indicator
        if (widget.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        // "Continue to see more" message
        if (!widget.isLoadingMore && widget.hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
              child: GestureDetector(
                onTap: widget.onLoadMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: _themeColorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _themeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, color: _themeColorDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Continue to see more',
                        style: TextStyle(
                          color: _themeColorDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
      ),
    );
  }
}

class _LookingForPostCard extends StatefulWidget {
  final LookingForPostModel post;

  const _LookingForPostCard({required this.post});

  @override
  State<_LookingForPostCard> createState() => _LookingForPostCardState();
}

class _LookingForPostCardState extends State<_LookingForPostCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  final List<CommentModel> _comments = [];
  final BHiddenPostService _hiddenPostService = BHiddenPostService();
  final BCommentService _commentService = BCommentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoadingCommentCount = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _loadCommentCount();
  }
  
  Future<void> _loadCommentCount() async {
    try {
      setState(() {
        _isLoadingCommentCount = true;
      });
      
      final commentsData = await _commentService.getCommentsByLookingForPost(widget.post.id);
      final actualCount = commentsData.length;
      
      if (mounted) {
        setState(() {
          _commentCount = actualCount;
          _isLoadingCommentCount = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [LookingForPostCard] Error loading comment count: $e');
      if (mounted) {
        setState(() {
          _isLoadingCommentCount = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_LookingForPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update counts when post data changes (e.g., from real-time listener)
    if (oldWidget.post.commentCount != widget.post.commentCount) {
      _commentCount = widget.post.commentCount;
    }
    if (oldWidget.post.likeCount != widget.post.likeCount) {
      _likeCount = widget.post.likeCount;
    }
  }

  void _showPostOptions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please log in to hide posts'),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bgColor = isDark ? Colors.grey[800] : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.visibility_off, color: textColor),
                  title: Text(
                    'Hide post',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _hidePost(currentUser.uid);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Remove from feed',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _hidePost(currentUser.uid);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareModal() {
    final postLink = 'https://rentease.app/looking-for/${widget.post.id}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _ShareOption(
                    iconPath: 'assets/icons/navbar/share_outlined.svg',
                    title: 'Copy link',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: postLink));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBarUtils.buildThemedSnackBar(
                          context,
                          'Link copied to clipboard',
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ShareOption(
                    iconPath: 'assets/icons/navbar/share_outlined.svg',
                    title: 'Share to other apps',
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.share(postLink, subject: widget.post.description);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _hidePost(String userId) async {
    try {
      debugPrint('🔒 [LookingForPostCard] Attempting to hide post: ${widget.post.id} for user: $userId');
      
      await _hiddenPostService.hidePost(
        userId: userId,
        postId: widget.post.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Post hidden. It will no longer appear in your feed.',
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Remove the post from the local list immediately
        final homePageState = context.findAncestorStateOfType<_HomePageState>();
        if (homePageState != null && mounted) {
          homePageState.setState(() {
            homePageState._lookingForPosts.removeWhere((p) => p.id == widget.post.id);
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LookingForPostCard] Error hiding post: $e');
      debugPrint('❌ [LookingForPostCard] Stack trace: $stackTrace');
      debugPrint('❌ [LookingForPostCard] Error type: ${e.runtimeType}');
      
      if (mounted) {
        String errorMessage = 'Failed to hide post. Please try again.';
        final errorString = e.toString().toLowerCase();
        
        // Check for specific error types
        if (errorString.contains('permission-denied') || errorString.contains('permission')) {
          errorMessage = 'Permission denied. Please make sure Firestore rules are deployed.';
          debugPrint('🔒 PERMISSION DENIED - Check if Firestore rules are deployed!');
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (errorString.contains('already')) {
          errorMessage = 'Post is already hidden.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            errorMessage,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _PostHeader(
            post: widget.post,
            onMoreTap: _showPostOptions,
          ),
              
          // Post Body (Clickable)
          Material(
            color: Colors.transparent,
              child: InkWell(
              onTap: () async {
                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LookingForPostDetailPage(post: widget.post),
                  ),
                );
                
                // Handle result: true = deleted, LookingForPostModel = updated
                if (mounted) {
                  final homePageState = context.findAncestorStateOfType<_HomePageState>();
                  if (result == true) {
                    // Post was deleted
                    homePageState?.setState(() {
                      homePageState._lookingForPosts.removeWhere((p) => p.id == widget.post.id);
                    });
                  } else if (result is LookingForPostModel) {
                    // Post was updated
                    homePageState?.setState(() {
                      final index = homePageState._lookingForPosts.indexWhere((p) => p.id == result.id);
                      if (index != -1) {
                        homePageState._lookingForPosts[index] = result;
                      }
                    });
                  }
                }
              },
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      widget.post.description,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                        height: 1.6,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Tags Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ModernTag(
                          icon: Icons.location_on_outlined,
                          text: widget.post.location,
                          color: const Color(0xFF6C63FF),
                        ),
                        _ModernTag(
                          iconAssetPath: 'assets/icons/navbar/home_outlined.svg',
                          text: widget.post.propertyType,
                          color: const Color(0xFF4CAF50),
                        ),
                        _ModernTag(
                          icon: Icons.attach_money_outlined,
                          text: widget.post.budget,
                          color: const Color(0xFF2196F3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action Bar (Footer)
          _PostActionBar(
            likeCount: _likeCount,
            commentCount: _commentCount,
            isLiked: _isLiked,
            isDark: isDark,
            onLikeTap: () {
              setState(() {
                _isLiked = !_isLiked;
                _likeCount += _isLiked ? 1 : -1;
              });
            },
            onCommentTap: () async {
              final result = await Navigator.push<dynamic>(
                context,
                MaterialPageRoute(
                  builder: (context) => LookingForPostDetailPage(post: widget.post),
                ),
              );
              
              // Handle result: true = deleted, LookingForPostModel = updated
              if (mounted) {
                final homePageState = context.findAncestorStateOfType<_HomePageState>();
                if (result == true) {
                  // Post was deleted
                  homePageState?.setState(() {
                    homePageState._lookingForPosts.removeWhere((p) => p.id == widget.post.id);
                  });
                } else if (result is LookingForPostModel) {
                  // Post was updated
                  homePageState?.setState(() {
                    final index = homePageState._lookingForPosts.indexWhere((p) => p.id == result.id);
                    if (index != -1) {
                      homePageState._lookingForPosts[index] = result;
                    }
                  });
                }
              }
              
              // Refresh comment count after returning from detail page
              await _loadCommentCount();
            },
            onShareTap: _showShareModal,
          ),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final LookingForPostModel post;
  final VoidCallback? onMoreTap;

  const _PostHeader({
    required this.post,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final iconColor = isDark ? Colors.white : Colors.grey[600];
    
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  post.username[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            // Username and Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (post.isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _themeColorDark.withValues(alpha: 0.2), // Glowing blue background
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: _themeColorDark, // Blue icon
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Three dots menu
            if (onMoreTap != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMoreTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.more_horiz,
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }
}

class _ModernTag extends StatelessWidget {
  final IconData? icon;
  final String? iconAssetPath; // SVG asset path for navbar-style icons
  final String text;
  final Color color;

  const _ModernTag({
    this.icon,
    this.iconAssetPath,
    required this.text,
    required this.color,
  }) : assert(icon != null || iconAssetPath != null, 'Either icon or iconAssetPath must be provided');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAssetPath != null)
            SvgPicture.asset(
              iconAssetPath!,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            )
          else
            Icon(
              icon!,
              size: 16,
              color: color,
            ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActionBar extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isDark;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback? onShareTap;

  const _PostActionBar({
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isDark,
    required this.onLikeTap,
    required this.onCommentTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like Button
          _ActionButton(
            iconPath: isLiked 
                ? 'assets/icons/navbar/heart_filled.svg'
                : 'assets/icons/navbar/heart_outlined.svg',
            count: likeCount,
            isActive: isLiked,
            isDark: isDark,
            onTap: onLikeTap,
          ),
          
          // Comment Button
          _ActionButton(
            iconPath: 'assets/icons/navbar/comment_outlined.svg',
            count: commentCount,
            isDark: isDark,
            onTap: onCommentTap,
          ),
          
          // Share Button
          if (onShareTap != null)
            _ActionButton(
              iconPath: 'assets/icons/navbar/share_outlined.svg',
              count: 0,
              isDark: isDark,
              onTap: onShareTap!,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String iconPath;
  final int count;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
    required this.count,
    this.isActive = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? Colors.white : Colors.grey[600]!;
    final inactiveTextColor = isDark ? Colors.white : Colors.grey[600]!;
    
    // Don't show count for share button (count is 0)
    final shouldShowCount = count > 0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isActive
                      ? const Color(0xFFE91E63)
                      : inactiveColor,
                  BlendMode.srcIn,
                ),
              ),
              if (shouldShowCount) ...[
                const SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                      ? const Color(0xFFE91E63)
                      : inactiveTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}


// ignore: unused_element
class _ScrollBasedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final ValueNotifier<bool> visibilityNotifier;
  final double height;

  _ScrollBasedTabBarDelegate({
    required this.tabBar,
    required this.visibilityNotifier,
    // ignore: unused_element_parameter
    this.height = 36.0,
  });

  @override
  double get minExtent => 0.0; // Can shrink to 0 when hidden

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _AnimatedTabBar(
      visibilityNotifier: visibilityNotifier,
      height: height,
      tabBar: tabBar,
    );
  }

  @override
  bool shouldRebuild(_ScrollBasedTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        height != oldDelegate.height ||
        visibilityNotifier != oldDelegate.visibilityNotifier;
  }
}

/// Animated tab bar widget with smooth slide down and fade in effect
class _AnimatedTabBar extends StatefulWidget {
  final ValueNotifier<bool> visibilityNotifier;
  final double height;
  final TabBar tabBar;

  const _AnimatedTabBar({
    required this.visibilityNotifier,
    required this.height,
    required this.tabBar,
  });

  @override
  State<_AnimatedTabBar> createState() => _AnimatedTabBarState();
}

/// Minimal fade and slide animation widget for content loading
class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final int delay; // Delay in milliseconds
  final bool skipAnimation; // Skip animation if true
  
  const _AnimatedFadeSlide({
    required this.child,
    this.delay = 0,
    this.skipAnimation = false,
  });
  
  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<_AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasStarted = false;
  
  @override
  void initState() {
    super.initState();
    
    // If animation should be skipped, show content immediately
    if (widget.skipAnimation) {
      _hasStarted = true;
      return;
    }
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Slower for visibility
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15), // More visible slide (15% down)
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    // Start animation after delay (wait for skeleton to disappear + stagger)
    Future.delayed(Duration(milliseconds: 850 + widget.delay), () {
      if (mounted && !_hasStarted) {
        setState(() {
          _hasStarted = true;
        });
        _controller.forward();
        // Mark that animations have been shown
        _HomePageState._hasAnimatedOnce = true;
      }
    });
  }
  
  @override
  void dispose() {
    if (!widget.skipAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // If animation is skipped, show content immediately
    if (widget.skipAnimation) {
      return widget.child;
    }
    
    if (!_hasStarted) {
      return Opacity(
        opacity: 0,
        child: widget.child,
      );
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedTabBarState extends State<_AnimatedTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Smooth fade animation with easeOutCubic curve for natural feel
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Smooth slide down animation with easeOutCubic curve
    _slideAnimation = Tween<double>(
      begin: -20.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Listen to visibility changes
    widget.visibilityNotifier.addListener(_onVisibilityChanged);
    _isVisible = widget.visibilityNotifier.value;
    if (_isVisible) {
      _controller.value = 1.0;
    }
  }

  void _onVisibilityChanged() {
    final newVisibility = widget.visibilityNotifier.value;
    if (newVisibility != _isVisible) {
      setState(() {
        _isVisible = newVisibility;
      });
      if (_isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.visibilityNotifier.removeListener(_onVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not visible and animation is at 0, return zero-height widget
    if (!_isVisible && _controller.value == 0.0) {
      return const SizedBox(height: 0, width: double.infinity);
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Return zero-height widget if animation is at 0
        if (_fadeAnimation.value <= 0) {
          return const SizedBox(height: 0, width: double.infinity);
        }
        
        return ClipRect(
          child: SizeTransition(
            sizeFactor: _fadeAnimation,
            axisAlignment: -1.0,
            child: Container(
              height: widget.height,
              color: Colors.white,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value.isNaN ? 0.0 : _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value.isNaN ? 1.0 : _fadeAnimation.value,
                  child: widget.tabBar,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
