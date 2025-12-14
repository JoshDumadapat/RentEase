import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentease_app/models/category_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/models/comment_model.dart';
import 'package:rentease_app/screens/posts/posts_page.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';
import 'package:rentease_app/screens/home/widgets/home_skeleton.dart';
import 'package:rentease_app/screens/home/widgets/looking_for_skeleton.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

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
  final List<ListingModel> _listings = [...ListingModel.getMockListings()];
  final List<LookingForPostModel> _lookingForPosts = [
    ...LookingForPostModel.getMockLookingForPosts()
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFirstTimeUser();
    _loadData();
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

  Future<void> _loadData() async {
    // Simulate network delay for skeleton loading (minimal delay for smooth UX)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingLookingFor = false;
      });
    }
  }

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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final unselectedTabColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
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
                    dividerColor: Colors.transparent, // Remove bottom outline
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
    // Reload listings data
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildListingsTab() {
    return _ListingsSection(
      categories: _categories,
      listings: _listings,
      scrollController: _listingsScrollController,
      onRefresh: _refreshListings,
      hasAnimatedOnce: _hasAnimatedOnce,
      isFirstTimeUser: _isFirstTimeUser,
    );
  }

  Future<void> _refreshLookingFor() async {
    // Reload looking for posts data
    setState(() {
      _isLoadingLookingFor = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoadingLookingFor = false;
      });
    }
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

  const _ListingsSection({
    required this.categories,
    required this.listings,
    this.scrollController,
    this.onRefresh,
    required this.hasAnimatedOnce,
    required this.isFirstTimeUser,
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

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: listings.length,
            itemBuilder: (context, index) {
            final listing = listings[index];
            return Padding(
              key: ValueKey(listing.id),
              padding: EdgeInsets.only(
                bottom: index == listings.length - 1 ? 0 : 20,
              ),
              child: _AnimatedFadeSlide(
                delay: 400 + (index * 80), // Staggered animation with more spacing
                child: _ModernListingCard(
                  listing: listing,
                  onTap: () => onListingTap(listing),
                ),
              ),
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
                          ? Image(
                              image: AssetImage(listing.imagePaths[0]),
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
                            )
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
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
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
                        _HeartActionIcon(likeCount: 24),
                        _ModernActionIcon(
                          assetPath: 'assets/icons/navbar/comment_outlined.svg',
                          count: 8,
                          onTap: () {},
                        ),
                        _ModernActionIcon(
                          assetPath: 'assets/icons/navbar/share_outlined.svg',
                          count: 3,
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
    const postLink = "https://example.com/post/123";

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
                      await Share.share(postLink, subject: listing.title);
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
  final int likeCount;

  const _HeartActionIcon({required this.likeCount});

  @override
  State<_HeartActionIcon> createState() => _HeartActionIconState();
}

class _HeartActionIconState extends State<_HeartActionIcon>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isSaved = !_isSaved;
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
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
              Text(
                widget.likeCount.toString(),
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

  const _LookingForSection({
    required this.posts,
    this.scrollController,
    this.onRefresh,
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
                  bottom: index == widget.posts.length - 1 ? 32 : 16,
                ),
                child: _LookingForPostCard(post: widget.posts[index]),
              );
            }, childCount: widget.posts.length),
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _comments.addAll(CommentModel.getMockComments());
  }

  void _showPostOptions() {
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
                onTap: () {
                  Navigator.pop(context);
                  // Note: Hide post functionality will be implemented when backend is ready
                },
              ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Remove from feed',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Note: Remove post functionality will be implemented when backend is ready
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LookingForPostDetailPage(post: widget.post),
                  ),
                );
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
            onCommentTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LookingForPostDetailPage(post: widget.post),
                ),
              );
            },
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

  const _PostActionBar({
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isDark,
    required this.onLikeTap,
    required this.onCommentTap,
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
          const SizedBox(width: 32),
          
          // Comment Button
          _ActionButton(
            iconPath: 'assets/icons/navbar/comment_outlined.svg',
            count: commentCount,
            isDark: isDark,
            onTap: onCommentTap,
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
              const SizedBox(width: 8),
              Text(
                count > 0 ? _formatCount(count) : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFFE91E63)
                      : inactiveTextColor,
                ),
              ),
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
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
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
