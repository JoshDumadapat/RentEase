import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/review_model.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:rentease_app/backend/BFavoriteService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/backend/BReviewService.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/screens/listing_details/osm_location_view_page.dart';
import 'package:rentease_app/screens/profile/profile_page.dart';
import 'package:rentease_app/screens/chat/chats_list_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

// Theme colors to match HomePage
const Color _themeColorLight = Color(0xFFE5F9FF);
const Color _themeColorLight2 = Color(0xFFB3F0FF);
const Color _themeColorDark = Color(0xFF00B8E6);

class ListingDetailsPage extends StatefulWidget {
  final ListingModel listing;
  final int initialTab; // 0 for About, 1 for Review

  const ListingDetailsPage({
    super.key,
    required this.listing,
    this.initialTab = 0,
  });

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BReviewService _reviewService = BReviewService();
  final BUserService _userService = BUserService();

  // Realtime reviews from Firestore
  List<ReviewModel> _reviews = [];
  StreamSubscription<QuerySnapshot>? _reviewsSubscription;

  // Realtime listing data (for favorite count, review count, average rating)
  ListingModel? _currentListing;
  StreamSubscription<DocumentSnapshot>? _listingSubscription;

  double get _averageRating {
    // Calculate average rating from Firestore reviews
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(
      0.0,
      (accumulator, review) => accumulator + review.rating,
    );
    return total / _reviews.length;
  }

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
    _checkIfDraftAccess();
    _checkIfFavorite();
    _setupRealtimeListeners();
  }

  /// Check if user is trying to access a draft listing from another user
  /// If so, prevent access and navigate back
  void _checkIfDraftAccess() async {
    final currentUser = _auth.currentUser;
    final listing = widget.listing;
    
    // Check Firestore directly to see if this listing is a draft
    try {
      final doc = await _firestore.collection('listings').doc(listing.id).get();
      if (doc.exists) {
        final data = doc.data();
        final isDraft = data?['isDraft'] as bool? ?? false;
        final status = data?['status'] as String? ?? '';
        final listingUserId = data?['userId'] as String?;
        
        // If listing is a draft or has draft status, and current user is not the owner, prevent access
        if ((isDraft == true || status == 'draft') && 
            currentUser != null && 
            listingUserId != null && 
            listingUserId != currentUser.uid) {
          debugPrint('🚫 [ListingDetailsPage] Blocked access to draft listing ${listing.id} from user $listingUserId');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBarUtils.buildThemedSnackBar(
                  context,
                  'This listing is not available.',
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ListingDetailsPage] Error checking draft access: $e');
      // If check fails, allow access (fail open for better UX)
    }
  }



  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    _listingSubscription?.cancel();
    super.dispose();
  }

  /// Setup realtime Firestore listeners for reviews and listing data
  void _setupRealtimeListeners() {
    // Listen to reviews for this listing
    // Note: We query without orderBy to avoid composite index requirement,
    // then sort in memory
    _reviewsSubscription = _firestore
        .collection('reviews')
        .where('listingId', isEqualTo: widget.listing.id)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              try {
                debugPrint('📥 [ListingDetailsPage] Received reviews snapshot: ${snapshot.docs.length} reviews');
                
                // Convert to ReviewModel and sort by createdAt in memory (newest first)
                final reviews = snapshot.docs
                    .map((doc) {
                      try {
                        final data = doc.data();
                        debugPrint('📝 [ListingDetailsPage] Processing review: ${doc.id}, createdAt: ${data['createdAt']}');
                        return ReviewModel.fromMap({'id': doc.id, ...data});
                      } catch (e) {
                        debugPrint('❌ [ListingDetailsPage] Error parsing review doc ${doc.id}: $e');
                        return null;
                      }
                    })
                    .where((review) => review != null)
                    .cast<ReviewModel>()
                    .toList();

                // Sort by createdAt in memory (newest first)
                reviews.sort((a, b) {
                  final aDate = a.createdAt;
                  final bDate = b.createdAt;
                  return bDate.compareTo(aDate);
                });

                debugPrint('✅ [ListingDetailsPage] Updating reviews list: ${reviews.length} reviews');
                setState(() {
                  _reviews = reviews;
                });
              } catch (e, stackTrace) {
                debugPrint(
                  '❌ [ListingDetailsPage] Error processing reviews snapshot: $e',
                );
                debugPrint('Stack trace: $stackTrace');
              }
            }
          },
          onError: (error) {
            debugPrint(
              '❌ [ListingDetailsPage] Error listening to reviews: $error',
            );
            // Show error to user if needed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBarUtils.buildThemedSnackBar(
                  context,
                  'Error loading reviews. Please refresh.',
                ),
              );
            }
          },
        );

    // Listen to listing document for realtime updates (favorite count, review count, average rating)
    _listingSubscription = _firestore
        .collection('listings')
        .doc(widget.listing.id)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted && snapshot.exists) {
              final data = snapshot.data()!;
              try {
                final updatedListing = ListingModel.fromMap({
                  'id': snapshot.id,
                  ...data,
                });
                setState(() {
                  _currentListing = updatedListing;
                });
              } catch (e) {
                debugPrint(
                  '❌ [ListingDetailsPage] Error parsing listing update: $e',
                );
              }
            }
          },
          onError: (error) {
            debugPrint(
              '❌ [ListingDetailsPage] Error listening to listing: $error',
            );
          },
        );
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final favoriteService = BFavoriteService();
      final isFav = await favoriteService.isFavorite(
        user.uid,
        widget.listing.id,
      );

      setState(() {
        _isFavorite = isFav;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Please sign in to save favorites',
          ),
        );
      }
      return;
    }

    try {
      final favoriteService = BFavoriteService();
      final newFavoriteState = await favoriteService.toggleFavorite(
        userId: user.uid,
        listingId: widget.listing.id,
      );

      setState(() {
        _isFavorite = newFavoriteState;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            newFavoriteState ? 'Saved to favorites' : 'Removed from favorites',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> _copyListingLink() async {
    try {
      final listingLink = 'https://rentease.app/listing/${widget.listing.id}';
      await Clipboard.setData(ClipboardData(text: listingLink));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Link copied to clipboard',
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error copying link: $e'),
        );
      }
    }
  }

  void _openMapWithConfirmation(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Location'),
        content: Text('Do you want to view "$address" on the map?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OSMLocationViewPage(address: address),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareListing() async {
    try {
      final shareText =
          'Check out this property: ${widget.listing.title}\n'
          'Location: ${widget.listing.location}\n'
          'Price: \$${widget.listing.price.toStringAsFixed(0)}/month\n'
          'View listing: https://rentease.app/listing/${widget.listing.id}';

      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error sharing: $e'),
        );
      }
    }
  }

  void _reportListing(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Report Listing', style: TextStyle(color: textColor)),
        content: Text(
          'Are you sure you want to report this listing? Our team will review it.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBarUtils.buildThemedSnackBar(
                  context,
                  'Listing reported. Thank you for your feedback.',
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Show notification dialog when user tries to review a listing they've already reviewed
  void _showAlreadyReviewedDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = Colors.orange[700];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Already Reviewed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              'You have already submitted a review for this listing. Each user can only submit one review per property.',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Got it',
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.grey[300] : Colors.grey[700];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: iconColor,
                ),
                title: Text(
                  _isFavorite ? 'Remove from Favorites' : 'Save to Favorites',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite();
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: iconColor),
                title: Text('Copy link', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _copyListingLink();
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: iconColor),
                title: Text('Share', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _shareListing();
                },
              ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: iconColor),
                title: Text('Report', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _reportListing(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addReview(int rating, String comment) async {
    if (rating == 0 || comment.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Please sign in to add a review',
          ),
        );
      }
      return;
    }

    // Check if user has already reviewed this listing
    try {
      final hasReviewed = await _reviewService.hasUserReviewed(
        user.uid,
        widget.listing.id,
      );
      if (hasReviewed) {
        // Throw exception so modal can catch it and show error without closing
        throw Exception('ALREADY_REVIEWED');
      }

      // Get user's name for the review
      final userData = await _userService.getUserData(user.uid);
      final reviewerName =
          userData?['displayName'] as String? ??
          (userData?['fname'] != null && userData?['lname'] != null
              ? '${userData!['fname']} ${userData['lname']}'.trim()
              : userData?['fname'] as String? ??
                    userData?['lname'] as String?) ??
          user.displayName ??
          'Anonymous';

      // Create review in Firestore
      await _reviewService.createReview(
        userId: user.uid,
        listingId: widget.listing.id,
        reviewerName: reviewerName,
        rating: rating,
        comment: comment.trim(),
      );

      // The realtime listener will automatically update the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Review added successfully!',
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ListingDetailsPage] Error adding review: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // If it's the "already reviewed" exception, don't show snackbar here
      // Let the modal handle it
      if (e.toString().contains('ALREADY_REVIEWED')) {
        rethrow; // Re-throw so modal can handle it
      }
      
      if (mounted) {
        String errorMessage = 'Error adding review. Please try again.';
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission') || errorString.contains('denied')) {
          errorMessage = 'Permission denied. Please check your authentication.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            errorMessage,
          ),
        );
      }
      rethrow; // Re-throw so modal can handle it
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/chat.png',
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.chat_bubble_outline,
                    size: 22,
                    color: iconColor,
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
            ),
            const SizedBox(width: 2),
            IconButton(
              icon: Icon(Icons.more_vert, color: iconColor),
              onPressed: () => _showOptionsBottomSheet(context),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ImageCarousel(
                      images: widget.listing.imagePaths,
                      currentIndex: _currentImageIndex,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      listing: widget.listing,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? _themeColorDark.withValues(alpha: 0.25)
                                          : _themeColorLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.listing.category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(color: _themeColorDark),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.listing.timeAgo,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                              // Review count and star rating at the right end (only show if there are reviews)
                              if (_reviews.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Review count with icon
                                    Icon(
                                      Icons.chat_bubble_outline_outlined,
                                      size: 16,
                                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_reviews.length}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Star rating
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _averageRating.toStringAsFixed(1),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.listing.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: isDark ? Colors.white : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openMapWithConfirmation(widget.listing.location),
                                  child: Text(
                                    widget.listing.location,
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₱${widget.listing.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _themeColorDark,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/month',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TabBar(
                            labelColor: _themeColorDark,
                            unselectedLabelColor: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            indicatorColor: _themeColorDark,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: const [
                              Tab(text: 'About'),
                              Tab(text: 'Review'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ];
          },
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _PropertyDetailsSection(listing: widget.listing),
                      const SizedBox(height: 24),
                      _DescriptionSection(
                        description: widget.listing.description,
                      ),
                      const SizedBox(height: 24),
                      _OwnerSection(
                        userId: widget.listing.userId,
                        ownerName: widget.listing.ownerName, // Fallback
                        isVerified: widget.listing.isOwnerVerified,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _ReviewsSection(
                    reviews: _reviews,
                    onAddReview: _addReview,
                    parentContext: context,
                    onShowAlreadyReviewedDialog: _showAlreadyReviewedDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final Function(int) onPageChanged;
  final ListingModel listing;

  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.listing,
  });

  void _showFullScreenImage(
    BuildContext context,
    List<String> images,
    int initialIndex,
    ListingModel listing,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          listing: listing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final imagePath = images[index];
              final isNetworkImage =
                  imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://');

              return GestureDetector(
                onTap: () {
                  _showFullScreenImage(context, images, index, listing);
                },
                child: isNetworkImage
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        memCacheWidth: 1200,
                        memCacheHeight: 675,
                        maxWidthDiskCache: 1600,
                        maxHeightDiskCache: 900,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
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
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Image(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PropertyDetailsSection extends StatelessWidget {
  final ListingModel listing;

  const _PropertyDetailsSection({required this.listing});

  void _showAdditionalInfoModal(BuildContext context, ListingModel listing) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final backgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: subtextColor, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      if (listing.deposit != null)
                        _buildSimpleInfoRow(
                          Icons.account_balance_wallet_outlined,
                          'Deposit',
                          '₱${listing.deposit!.toStringAsFixed(0)}',
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      if (listing.advance != null)
                        _buildSimpleInfoRow(
                          Icons.payment_outlined,
                          'Advance Payment',
                          '₱${listing.advance!.toStringAsFixed(0)}',
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      if (listing.maxOccupants != null)
                        _buildSimpleInfoRow(
                          Icons.people_outline,
                          'Max Occupants',
                          '${listing.maxOccupants} person${listing.maxOccupants! > 1 ? 's' : ''}',
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      if (listing.curfew != null)
                        _buildSimpleInfoRow(
                          Icons.access_time_outlined,
                          'Curfew',
                          listing.curfew!,
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      if (listing.availableFrom != null)
                        _buildSimpleInfoRow(
                          Icons.calendar_today_outlined,
                          'Available From',
                          '${listing.availableFrom!.day}/${listing.availableFrom!.month}/${listing.availableFrom!.year}',
                          isDark,
                          textColor,
                          subtextColor,
                        ),
                      if (listing.landmark != null)
                        _buildSimpleInfoRow(
                          Icons.location_on_outlined,
                          'Landmark',
                          listing.landmark!,
                          isDark,
                          textColor,
                          subtextColor,
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

  void _showAmenitiesModal(
    BuildContext context,
    List<Map<String, dynamic>> amenities,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final backgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Amenities & Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: subtextColor, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: amenities.map((amenity) {
                      return _buildSimpleAmenityChip(
                        amenity['icon'] as IconData,
                        amenity['label'] as String,
                        isDark,
                        textColor,
                        subtextColor,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleInfoRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: _themeColorDark,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAmenityChip(
    IconData icon,
    String label,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: _themeColorDark,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];

    // Collect all amenities that are true
    final amenities = <Map<String, dynamic>>[];
    if (listing.wifi) {
      amenities.add({'icon': Icons.wifi, 'label': 'Free WiFi'});
    }
    if (listing.waterIncluded) {
      amenities.add({'icon': Icons.water_drop, 'label': 'Water Included'});
    }
    if (listing.electricityIncluded) {
      amenities.add({'icon': Icons.flash_on, 'label': 'Electricity Included'});
    }
    if (listing.internetIncluded) {
      amenities.add({'icon': Icons.language, 'label': 'Internet Included'});
    }
    if (listing.aircon) {
      amenities.add({'icon': Icons.ac_unit, 'label': 'Air Conditioning'});
    }
    if (listing.parking) {
      amenities.add({'icon': Icons.local_parking, 'label': 'Parking'});
    }
    if (listing.laundry) {
      amenities.add({'icon': Icons.local_laundry_service, 'label': 'Laundry'});
    }
    if (listing.security) {
      amenities.add({'icon': Icons.security, 'label': 'Security'});
    }
    if (listing.kitchenAccess) {
      amenities.add({'icon': Icons.kitchen, 'label': 'Kitchen Access'});
    }
    if (listing.privateCR) {
      amenities.add({'icon': Icons.bathroom, 'label': 'Private CR'});
    }
    if (listing.sharedCR) {
      amenities.add({'icon': Icons.wc, 'label': 'Shared CR'});
    }
    if (listing.petFriendly) {
      amenities.add({'icon': Icons.pets, 'label': 'Pet Friendly'});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        // Basic Details Row
        Row(
          children: [
            Expanded(
              child: _DetailItem(
                icon: Icons.bed,
                label: 'Bedrooms',
                value: listing.bedrooms.toString(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DetailItem(
                icon: Icons.bathroom,
                label: 'Bathrooms',
                value: listing.bathrooms.toString(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DetailItem(
                icon: Icons.square_foot,
                label: 'Area',
                value: '${listing.area.toStringAsFixed(0)} m²',
              ),
            ),
          ],
        ),
        // Additional Details - Clickable Card
        if (listing.deposit != null ||
            listing.advance != null ||
            listing.maxOccupants != null ||
            listing.curfew != null ||
            listing.availableFrom != null) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _showAdditionalInfoModal(context, listing),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _themeColorDark, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Information',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view details',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subtextColor),
                ],
              ),
            ),
          ),
        ],
        // Amenities - Clickable Card
        if (amenities.isNotEmpty) ...[
          const SizedBox(height: 24),
          InkWell(
            onTap: () => _showAmenitiesModal(context, amenities),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.room_service, color: _themeColorDark, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amenities',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${amenities.length} amenities available',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subtextColor),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}


class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _themeColorDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: _themeColorDark),
        ),
        const SizedBox(height: 8),
        // Value
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        // Label
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: subtextColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[700];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: subtextColor, height: 1.5),
        ),
      ],
    );
  }
}

class _OwnerSection extends StatefulWidget {
  final String? userId;
  final String ownerName; // Fallback name
  final bool isVerified;

  const _OwnerSection({
    required this.userId,
    required this.ownerName,
    required this.isVerified,
  });

  @override
  State<_OwnerSection> createState() => _OwnerSectionState();
}

class _OwnerSectionState extends State<_OwnerSection> {
  String? _username;
  String? _profileImageUrl;
  bool _isLoading = true;
  final BUserService _userService = BUserService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userData = await _userService.getUserData(widget.userId!);
      if (userData != null && mounted) {
        setState(() {
          _username = userData['username'] as String?;
          _profileImageUrl = userData['profileImageUrl'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [OwnerSection] Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  _themeColorDark.withValues(alpha: 0.15),
                  _themeColorDark.withValues(alpha: 0.08),
                  const Color(0xFF4A4A4A),
                ]
              : [
                  _themeColorLight2.withValues(alpha: 0.4),
                  _themeColorLight.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? _themeColorDark.withValues(alpha: 0.3)
              : _themeColorDark.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : _themeColorDark.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        _themeColorDark.withValues(alpha: 0.3),
                        _themeColorDark.withValues(alpha: 0.15),
                      ]
                    : [_themeColorLight, _themeColorLight2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? _themeColorDark.withValues(alpha: 0.4)
                    : _themeColorDark.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _profileImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      placeholder: (context, url) => CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          (_username ?? widget.ownerName.split(' ').first)[0]
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : _themeColorDark,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          (_username ?? widget.ownerName.split(' ').first)[0]
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : _themeColorDark,
                          ),
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      (_username ?? widget.ownerName.split(' ').first)[0]
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : _themeColorDark,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Listed by',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: subtextColor),
                    ),
                    if (widget.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _themeColorDark.withValues(
                            alpha: 0.2,
                          ), // Glowing blue background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: _themeColorDark, // Blue icon
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _themeColorDark,
                        ),
                      )
                    : Text(
                        _username ?? widget.ownerName.split(' ').first,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [_themeColorDark, _themeColorDark.withValues(alpha: 0.8)]
                    : [_themeColorDark, _themeColorDark.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _themeColorDark.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (widget.userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: widget.userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBarUtils.buildThemedSnackBar(
                      context,
                      'User information not available',
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  final List<ReviewModel> reviews;
  final Future<void> Function(int rating, String comment) onAddReview;
  final BuildContext parentContext;
  final void Function(BuildContext) onShowAlreadyReviewedDialog;

  const _ReviewsSection({
    required this.reviews,
    required this.onAddReview,
    required this.parentContext,
    required this.onShowAlreadyReviewedDialog,
  });

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final TextEditingController _controller = TextEditingController();
  int _selectedRating = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddReviewModal() {
    final modalContext = widget.parentContext;
    final theme = Theme.of(modalContext);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    // Local state for the modal
    int modalRating = _selectedRating;
    final TextEditingController modalController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add a review',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: isSubmitting
                            ? null
                            : () {
                                Navigator.pop(context);
                                // Dispose controller after modal animation completes
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  try {
                                    modalController.dispose();
                                  } catch (e) {
                                    // Controller already disposed or not attached
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (index) => GestureDetector(
                        onTap: isSubmitting
                            ? null
                            : () {
                                setModalState(() {
                                  modalRating = index + 1;
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < modalRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: modalController,
                    maxLines: 5,
                    enabled: !isSubmitting,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Share your experience about this property',
                      hintStyle: TextStyle(color: subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _themeColorDark, width: 1.5),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _themeColorDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final modalContext = context; // Modal's context
                              final parentContext = widget.parentContext; // Main page context
                              
                              if (modalRating == 0 || modalController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(modalContext).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Please provide a rating and comment',
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                  ),
                                );
                                return;
                              }
                              
                              final reviewText = modalController.text.trim();
                              final reviewRating = modalRating;
                              
                              // Set submitting state to disable interactions
                              setModalState(() {
                                isSubmitting = true;
                              });
                              
                              try {
                                // Call the review function which will check for duplicates
                                await widget.onAddReview(reviewRating, reviewText);
                                
                                // If successful, close modal and update state
                                if (modalContext.mounted) {
                                  Navigator.pop(modalContext);
                                  // Dispose controller after modal animation completes
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    try {
                                      modalController.dispose();
                                    } catch (e) {
                                      // Controller already disposed or not attached
                                    }
                                  });
                                }
                                
                                // Update local state if widget is still mounted
                                if (mounted) {
                                  setState(() {
                                    _selectedRating = 0;
                                    _controller.clear();
                                  });
                                }
                              } catch (e) {
                                debugPrint('❌ [AddReviewModal] Error adding review: $e');
                                
                                // Re-enable interactions on error
                                if (modalContext.mounted) {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                  
                                  // Show error notification
                                  if (e.toString().contains('ALREADY_REVIEWED')) {
                                    // Close the review modal first
                                    Navigator.pop(modalContext);
                                    // Then show notification dialog for already reviewed error
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (parentContext.mounted) {
                                        widget.onShowAlreadyReviewedDialog(parentContext);
                                      }
                                    });
                                  } else {
                                    // Show snackbar for other errors
                                    String errorMessage = 'Error adding review. Please try again.';
                                    final errorString = e.toString().toLowerCase();
                                    if (errorString.contains('permission') || errorString.contains('denied')) {
                                      errorMessage = 'Permission denied. Please check your authentication.';
                                    } else if (errorString.contains('network') || errorString.contains('connection')) {
                                      errorMessage = 'Network error. Please check your connection and try again.';
                                    }
                                    
                                    ScaffoldMessenger.of(modalContext).showSnackBar(
                                      SnackBarUtils.buildThemedSnackBar(
                                        modalContext,
                                        errorMessage,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      // Dispose controller after modal is fully closed
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          modalController.dispose();
        } catch (e) {
          // Controller already disposed or not attached
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDark
        ? Colors.grey[700]!
        : _themeColorLight2.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: _themeColorDark,
                size: 24,
              ),
              onPressed: _showAddReviewModal,
              tooltip: 'Add Review',
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scrollable reviews list
        Expanded(
          child: widget.reviews.isEmpty
              ? Center(
                  child: Text(
                    'No reviews yet. Be the first to leave one!',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: subtextColor),
                  ),
                )
              : ListView.separated(
                  itemCount: widget.reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = widget.reviews[index];
                    return Container(
                      key: ValueKey('review_${review.id}_$index'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.03,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: _themeColorLight.withValues(
                                  alpha: 0.9,
                                ),
                                child: Text(
                                  review.reviewerName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _themeColorDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.reviewerName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _themeColorLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      review.rating.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _themeColorDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < review.rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review.comment,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: textColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final ListingModel listing;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.listing,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Initialize transformation controllers for all images
    for (int i = 0; i < widget.images.length; i++) {
      _transformationControllers[i] = TransformationController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDoubleTap(
    TransformationController controller,
    TapDownDetails details,
  ) {
    final position = details.localPosition;
    final scale = controller.value.getMaxScaleOnAxis();

    if (scale > 1.0) {
      // Zoom out with smooth animation
      final animation =
          Matrix4Tween(
            begin: controller.value,
            end: Matrix4.identity(),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );

      animation.addListener(() {
        controller.value = animation.value;
      });

      _animationController.reset();
      _animationController.forward();
    } else {
      // Zoom in to 2x at tap position with smooth animation
      final newScale = 2.0;
      final x = -position.dx * (newScale - 1);
      final y = -position.dy * (newScale - 1);
      final endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(newScale);

      final animation = Matrix4Tween(begin: controller.value, end: endMatrix)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          );

      animation.addListener(() {
        controller.value = animation.value;
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  void _resetZoomForIndex(int index) {
    final controller = _transformationControllers[index];
    if (controller != null) {
      controller.value = Matrix4.identity();
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.grey[300] : Colors.grey[700];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.download, color: iconColor),
                title: Text('Save Photo', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _savePhoto(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: iconColor),
                title: Text('Copy link', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _copyListingLink();
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: iconColor),
                title: Text('Share', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _shareListing();
                },
              ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: iconColor),
                title: Text('Report Photo', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _reportPhoto(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePhoto(BuildContext context) async {
    try {
      // Request storage permission (for Android < 13) or photos permission (for Android 13+)
      PermissionStatus status;
      if (Platform.isAndroid) {
        // For Android 13+, use photos permission
        status = await Permission.photos.request();
        if (!status.isGranted) {
          // Fallback to storage for older Android versions
          status = await Permission.storage.request();
        }
      } else {
        // For iOS, use photos permission
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Permission is required to save photos',
            ),
          );
        }
        return;
      }

      final imagePath = widget.images[_currentIndex];
      final isNetworkImage =
          imagePath.startsWith('http://') || imagePath.startsWith('https://');

      if (isNetworkImage) {
        // Save network image directly using gallery_saver_plus
        final success = await GallerySaver.saveImage(imagePath);
        if (mounted) {
          if (success == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBarUtils.buildThemedSnackBar(
                context,
                'Photo saved to gallery',
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBarUtils.buildThemedSnackBar(
                context,
                'Failed to save photo',
              ),
            );
          }
        }
      } else {
        // For asset images, we need to load them differently
        // This is a limitation - asset images can't be easily saved
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Saving asset images is not supported',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error saving photo: $e'),
        );
      }
    }
  }

  Future<void> _copyListingLink() async {
    try {
      final listingLink = 'https://rentease.app/listing/${widget.listing.id}';
      await Clipboard.setData(ClipboardData(text: listingLink));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Link copied to clipboard',
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error copying link: $e'),
        );
      }
    }
  }

  Future<void> _shareListing() async {
    try {
      // Create shareable link (you can customize this URL format)
      final shareText =
          'Check out this property: ${widget.listing.title}\n'
          'Location: ${widget.listing.location}\n'
          'Price: \$${widget.listing.price.toStringAsFixed(0)}/month\n'
          'View listing: https://rentease.app/listing/${widget.listing.id}';

      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error sharing: $e'),
        );
      }
    }
  }

  void _reportPhoto(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Report Photo', style: TextStyle(color: textColor)),
        content: Text(
          'Are you sure you want to report this photo? Our team will review it.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBarUtils.buildThemedSnackBar(
                  context,
                  'Photo reported. Thank you for your feedback.',
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              // Reset zoom for the previous image
              _resetZoomForIndex(_currentIndex);
              setState(() {
                _currentIndex = index;
              });
              // Reset zoom for the new image (in case it was zoomed before)
              _resetZoomForIndex(index);
            },
            itemBuilder: (context, index) {
              final imagePath = widget.images[index];
              final isNetworkImage =
                  imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://');
              final controller = _transformationControllers[index]!;

              return GestureDetector(
                onDoubleTapDown: (details) =>
                    _handleDoubleTap(controller, details),
                child: InteractiveViewer(
                  transformationController: controller,
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: isNetworkImage
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image(
                            image: AssetImage(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Colors.grey,
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
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Three-dot menu
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => _showOptionsBottomSheet(context),
                  ),
                ],
              ),
            ),
          ),
          // Image counter centered at bottom
          if (widget.images.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
