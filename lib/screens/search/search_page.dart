import 'package:flutter/material.dart';
import 'package:rentease_app/models/filter_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';
import 'package:rentease_app/widgets/filter_sheet.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/screens/search/widgets/search_skeleton.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/widgets/subscription_promotion_card.dart';
import 'package:rentease_app/screens/subscription/subscription_page.dart';
import 'package:rentease_app/screens/chat/chats_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF); // Light background (like blue[50])
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  // Listings state
  List<ListingModel> _allListings = [];
  List<ListingModel>? _cachedFilteredListings;
  
  // Looking For Posts state
  List<LookingForPostModel> _allLookingForPosts = [];
  List<LookingForPostModel>? _cachedFilteredLookingForPosts;
  
  final FilterModel _filterModel = FilterModel();
  final BListingService _listingService = BListingService();
  final BLookingForPostService _lookingForPostService = BLookingForPostService();
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingLookingFor = true;
  
  // Track if we've loaded data to avoid unnecessary reloads
  bool _hasLoadedData = false;
  
  // Cache filtered listings to avoid recalculating on every build
  String? _lastSelectedCategory;
  double? _lastMinPrice;
  double? _lastMaxPrice;
  String? _lastBedrooms;
  String? _lastBathrooms;
  String? _lastPropertyType;
  
  // Verification status
  bool _isVerified = false;
  bool _isLoadingVerification = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _filterModel.addListener(_onFilterChanged);
    _loadSearchData();
    _loadLookingForPosts();
    _checkVerificationStatus();
    _hasLoadedData = true;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground to get newly added listings
    if (state == AppLifecycleState.resumed && _hasLoadedData) {
      debugPrint('🔄 [SearchPage] App resumed - refreshing search data...');
      _refreshSearchData();
    }
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }
  
  /// Called when search tab becomes visible - refresh data to ensure new listings appear
  void refreshOnTabVisible() {
    if (_hasLoadedData && mounted) {
      debugPrint('🔄 [SearchPage] Tab became visible - refreshing search data...');
      _refreshSearchData();
    }
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
            _isLoadingVerification = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingVerification = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVerification = false;
        });
      }
    }
  }

  /// Load search data from Firestore
  Future<void> _loadSearchData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final listingsData = await _listingService.getAllListings();
      
      // Remove duplicates by ID before converting to ListingModel
      final seenIds = <String>{};
      final uniqueListingsData = <String, Map<String, dynamic>>{};
      for (var data in listingsData) {
        final listingId = data['id'] as String? ?? '';
        if (listingId.isNotEmpty && !seenIds.contains(listingId)) {
          seenIds.add(listingId);
          uniqueListingsData[listingId] = data;
        }
      }
      
      final listings = uniqueListingsData.values.map((data) => ListingModel.fromMap(data)).toList();
      
      debugPrint('✅ [SearchPage] Loaded ${listings.length} unique listings (removed ${listingsData.length - listings.length} duplicates)');
      
      if (mounted) {
        setState(() {
          _allListings = listings;
          _cachedFilteredListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [SearchPage] Error loading listings: $e');
      if (mounted) {
        setState(() {
          _allListings = [];
          _cachedFilteredListings = [];
          _isLoading = false;
        });
      }
    }
  }
  
  /// Load looking for posts from Firestore
  Future<void> _loadLookingForPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingLookingFor = true;
      });
    }
    
    try {
      final postsData = await _lookingForPostService.getAllLookingForPosts();
      
      // Remove duplicates by ID before converting to LookingForPostModel
      final seenIds = <String>{};
      final uniquePostsData = <String, Map<String, dynamic>>{};
      for (var data in postsData) {
        final postId = data['id'] as String? ?? '';
        if (postId.isNotEmpty && !seenIds.contains(postId)) {
          seenIds.add(postId);
          uniquePostsData[postId] = data;
        }
      }
      
      final posts = uniquePostsData.values.map((data) => LookingForPostModel.fromMap(data)).toList();
      
      debugPrint('✅ [SearchPage] Loaded ${posts.length} unique looking for posts (removed ${postsData.length - posts.length} duplicates)');
      
      if (mounted) {
        setState(() {
          _allLookingForPosts = posts;
          _cachedFilteredLookingForPosts = posts;
          _isLoadingLookingFor = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [SearchPage] Error loading looking for posts: $e');
      if (mounted) {
        setState(() {
          _allLookingForPosts = [];
          _cachedFilteredLookingForPosts = [];
          _isLoadingLookingFor = false;
        });
      }
    }
  }
  
  /// Perform search with filters
  Future<void> _performSearch() async {
    // Search based on current tab
    if (_tabController.index == 0) {
      await _performListingsSearch();
    } else {
      await _performLookingForSearch();
    }
  }
  
  /// Perform search for listings
  Future<void> _performListingsSearch() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final searchQuery = _searchController.text.trim();
      final hasSearchQuery = searchQuery.isNotEmpty;
      final hasFilters = _filterModel.hasActiveFilters || _selectedCategory != null;
      
      // If no search query and no filters, use getAllListings for better performance and completeness
      if (!hasSearchQuery && !hasFilters) {
        debugPrint('🔍 [SearchPage] No search query or filters - loading all listings...');
        await _loadSearchData();
        return;
      }
      
      // Parse filter values
      int? bedroomsFilter;
      if (_filterModel.selectedBedrooms != null) {
        if (_filterModel.selectedBedrooms == 'Studio') {
          bedroomsFilter = 0;
        } else if (_filterModel.selectedBedrooms == '4+') {
          bedroomsFilter = 4; // Will filter >= 4 in memory
        } else {
          bedroomsFilter = int.tryParse(_filterModel.selectedBedrooms!);
        }
      }
      
      int? bathroomsFilter;
      if (_filterModel.selectedBathrooms != null) {
        if (_filterModel.selectedBathrooms == '4+') {
          bathroomsFilter = 4; // Will filter >= 4 in memory
        } else {
          bathroomsFilter = int.tryParse(_filterModel.selectedBathrooms!);
        }
      }
      
      // Map category filter to propertyType for fuzzy matching
      String? propertyTypeFilter = _filterModel.selectedPropertyType;
      if (_selectedCategory != null && propertyTypeFilter == null) {
        final categoryLower = _selectedCategory!.toLowerCase();
        if (categoryLower.contains('house')) {
          propertyTypeFilter = 'house';
        } else if (categoryLower.contains('apartment')) {
          propertyTypeFilter = 'apartment';
        } else if (categoryLower.contains('condo')) {
          propertyTypeFilter = 'condo';
        }
      }
      
      debugPrint('🔍 [SearchPage] Performing listings search with filters:');
      debugPrint('   - Search query: "$searchQuery"');
      debugPrint('   - Category: $_selectedCategory');
      debugPrint('   - Property Type: $propertyTypeFilter');
      debugPrint('   - Has filters: $hasFilters');
      
      // Use searchListingsWithFilters which queries Firestore directly for fresh data
      // This ensures we always get the latest listings from Firestore, including newly added ones
      final listingsData = await _listingService.searchListingsWithFilters(
        searchQuery: hasSearchQuery ? searchQuery : null,
        category: null,
        minPrice: _filterModel.currentMinPrice > 0 ? _filterModel.currentMinPrice : null,
        maxPrice: _filterModel.currentMaxPrice < 50000 ? _filterModel.currentMaxPrice : null,
        bedrooms: bedroomsFilter,
        bathrooms: bathroomsFilter,
        propertyType: propertyTypeFilter ?? _filterModel.selectedPropertyType,
      );
      
      debugPrint('📊 [SearchPage] Received ${listingsData.length} listings from Firestore');
      
      // Remove duplicates by ID before converting to ListingModel
      final seenIds = <String>{};
      final uniqueListingsData = <String, Map<String, dynamic>>{};
      for (var data in listingsData) {
        final listingId = data['id'] as String? ?? '';
        if (listingId.isNotEmpty && !seenIds.contains(listingId)) {
          seenIds.add(listingId);
          uniqueListingsData[listingId] = data;
        }
      }
      
      var listings = uniqueListingsData.values.map((data) => ListingModel.fromMap(data)).toList();
      
      // Apply additional filters that can't be done in Firestore
      if (bedroomsFilter == 4) {
        listings = listings.where((l) => l.bedrooms >= 4).toList();
      }
      
      if (bathroomsFilter == 4) {
        listings = listings.where((l) => l.bathrooms >= 4).toList();
      }
      
      debugPrint('✅ [SearchPage] Final filtered results: ${listings.length} unique listings (removed ${listingsData.length - uniqueListingsData.length} duplicates)');
      
      if (mounted) {
        setState(() {
          _allListings = listings;
          _cachedFilteredListings = listings;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SearchPage] Error searching listings: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _allListings = [];
          _cachedFilteredListings = [];
          _isLoading = false;
        });
      }
    }
  }
  
  /// Perform search for looking for posts
  Future<void> _performLookingForSearch() async {
    if (mounted) {
      setState(() {
        _isLoadingLookingFor = true;
      });
    }
    
    try {
      final searchQuery = _searchController.text.trim();
      final hasSearchQuery = searchQuery.isNotEmpty;
      
      // Map category filter to propertyType
      String? propertyTypeFilter = _filterModel.selectedPropertyType;
      if (_selectedCategory != null && propertyTypeFilter == null) {
        final categoryLower = _selectedCategory!.toLowerCase();
        if (categoryLower.contains('house')) {
          propertyTypeFilter = 'House Rentals';
        } else if (categoryLower.contains('apartment')) {
          propertyTypeFilter = 'Apartment';
        } else if (categoryLower.contains('condo')) {
          propertyTypeFilter = 'Condo';
        }
      }
      
      debugPrint('🔍 [SearchPage] Performing looking for posts search:');
      debugPrint('   - Search query: "${searchQuery}" (hasQuery: $hasSearchQuery)');
      debugPrint('   - Property Type: $propertyTypeFilter');
      debugPrint('   - Has filters: ${_filterModel.hasActiveFilters}');
      
      // If no search query and no filters, load all posts
      if (!hasSearchQuery && propertyTypeFilter == null && !_filterModel.hasActiveFilters) {
        debugPrint('📋 [SearchPage] No search query or filters - loading all posts');
        await _loadLookingForPosts();
        return;
      }
      
      final postsData = await _lookingForPostService.searchLookingForPosts(
        searchQuery: hasSearchQuery ? searchQuery : null,
        location: null, // Could add location filter later
        propertyType: propertyTypeFilter ?? _filterModel.selectedPropertyType,
        budget: null, // Could add budget filter later
      );
      
      debugPrint('📊 [SearchPage] Received ${postsData.length} looking for posts from service');
      
      // Remove duplicates by ID before converting to LookingForPostModel
      final seenIds = <String>{};
      final uniquePostsData = <String, Map<String, dynamic>>{};
      for (var data in postsData) {
        final postId = data['id'] as String? ?? '';
        if (postId.isNotEmpty && !seenIds.contains(postId)) {
          seenIds.add(postId);
          uniquePostsData[postId] = data;
        }
      }
      
      final posts = uniquePostsData.values.map((data) => LookingForPostModel.fromMap(data)).toList();
      
      debugPrint('✅ [SearchPage] Final filtered results: ${posts.length} unique looking for posts (removed ${postsData.length - posts.length} duplicates)');
      
      if (mounted) {
        setState(() {
          _allLookingForPosts = posts;
          _cachedFilteredLookingForPosts = posts;
          _isLoadingLookingFor = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SearchPage] Error searching looking for posts: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _allLookingForPosts = [];
          _cachedFilteredLookingForPosts = [];
          _isLoadingLookingFor = false;
        });
      }
    }
  }

  /// Refresh search data
  Future<void> _refreshSearchData() async {
    debugPrint('🔄 [SearchPage] Refreshing search data...');
    // Always refresh and then perform search to respect current filters and search query
    if (_tabController.index == 0) {
      // Reload all listings first to get fresh data
      await _loadSearchData();
      // Then apply search/filters if any
      final hasSearchQuery = _searchController.text.trim().isNotEmpty;
      final hasFilters = _filterModel.hasActiveFilters || _selectedCategory != null;
      if (hasSearchQuery || hasFilters) {
        await _performListingsSearch();
      }
    } else {
      await _loadLookingForPosts();
      // Then apply search/filters if any
      final hasSearchQuery = _searchController.text.trim().isNotEmpty;
      final hasFilters = _filterModel.hasActiveFilters || _selectedCategory != null;
      if (hasSearchQuery || hasFilters) {
        await _performLookingForSearch();
      }
    }
  }

  void _onFilterChanged() {
    // Invalidate cache when filters change
    _cachedFilteredListings = null;
    // Perform search when filters change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performSearch();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _filterModel.removeListener(_onFilterChanged);
    _filterModel.dispose();
    super.dispose();
  }

  List<ListingModel> get _filteredListings {
    // Return cached filtered listings (filtering is done via Firestore queries)
    return _cachedFilteredListings ?? _allListings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    
    // Show skeleton only during initial loading
    if (_isLoading && _allListings.isEmpty) {
      return SearchSkeleton(isDark: isDark);
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshSearchData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildTabs(),
              const SizedBox(height: 8),
              _buildCategoryFilters(),
              const SizedBox(height: 16),
              // Subscription Promotion Card (only show if not verified)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: (!_isLoadingVerification && !_isVerified)
                    ? Padding(
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
                          showDismissButton: true,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              // Show results based on selected tab
              _tabController.index == 0
                  ? _buildListingsResults()
                  : _buildLookingForResults(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarColor = isDark ? Colors.grey[900] : Colors.white;
    
    return AppBar(
      backgroundColor: appBarColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
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
        const ThreeDotsMenu(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover your new house!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find the perfect rental property',
            style: TextStyle(
              fontSize: 14,
              color: subtextColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final hintColor = isDark ? Colors.grey[400]! : Colors.grey[400]!;
    final iconColor = isDark ? Colors.white : Colors.grey[600]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: iconColor,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: iconColor, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                          // Reload data for current tab when clearing
                          if (_tabController.index == 0) {
                            _loadSearchData();
                          } else {
                            _loadLookingForPosts();
                          }
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _themeColorDark, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                filled: true,
                fillColor: fillColor,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {});
                // Perform search as user types (debounced)
                if (value.isEmpty) {
                  // Clear search - reload all data for current tab
                  if (_tabController.index == 0) {
                    _loadSearchData();
                  } else {
                    _loadLookingForPosts();
                  }
                } else {
                  // Debounce search - wait 500ms after user stops typing
                  // This ensures we fetch fresh data each time user searches
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && _searchController.text == value) {
                      _performSearch();
                    }
                  });
                }
              },
              onSubmitted: (value) {
                _performSearch();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Filter button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _themeColorDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => FilterSheet(filterModel: _filterModel),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: 36, // Reduced height for smaller tabs
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: _themeColorDark,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            labelPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            tabAlignment: TabAlignment.fill,
            tabs: const [
              Tab(text: 'Listings'),
              Tab(text: 'Looking For'),
            ],
            onTap: (index) {
              setState(() {});
              // Perform search when switching tabs
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _performSearch();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    // Simplified category list matching the reference design
    final categoryFilters = ['House', 'Condo', 'Apartment'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: categoryFilters.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(
              right: category != categoryFilters.last ? 12 : 0,
            ),
              child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : category;
                  _cachedFilteredListings = null;
                  _cachedFilteredLookingForPosts = null;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _performSearch();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _themeColorDark
                      : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _themeColorDark
                        : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[300]! : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListingsResults() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final filteredListings = _filteredListings;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(
            color: _themeColorDark,
          ),
        ),
      );
    }

    if (filteredListings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: subtextColor),
              const SizedBox(height: 16),
              Text(
                'No listings found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search terms',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _selectedCategory = null;
                  _filterModel.clearFilters();
                  _performSearch();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear all filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColorDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get featured listings (first 5 listings or verified user listings)
    // Remove duplicates by ID
    final seenFeaturedIds = <String>{};
    final featuredListings = <ListingModel>[];
    
    // First, add verified listings
    for (final listing in filteredListings) {
      if (listing.isOwnerVerified && !seenFeaturedIds.contains(listing.id) && featuredListings.length < 5) {
        seenFeaturedIds.add(listing.id);
        featuredListings.add(listing);
      }
    }
    
    // If no verified listings, use first 5 unique listings as featured
    if (featuredListings.isEmpty) {
      for (final listing in filteredListings) {
        if (!seenFeaturedIds.contains(listing.id) && featuredListings.length < 5) {
          seenFeaturedIds.add(listing.id);
          featuredListings.add(listing);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured Listings Section (if we have listings)
        if (featuredListings.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: featuredListings.length,
              itemBuilder: (context, index) {
                final listing = featuredListings[index];
                return Padding(
                  key: ValueKey('featured_${listing.id}'),
                  padding: EdgeInsets.only(
                    right: index == featuredListings.length - 1 ? 0 : 16,
                  ),
                  child: _FeaturedListingCard(
                    listing: listing,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListingDetailsPage(
                            listing: listing,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        // All Results Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'All Results (${filteredListings.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredListings.length,
            itemBuilder: (context, index) {
              final listing = filteredListings[index];
              return Padding(
                key: ValueKey(listing.id),
                padding: EdgeInsets.only(
                  bottom: index == filteredListings.length - 1 ? 0 : 16,
                ),
                child: _NearbyListingCard(
                  listing: listing,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailsPage(
                          listing: listing,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLookingForResults() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final filteredPosts = _cachedFilteredLookingForPosts ?? _allLookingForPosts;

    if (_isLoadingLookingFor) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(
            color: _themeColorDark,
          ),
        ),
      );
    }

    if (filteredPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: subtextColor),
              const SizedBox(height: 16),
              Text(
                'No posts found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search terms',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _selectedCategory = null;
                  _filterModel.clearFilters();
                  _performSearch();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear all filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColorDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Search Results (${filteredPosts.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPosts.length,
            cacheExtent: 500,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return Padding(
                key: ValueKey(post.id),
                padding: EdgeInsets.only(
                  bottom: index == filteredPosts.length - 1 ? 0 : 16,
                ),
                child: _SearchLookingForPostCard(
                  post: post,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LookingForPostDetailPage(
                          post: post,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Helper function to build listing images (supports both network and asset images)
Widget _buildListingImage(String imagePath, Color placeholderColor, Color iconColor, {double? width, double? height}) {
  final isNetworkImage = imagePath.startsWith('http://') || imagePath.startsWith('https://');
  
  if (isNetworkImage) {
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.cover,
      width: width,
      height: height,
      memCacheWidth: width != null ? (width * 2).toInt() : 800,
      memCacheHeight: height != null ? (height * 2).toInt() : 450,
      maxWidthDiskCache: width != null ? (width * 3).toInt() : 1200,
      maxHeightDiskCache: height != null ? (height * 3).toInt() : 675,
      placeholder: (context, url) => Container(
        color: placeholderColor,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: placeholderColor,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: width != null ? 32 : 48,
            color: iconColor,
          ),
        ),
      ),
    );
  } else {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: placeholderColor,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: width != null ? 32 : 48,
              color: iconColor,
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedListingCard extends StatelessWidget {
  final ListingModel listing;
  final bool isDark;
  final VoidCallback onTap;

  const _FeaturedListingCard({
    super.key,
    required this.listing,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final iconColor = isDark ? Colors.white : Colors.grey[500]!;
    final placeholderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: listing.imagePaths.isNotEmpty
                        ? _buildListingImage(listing.imagePaths[0], placeholderColor, iconColor)
                        : Container(
                            color: placeholderColor,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: iconColor,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.price > 0 
                            ? '₱${listing.price.toStringAsFixed(0)}/mo'
                            : 'Price not set',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? _themeColorDark.withOpacity(0.25)
                            : _themeColorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: _themeColorDark,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: iconColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtextColor,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Monthly Payment and Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Monthly Payment
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₱${listing.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _themeColorDark,
                              ),
                            ),
                            Text(
                              '/month',
                              style: TextStyle(
                                fontSize: 10,
                                color: subtextColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        // Rating
                        if (listing.reviewCount > 0)
                          Row(
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${listing.reviewCount})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyListingCard extends StatelessWidget {
  final ListingModel listing;
  final bool isDark;
  final VoidCallback onTap;

  const _NearbyListingCard({
    super.key,
    required this.listing,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600]!;
    final iconColor = isDark ? Colors.white : Colors.grey[500]!;
    final placeholderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _themeColor.withValues(alpha: 0.1),
        highlightColor: _themeColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Thumbnail
              Align(
                alignment: Alignment.topLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 130,
                    child: Container(
                      color: placeholderColor,
                      child: listing.imagePaths.isNotEmpty
                          ? _buildListingImage(listing.imagePaths[0], placeholderColor, iconColor, width: 100, height: 130)
                          : Container(
                              color: placeholderColor,
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                  color: iconColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Column 2: Property Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? _themeColorDark.withOpacity(0.25)
                              : _themeColorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          listing.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: _themeColorDark,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: subtextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              listing.price > 0 
                                  ? '₱${listing.price.toStringAsFixed(0)}'
                                  : 'Price not set',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: listing.price > 0 
                                    ? _themeColorDark 
                                    : subtextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (listing.price > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '/mo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ],
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

class _SearchLookingForPostCard extends StatelessWidget {
  final LookingForPostModel post;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchLookingForPostCard({
    required this.post,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final iconColor = isDark ? Colors.white : Colors.grey[500]!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _themeColor.withValues(alpha: 0.1),
        highlightColor: _themeColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Username and time
              Row(
                children: [
                  // Profile Picture
                  Container(
                    width: 40,
                    height: 40,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            if (post.isVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _themeColorDark.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: _themeColorDark,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                post.description,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Tags: Location, Property Type, Budget
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagChip(
                    icon: Icons.location_on_outlined,
                    text: post.location,
                    color: const Color(0xFF6C63FF),
                    isDark: isDark,
                  ),
                  _TagChip(
                    icon: Icons.home_outlined,
                    text: post.propertyType,
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                  ),
                  _TagChip(
                    icon: Icons.attach_money_outlined,
                    text: post.budget,
                    color: const Color(0xFF2196F3),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Footer: Stats
              Row(
                children: [
                  if (post.likeCount > 0) ...[
                    Icon(
                      Icons.favorite_outline,
                      size: 16,
                      color: subtextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (post.commentCount > 0) ...[
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: subtextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _TagChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
