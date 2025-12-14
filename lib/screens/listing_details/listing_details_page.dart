import 'package:flutter/material.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

// Theme colors to match HomePage
const Color _themeColorLight = Color(0xFFE5F9FF);
const Color _themeColorLight2 = Color(0xFFB3F0FF);
const Color _themeColorDark = Color(0xFF00B8E6);

class ListingDetailsPage extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailsPage({super.key, required this.listing});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final List<_Review> _reviews = [
    _Review(
      reviewerName: 'Anna Lopez',
      rating: 5,
      comment:
          'Beautiful and very clean apartment. The owner was responsive and helpful throughout our stay.',
      createdAt: DateTime(2024, 7, 12),
    ),
    _Review(
      reviewerName: 'Mark Reyes',
      rating: 4,
      comment:
          'Great location and amenities. A bit noisy at night, but overall a good experience.',
      createdAt: DateTime(2024, 6, 28),
    ),
  ];

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / _reviews.length;
  }

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isCheckingFavorite = false;
      });
      return;
    }

    try {
      final favoriteDoc = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('listingId', isEqualTo: widget.listing.id)
          .limit(1)
          .get();

      setState(() {
        _isFavorite = favoriteDoc.docs.isNotEmpty;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Please sign in to save favorites'),
        );
      }
      return;
    }

    try {
      if (_isFavorite) {
        // Remove from favorites
        final favoriteDoc = await _firestore
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('listingId', isEqualTo: widget.listing.id)
            .limit(1)
            .get();

        for (var doc in favoriteDoc.docs) {
          await doc.reference.delete();
        }

        setState(() {
          _isFavorite = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Removed from favorites'),
          );
        }
      } else {
        // Add to favorites
        await _firestore.collection('favorites').add({
          'userId': user.uid,
          'listingId': widget.listing.id,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isFavorite = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to favorites')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error: ${e.toString()}'),
        );
      }
    }
  }

  Future<void> _shareListing() async {
    try {
      final shareText = 'Check out this property: ${widget.listing.title}\n'
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
                SnackBarUtils.buildThemedSnackBar(context, 'Listing reported. Thank you for your feedback.'),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
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

  void _addReview(int rating, String comment) {
    if (rating == 0 || comment.trim().isEmpty) return;
    setState(() {
      _reviews.add(
        _Review(
          reviewerName: 'You',
          rating: rating,
          comment: comment.trim(),
          createdAt: DateTime.now(),
        ),
      );
    });
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
                                          ? _themeColorDark.withOpacity(0.25)
                                          : _themeColorLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.listing.category,
                                      style: Theme.of(context).textTheme.labelMedium
                                          ?.copyWith(color: _themeColorDark),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.listing.timeAgo,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: isDark ? Colors.grey[300] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_outlined,
                                    size: 16,
                                    color: isDark ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_reviews.length} reviews',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: isDark ? Colors.grey[300] : Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _reviews.isEmpty
                                        ? '-'
                                        : _averageRating.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodySmall,
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
                                child: Text(
                                  widget.listing.location,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: isDark ? Colors.grey[300] : Colors.grey[700]),
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
                                    ?.copyWith(color: isDark ? Colors.grey[300] : Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TabBar(
                            labelColor: _themeColorDark,
                            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        ownerName: widget.listing.ownerName,
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

  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex, ListingModel listing) {
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
              return GestureDetector(
                onTap: () {
                  _showFullScreenImage(context, images, index, listing);
                },
                child: Image(
                  image: AssetImage(images[index]),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, size: 80, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? dateText;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
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
          child: Icon(
            icon,
            size: 20,
            color: _themeColorDark,
          ),
        ),
        const SizedBox(height: 8),
        // Value
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: subtextColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _OwnerSection extends StatelessWidget {
  final String ownerName;
  final bool isVerified;

  const _OwnerSection({required this.ownerName, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[800] : _themeColorLight2.withValues(alpha: 0.25);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  _themeColorDark.withOpacity(0.15),
                  _themeColorDark.withOpacity(0.08),
                  const Color(0xFF4A4A4A),
                ]
              : [
                  _themeColorLight2.withOpacity(0.4),
                  _themeColorLight.withOpacity(0.3),
                  Colors.white.withOpacity(0.5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? _themeColorDark.withOpacity(0.3)
              : _themeColorDark.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : _themeColorDark.withOpacity(0.1),
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
                        _themeColorDark.withOpacity(0.3),
                        _themeColorDark.withOpacity(0.15),
                      ]
                    : [
                        _themeColorLight,
                        _themeColorLight2,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? _themeColorDark.withOpacity(0.4)
                    : _themeColorDark.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              child: Text(
                ownerName[0].toUpperCase(),
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
                Text(
                  'Listed by',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtextColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      ownerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _themeColorDark.withOpacity(0.2), // Glowing blue background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 18,
                          color: _themeColorDark, // Blue icon
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        _themeColorDark,
                        _themeColorDark.withOpacity(0.8),
                      ]
                    : [
                        _themeColorDark,
                        _themeColorDark.withOpacity(0.9),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _themeColorDark.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBarUtils.buildThemedSnackBar(context, 'Contact feature coming soon!'),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Contact',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Review {
  final String reviewerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  _Review({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class _ReviewsSection extends StatefulWidget {
  final List<_Review> reviews;
  final void Function(int rating, String comment) onAddReview;

  const _ReviewsSection({required this.reviews, required this.onAddReview});

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

  void _showAddReviewModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  onPressed: () => Navigator.pop(context),
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
                (index) => IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 32,
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
              controller: _controller,
              maxLines: 5,
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
                  borderSide: BorderSide(
                    color: _themeColorDark,
                    width: 1.5,
                  ),
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
                onPressed: () {
                  if (_selectedRating == 0 || _controller.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please provide a rating and comment'),
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                    );
                    return;
                  }
                  widget.onAddReview(_selectedRating, _controller.text);
                  _controller.clear();
                  setState(() {
                    _selectedRating = 0;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Review added successfully!'),
                      backgroundColor: _themeColorDark,
                    ),
                  );
                },
                child: const Text(
                  'Submit Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : _themeColorLight2.withValues(alpha: 0.6);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reviews',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(
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
              onPressed: () => _showAddReviewModal(context),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
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

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> with SingleTickerProviderStateMixin {
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

  void _handleDoubleTap(TransformationController controller, TapDownDetails details) {
    final position = details.localPosition;
    final scale = controller.value.getMaxScaleOnAxis();
    
    if (scale > 1.0) {
      // Zoom out with smooth animation
      final animation = Matrix4Tween(
        begin: controller.value,
        end: Matrix4.identity(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      
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
      
      final animation = Matrix4Tween(
        begin: controller.value,
        end: endMatrix,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      
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
                leading: Icon(Icons.share, color: iconColor),
                title: Text('Share', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _shareListing(context);
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
            SnackBarUtils.buildThemedSnackBar(context, 'Permission is required to save photos'),
          );
        }
        return;
      }

      final imagePath = widget.images[_currentIndex];
      final isNetworkImage = imagePath.startsWith('http://') || 
                             imagePath.startsWith('https://');

      if (isNetworkImage) {
        // Download network image
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode == 200) {
          final result = await ImageGallerySaver.saveImage(
            response.bodyBytes,
            quality: 100,
          );
          if (mounted && result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBarUtils.buildThemedSnackBar(context, 'Photo saved to gallery'),
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBarUtils.buildThemedSnackBar(context, 'Failed to save photo'),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBarUtils.buildThemedSnackBar(context, 'Failed to download photo'),
            );
          }
        }
      } else {
        // For asset images, we need to load them differently
        // This is a limitation - asset images can't be easily saved
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Saving asset images is not supported'),
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

  Future<void> _shareListing(BuildContext context) async {
    try {
      // Create shareable link (you can customize this URL format)
      final shareText = 'Check out this property: ${widget.listing.title}\n'
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
                SnackBarUtils.buildThemedSnackBar(context, 'Photo reported. Thank you for your feedback.'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              final isNetworkImage = imagePath.startsWith('http://') || 
                                     imagePath.startsWith('https://');
              final controller = _transformationControllers[index]!;
              
              return GestureDetector(
                onDoubleTapDown: (details) => _handleDoubleTap(controller, details),
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
                                value: loadingProgress.expectedTotalBytes != null
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
                      color: Colors.black.withOpacity(0.5),
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

