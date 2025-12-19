import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rentease_app/models/category_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BReviewService.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

// Theme color constants
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF);
const Color _themeColorDark = Color(0xFF00B8E6);

class PostsPage extends StatefulWidget {
  final CategoryModel category;

  const PostsPage({super.key, required this.category});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final BListingService _listingService = BListingService();
  final BReviewService _reviewService = BReviewService();
  List<ListingModel> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Map CategoryModel names to Firestore category values
      // Firestore may have variations (e.g., "Apartment" vs "Apartments")
      // So we try both variations and combine results
      List<String> categoryNames = _getCategoryVariations(widget.category.name);
      if (kDebugMode) {
        debugPrint('🔍 [PostsPage] Category Model Name: ${widget.category.name}');
        debugPrint('🔍 [PostsPage] Searching categories: $categoryNames');
      }
      
      // Use a Map to track unique listings by ID as we fetch them
      // This prevents duplicates during fetching from multiple category variations
      final uniqueListings = <String, Map<String, dynamic>>{};
      
      for (String categoryName in categoryNames) {
        if (kDebugMode) {
          debugPrint('🔍 [PostsPage] Querying category: $categoryName');
        }
        final listingsData = await _listingService.getListingsByCategory(categoryName);
        if (kDebugMode) {
          debugPrint('📊 [PostsPage] Found ${listingsData.length} listings for "$categoryName"');
        }
        
        // Add listings only if they haven't been seen before (by ID)
        // This ensures no duplicates when querying multiple category variations
        int addedCount = 0;
        int skippedCount = 0;
        for (var listing in listingsData) {
          final id = listing['id'] as String?;
          if (id == null || id.isEmpty) {
            if (kDebugMode) {
              debugPrint('⚠️ [PostsPage] Skipping listing with empty/null ID from category "$categoryName"');
            }
            skippedCount++;
            continue;
          }
          
          if (!uniqueListings.containsKey(id)) {
            uniqueListings[id] = listing;
            addedCount++;
          } else {
            skippedCount++;
            if (kDebugMode) {
              debugPrint('⚠️ [PostsPage] Duplicate listing ID "$id" already found - skipping');
            }
          }
        }
        
        if (kDebugMode) {
          debugPrint('✅ [PostsPage] Added $addedCount new listings from "$categoryName"');
          if (skippedCount > 0) {
            debugPrint('⚠️ [PostsPage] Skipped $skippedCount duplicate/empty listings from "$categoryName"');
          }
        }
      }
      
      debugPrint('✅ [PostsPage] Total unique listings after deduplication: ${uniqueListings.length}');
      
      // Fetch review count and average rating for each listing
      final listingsWithReviews = await Future.wait(
        uniqueListings.values.map((data) async {
          // Fetch actual review count and average rating FIRST, before creating ListingModel
          String listingId = data['id'] as String? ?? '';
          int actualCount = 0;
          double actualAverageRating = 0.0;
          
          try {
            actualCount = await _reviewService.getReviewCount(listingId);
            debugPrint('🔍 [PostsPage] Fetching rating for $listingId: reviewCount=$actualCount');
            
            if (actualCount > 0) {
              actualAverageRating = await _reviewService.getAverageRating(listingId);
              debugPrint('✅ [PostsPage] Fetched rating for $listingId: $actualAverageRating (from $actualCount reviews)');
            } else {
              debugPrint('📊 [PostsPage] No reviews found for $listingId');
            }
          } catch (e, stackTrace) {
            debugPrint('⚠️ [PostsPage] Error fetching review data for $listingId: $e');
            debugPrint('📚 Stack trace: $stackTrace');
          }
          
          // Update data map with fetched values BEFORE creating ListingModel
          final updatedData = Map<String, dynamic>.from(data);
          updatedData['reviewCount'] = actualCount;
          updatedData['averageRating'] = actualAverageRating; // Already a double from getAverageRating
          
          debugPrint('🔧 [PostsPage] Creating ListingModel for $listingId with: reviewCount=$actualCount, averageRating=$actualAverageRating');
          
          // Create ListingModel with updated data
          return ListingModel.fromMap(updatedData);
        }),
      );
      
      // Final deduplication pass - ensure no duplicates in the final list
      // Use a Map to track by ID and preserve order (first occurrence wins)
      final finalUniqueListings = <String, ListingModel>{};
      int finalDuplicates = 0;
      for (var listing in listingsWithReviews) {
        if (listing.id.isEmpty) {
          finalDuplicates++;
          if (kDebugMode) {
            debugPrint('⚠️ [PostsPage] Skipping listing with empty ID in final list');
          }
          continue;
        }
        
        if (!finalUniqueListings.containsKey(listing.id)) {
          finalUniqueListings[listing.id] = listing;
        } else {
          finalDuplicates++;
          if (kDebugMode) {
            debugPrint('⚠️ [PostsPage] Removing duplicate listing ID "${listing.id}" from final list');
          }
        }
      }
      
      if (kDebugMode && finalDuplicates > 0) {
        debugPrint('⚠️ [PostsPage] Removed $finalDuplicates duplicate listings from final list');
      }
      
      debugPrint('✅ [PostsPage] Final list contains ${finalUniqueListings.length} unique listings');
      
      setState(() {
        _listings = finalUniqueListings.values.toList();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [PostsPage] Error loading listings: $e');
      debugPrint('❌ [PostsPage] Stack trace: $stackTrace');
      setState(() {
        _listings = [];
        _isLoading = false;
      });
    }
  }

  List<String> _getCategoryVariations(String categoryModelName) {
    // Map CategoryModel names to possible Firestore category values
    // Firestore may have variations, so return all possible matches
    switch (categoryModelName) {
      case 'Apartments':
        return ['Apartments', 'Apartment']; // Try both plural and singular
      case 'House Rentals':
        return ['House Rentals'];
      case 'Rooms':
        return ['Rooms'];
      case 'Boarding House':
        return ['Boarding House'];
      case 'Condo Rentals':
        return ['Condo Rentals'];
      case 'Student Dorms':
        return ['Student Dorms'];
      default:
        return [categoryModelName];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.category.name,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? _EmptyStateWidget(categoryName: widget.category.name)
              : RefreshIndicator(
                  onRefresh: _loadListings,
                  child: ListView.builder(
                    cacheExtent: 500,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _listings.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ModernListingCard(
                          listing: _listings[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ListingDetailsPage(listing: _listings[index]),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
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
                          ? _buildListingImage(
                              listing.imagePaths[0],
                              isDark: isDark,
                            )
                          : Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
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
                                  color: _themeColorDark,
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
                              debugPrint('🎨 [PostsPage UI] Displaying rating for ${listing.id}: reviewCount=${listing.reviewCount}, averageRating=${listing.averageRating}');
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
                                  color: _themeColorDark.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: _themeColorDark,
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
                          count: listing.reviewCount,
                          onTap: () {
                            debugPrint('🔍 [PostsPage] Comment icon tapped - reviewCount: ${listing.reviewCount}');
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

  Widget _buildListingImage(String imagePath, {required bool isDark}) {
    final isNetworkImage = imagePath.startsWith('http://') || 
                           imagePath.startsWith('https://');
    
    if (isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 800,
        memCacheHeight: 450,
        maxWidthDiskCache: 1200,
        maxHeightDiskCache: 675,
        placeholder: (context, url) => Container(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
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
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ),
      );
    } else {
      return Image(
        image: AssetImage(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          );
        },
      );
    }
  }

  void _showShareModal(BuildContext context, ListingModel listing) {
    final listingLink = 'https://rentease.app/listing/${listing.id}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB0B0B0),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;

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
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final String categoryName;

  const _EmptyStateWidget({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: subtextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No listings found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no $categoryName listings available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
