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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF); // Light background (like blue[50])
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _filterModel.addListener(_onFilterChanged);
    _loadSearchData();
    _loadLookingForPosts();
    _checkVerificationStatus();
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
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
      final listings = listingsData.map((data) => ListingModel.fromMap(data)).toList();
      
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
      final posts = postsData.map((data) => LookingForPostModel.fromMap(data)).toList();
      
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
      debugPrint('   - Search query: "${_searchController.text.trim()}"');
      debugPrint('   - Category: $_selectedCategory');
      debugPrint('   - Property Type: $propertyTypeFilter');
      
      final listingsData = await _listingService.searchListingsWithFilters(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        category: null,
        minPrice: _filterModel.currentMinPrice > 0 ? _filterModel.currentMinPrice : null,
        maxPrice: _filterModel.currentMaxPrice < 50000 ? _filterModel.currentMaxPrice : null,
        bedrooms: bedroomsFilter,
        bathrooms: bathroomsFilter,
        propertyType: propertyTypeFilter ?? _filterModel.selectedPropertyType,
      );
      
      debugPrint('📊 [SearchPage] Received ${listingsData.length} listings from service');
      
      var listings = listingsData.map((data) => ListingModel.fromMap(data)).toList();
      
      // Apply additional filters that can't be done in Firestore
      if (bedroomsFilter == 4) {
        listings = listings.where((l) => l.bedrooms >= 4).toList();
      }
      
      if (bathroomsFilter == 4) {
        listings = listings.where((l) => l.bathrooms >= 4).toList();
      }
      
      debugPrint('✅ [SearchPage] Final filtered results: ${listings.length} listings');
      
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
      debugPrint('   - Search query: "${_searchController.text.trim()}"');
      debugPrint('   - Property Type: $propertyTypeFilter');
      
      final postsData = await _lookingForPostService.searchLookingForPosts(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        location: null, // Could add location filter later
        propertyType: propertyTypeFilter ?? _filterModel.selectedPropertyType,
        budget: null, // Could add budget filter later
      );
      
      debugPrint('📊 [SearchPage] Received ${postsData.length} looking for posts from service');
      
      final posts = postsData.map((data) => LookingForPostModel.fromMap(data)).toList();
      
      debugPrint('✅ [SearchPage] Final filtered results: ${posts.length} looking for posts');
      
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
    // Always perform search when refreshing to respect current filters
    if (_tabController.index == 0) {
      await _loadSearchData();
      await _performListingsSearch();
    } else {
      await _loadLookingForPosts();
      await _performLookingForSearch();
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
              const SizedBox(height: 12),
              _buildTabs(),
              const SizedBox(height: 12),
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
                  vertical: 12,
                ),
                filled: true,
                fillColor: fillColor,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {});
                // Perform search as user types (debounced in production)
                if (value.isEmpty) {
                  // Reload data for current tab
                  if (_tabController.index == 0) {
                    _loadSearchData();
                  } else {
                    _loadLookingForPosts();
                  }
                } else {
                  // Debounce search - wait 500ms after user stops typing
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _themeColorDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune,
                color: Colors.white,
                size: 20,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Search Results (${filteredListings.length})',
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
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: placeholderColor,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
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
                        '₱${listing.price.toStringAsFixed(0)}/mo',
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
                    const SizedBox(height: 6),
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
                          Text(
                            '₱${listing.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _themeColorDark,
                            ),
                          ),
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
