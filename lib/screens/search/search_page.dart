import 'package:flutter/material.dart';
import 'package:rentease_app/models/filter_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/widgets/filter_sheet.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/screens/search/widgets/search_skeleton.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF); // Light background (like blue[50])
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ListingModel> _allListings = [];
  final FilterModel _filterModel = FilterModel();
  String? _selectedCategory;
  bool _isLoading = true;
  
  // Cache filtered listings to avoid recalculating on every build
  List<ListingModel>? _cachedFilteredListings;
  String? _lastSelectedCategory;
  double? _lastMinPrice;
  double? _lastMaxPrice;
  String? _lastBedrooms;
  String? _lastBathrooms;
  String? _lastPropertyType;

  @override
  void initState() {
    super.initState();
    _filterModel.addListener(_onFilterChanged);
    _loadSearchData();
  }

  /// Load search data (simulate network delay for skeleton loading)
  Future<void> _loadSearchData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _allListings = ListingModel.getMockListings();
        _cachedFilteredListings = _allListings;
        _isLoading = false;
      });
    }
  }

  /// Refresh search data
  Future<void> _refreshSearchData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSearchData();
  }

  void _onFilterChanged() {
    // Invalidate cache when filters change
    _cachedFilteredListings = null;
    // CRITICAL FIX: Defer setState() until after the current build frame completes.
    // This prevents "setState() called during build" errors when FilterSheet's
    // initState() calls resetTemporaryFilters() which triggers notifyListeners()
    // synchronously during the modal bottom sheet's build phase.
    // Using addPostFrameCallback ensures the state update happens after the
    // widget tree is fully built, making it safe to call setState().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterModel.removeListener(_onFilterChanged);
    _filterModel.dispose();
    super.dispose();
  }

  List<ListingModel> get _filteredListings {
    // Check if cache is still valid
    final currentMinPrice = _filterModel.minPrice;
    final currentMaxPrice = _filterModel.maxPrice;
    final currentBedrooms = _filterModel.selectedBedrooms;
    final currentBathrooms = _filterModel.selectedBathrooms;
    final currentPropertyType = _filterModel.selectedPropertyType;
    
    if (_cachedFilteredListings != null &&
        _lastSelectedCategory == _selectedCategory &&
        _lastMinPrice == currentMinPrice &&
        _lastMaxPrice == currentMaxPrice &&
        _lastBedrooms == currentBedrooms &&
        _lastBathrooms == currentBathrooms &&
        _lastPropertyType == currentPropertyType) {
      return _cachedFilteredListings!;
    }

    // Cache current filter values
    _lastSelectedCategory = _selectedCategory;
    _lastMinPrice = currentMinPrice;
    _lastMaxPrice = currentMaxPrice;
    _lastBedrooms = currentBedrooms;
    _lastBathrooms = currentBathrooms;
    _lastPropertyType = currentPropertyType;

    // Optimized: Single pass filtering instead of multiple where().toList() calls
    final filtered = <ListingModel>[];
    
    for (final listing in _allListings) {
      // Category filter
      if (_selectedCategory != null) {
        final selected = _selectedCategory!.toLowerCase();
        final listingCategory = listing.category.toLowerCase();
        bool matches = false;
        if (selected == 'house') {
          matches = listingCategory.contains('house');
        } else if (selected == 'apartment') {
          matches = listingCategory.contains('apartment');
        } else if (selected == 'office') {
          matches = true; // Office might not exist in listings
        } else {
          matches = listingCategory.contains(selected);
        }
        if (!matches) continue;
      }

      // Price filter
      if (listing.price < currentMinPrice || listing.price > currentMaxPrice) {
        continue;
      }

      // Bedrooms filter
      if (currentBedrooms != null) {
        bool matches = false;
        if (currentBedrooms == 'Studio') {
          matches = listing.bedrooms == 0 || listing.bedrooms == 1;
        } else if (currentBedrooms == '4+') {
          matches = listing.bedrooms >= 4;
        } else {
          final count = int.tryParse(currentBedrooms);
          matches = count != null && listing.bedrooms == count;
        }
        if (!matches) continue;
      }

      // Bathrooms filter
      if (currentBathrooms != null) {
        bool matches = false;
        if (currentBathrooms == '4+') {
          matches = listing.bathrooms >= 4;
        } else {
          final count = int.tryParse(currentBathrooms);
          matches = count != null && listing.bathrooms == count;
        }
        if (!matches) continue;
      }

      // Property type filter
      if (currentPropertyType != null) {
        final typeFilter = currentPropertyType.toLowerCase();
        final category = listing.category.toLowerCase();
        bool matches = false;
        if (typeFilter == 'apartment') {
          matches = category.contains('apartment');
        } else if (typeFilter == 'house') {
          matches = category.contains('house');
        } else if (typeFilter == 'condo') {
          matches = category.contains('condo');
        } else if (typeFilter == 'room') {
          matches = category.contains('room');
        } else if (typeFilter == 'villa') {
          matches = category.contains('villa');
        }
        if (!matches) continue;
      }

      filtered.add(listing);
    }

    _cachedFilteredListings = filtered;
    return filtered;
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
              _buildCategoryFilters(),
              const SizedBox(height: 24),
              _buildFeaturedListings(),
              const SizedBox(height: 24),
              _buildPropertyNearby(),
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

  Widget _buildCategoryFilters() {
    // Simplified category list matching the reference design
    final categoryFilters = ['House', 'Office', 'Apartment'];
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
                  _cachedFilteredListings = null; // Invalidate cache
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

  Widget _buildFeaturedListings() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final filteredListings = _filteredListings;

    if (filteredListings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Featured Properties',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: filteredListings.length,
            itemBuilder: (context, index) {
              final listing = filteredListings[index];
              return Padding(
                key: ValueKey(listing.id),
                padding: EdgeInsets.only(
                  right: index == filteredListings.length - 1 ? 0 : 16,
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
      ],
    );
  }

  Widget _buildPropertyNearby() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Property Nearby',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: _themeColorDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Builder(
            builder: (context) {
              final filteredListings = _filteredListings;
              final nearbyListings = filteredListings.length > 3
                  ? filteredListings.sublist(0, 3)
                  : filteredListings;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nearbyListings.length,
                itemBuilder: (context, index) {
                  final listing = nearbyListings[index];
                  return Padding(
                    key: ValueKey(listing.id),
                    padding: EdgeInsets.only(
                      bottom: index == nearbyListings.length - 1 ? 0 : 16,
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
              );
            },
          ),
        ),
      ],
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
                        ? Image.asset(
                            listing.imagePaths[0],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: placeholderColor,
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: iconColor,
                                  ),
                                ),
                              );
                            },
                          )
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
                          ? Image.asset(
                              listing.imagePaths[0],
                              fit: BoxFit.cover,
                              width: 100,
                              height: 130,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: placeholderColor,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 32,
                                      color: iconColor,
                                    ),
                                  ),
                                );
                              },
                            )
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
