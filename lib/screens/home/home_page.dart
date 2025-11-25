import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rentease_app/models/category_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/models/comment_model.dart';
import 'package:rentease_app/screens/posts/posts_page.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';
import 'package:rentease_app/screens/home/widgets/home_skeleton.dart';
import 'package:rentease_app/screens/home/widgets/comment_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _showTabs = true;
  final ScrollController _listingsScrollController = ScrollController();
  final ScrollController _lookingForScrollController = ScrollController();
  final ValueNotifier<bool> _tabsVisibilityNotifier = ValueNotifier<bool>(true);

  final List<CategoryModel> _categories = CategoryModel.getMockCategories();
  final List<ListingModel> _listings = ListingModel.getMockListings();
  final List<LookingForPostModel> _lookingForPosts =
      LookingForPostModel.getMockLookingForPosts();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _setupScrollListeners();
    _loadData();
  }

  void _onTabChanged() {
    if (mounted) {
      _handleScroll();
    }
  }

  void _setupScrollListeners() {
    _listingsScrollController.addListener(_handleScroll);

    _lookingForScrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final ScrollController activeController = _tabController.index == 0
        ? _listingsScrollController
        : _lookingForScrollController;

    if (!activeController.hasClients) return;

    final double currentScrollPosition = activeController.position.pixels;
    final direction = activeController.position.userScrollDirection;

    final bool shouldShow =
        currentScrollPosition <= 0 || direction == ScrollDirection.forward;

    if (_showTabs != shouldShow) {
      setState(() {
        _showTabs = shouldShow;
      });
      _tabsVisibilityNotifier.value = shouldShow;
    }
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _listingsScrollController.removeListener(_handleScroll);
    _lookingForScrollController.removeListener(_handleScroll);
    _listingsScrollController.dispose();
    _lookingForScrollController.dispose();
    _tabsVisibilityNotifier.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const HomeSkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: false,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.home, color: Colors.blue);
                  },
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPersistentHeader(
              pinned: false,
              floating: false,
              delegate: _ScrollBasedTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue[700],
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: const [
                    Tab(text: 'Listings'),
                    Tab(text: 'Looking For'),
                  ],
                ),
                visibilityNotifier: _tabsVisibilityNotifier,
                height: 40.0,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildListingsTab(), _buildLookingForTab()],
        ),
      ),
    );
  }

  Widget _buildListingsTab() {
    return CustomScrollView(
      controller: _listingsScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: _WelcomeSection(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        SliverToBoxAdapter(
          child: _FeaturedCategoriesSection(
            categories: _categories,
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
        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        SliverToBoxAdapter(
          child: _VisitListingsSection(
            listings: _listings,
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
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildLookingForTab() {
    return _LookingForSection(
      posts: _lookingForPosts,
      scrollController: _lookingForScrollController,
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to RentEase!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Start your '),
              TextSpan(
                text: 'journey',
                style: TextStyle(
                  color: Colors.blue[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const TextSpan(text: ' by choosing your '),
              TextSpan(
                text: 'property preference.',
                style: TextStyle(
                  color: Colors.blue[400],
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

  const _FeaturedCategoriesSection({
    required this.categories,
    required this.onCategoryTap,
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
            _LargeCategoryCard(
              category: houseRentals,
              onTap: () => onCategoryTap(houseRentals),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _TallCategoryCard(
                        category: apartments,
                        onTap: () => onCategoryTap(apartments),
                      ),
                      const SizedBox(height: 12),
                      _SmallCategoryCard(
                        category: condoRentals,
                        onTap: () => onCategoryTap(condoRentals),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _SmallCategoryCard(
                        category: rooms,
                        onTap: () => onCategoryTap(rooms),
                      ),
                      const SizedBox(height: 12),
                      _SmallCategoryCard(
                        category: boardingHouse,
                        onTap: () => onCategoryTap(boardingHouse),
                      ),
                      const SizedBox(height: 12),
                      _SmallCategoryCard(
                        category: studentDorms,
                        onTap: () => onCategoryTap(studentDorms),
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
                    color: Colors.blue[100],
                    child: const Center(
                      child: Icon(Icons.home, size: 60, color: Colors.blue),
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
                    color: Colors.blue[100],
                    child: const Center(
                      child: Icon(Icons.home, size: 50, color: Colors.blue),
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
                    color: Colors.blue[100],
                    child: const Center(
                      child: Icon(Icons.home, size: 40, color: Colors.blue),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visit Listings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Listings from Trusted users',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == listings.length - 1 ? 0 : 20,
              ),
              child: _ModernListingCard(
                listing: listings[index],
                onTap: () => onListingTap(listings[index]),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.blue.withValues(alpha: 0.1),
        highlightColor: Colors.blue.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                spreadRadius: 0,
                blurRadius: 8,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
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
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
                                color: Colors.blue[700],
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'per month',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
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
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (listing.isOwnerVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _HeartActionIcon(likeCount: 24),
                        _ModernActionIcon(
                          assetPath: 'assets/icons/navbar/message_outlined.svg',
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
                    icon: Icons.link,
                    title: 'Copy link',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: postLink));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ShareOption(
                    icon: Icons.share,
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
        splashColor: Colors.blue.withValues(alpha: 0.1),
        highlightColor: Colors.blue.withValues(alpha: 0.05),
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
        splashColor: Colors.blue.withValues(alpha: 0.1),
        highlightColor: Colors.blue.withValues(alpha: 0.05),
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
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
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
              Icon(icon, size: 24, color: Colors.black87),
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

class _LookingForSection extends StatelessWidget {
  final List<LookingForPostModel> posts;
  final ScrollController? scrollController;

  const _LookingForSection({required this.posts, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Header Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Looking For',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${posts.length} posts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Posts List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == posts.length - 1 ? 24 : 0,
                ),
                child: _LookingForPostCard(post: posts[index]),
              );
            }, childCount: posts.length),
          ),
        ),
      ],
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
  bool _showComments = false;
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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_off, color: Colors.black87),
                title: const Text(
                  'Hide post',
                  style: TextStyle(color: Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement hide post functionality
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
                  // TODO: Implement remove post functionality
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 0.5),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      widget.post.description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Tags Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ModernTag(
                          icon: Icons.location_on_outlined,
                          text: widget.post.location,
                          color: const Color(0xFF6C63FF),
                        ),
                        _ModernTag(
                          icon: Icons.home_outlined,
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
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 44,
              height: 44,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Username and Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (post.isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
              GestureDetector(
                onTap: onMoreTap,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModernTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ModernTag({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
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
              fontWeight: FontWeight.w500,
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
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  const _PostActionBar({
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Like Button
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            count: likeCount,
            isActive: isLiked,
            onTap: onLikeTap,
          ),
          const SizedBox(width: 32),
          
          // Comment Button
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            count: commentCount,
            onTap: onCommentTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.count,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? const Color(0xFFE91E63)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                count > 0 ? _formatCount(count) : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFFE91E63)
                      : Colors.grey[600],
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


class _ScrollBasedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final ValueNotifier<bool> visibilityNotifier;
  final double height;

  _ScrollBasedTabBarDelegate({
    required this.tabBar,
    required this.visibilityNotifier,
    this.height = 40.0,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: visibilityNotifier,
      builder: (context, isVisible, child) {
        return Container(
          height: height,
          color: Colors.white,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isVisible ? 1.0 : 0.0,
            child: tabBar,
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_ScrollBasedTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        height != oldDelegate.height ||
        visibilityNotifier != oldDelegate.visibilityNotifier;
  }
}
