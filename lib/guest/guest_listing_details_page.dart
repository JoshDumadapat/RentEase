import 'package:flutter/material.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/guest/widgets/sign_in_required_modal.dart';

// Theme colors to match HomePage
const Color _themeColorLight = Color(0xFFE5F9FF);
const Color _themeColorLight2 = Color(0xFFB3F0FF);
const Color _themeColorDark = Color(0xFF00B8E6);

/// Guest Listing Details Page - Shows listing details without authentication
class GuestListingDetailsPage extends StatefulWidget {
  final ListingModel listing;

  const GuestListingDetailsPage({super.key, required this.listing});

  @override
  State<GuestListingDetailsPage> createState() => _GuestListingDetailsPageState();
}

class _GuestListingDetailsPageState extends State<GuestListingDetailsPage> {
  int _currentImageIndex = 0;
  
  // Dummy reviews for display
  final List<_Review> _dummyReviews = [
    _Review(
      reviewerName: 'Anna Lopez',
      rating: 5,
      comment: 'Beautiful and very clean apartment. The owner was responsive and helpful throughout our stay.',
      createdAt: DateTime(2024, 7, 12),
    ),
    _Review(
      reviewerName: 'Mark Reyes',
      rating: 4,
      comment: 'Great location and amenities. A bit noisy at night, but overall a good experience.',
      createdAt: DateTime(2024, 6, 28),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87),
              onPressed: () {
                SignInRequiredModal.show(
                  context,
                  message: 'Sign in to share this listing',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black87),
              onPressed: () {
                SignInRequiredModal.show(
                  context,
                  message: 'Sign in to save this listing to favorites',
                );
              },
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
                                      color: _themeColorLight,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.listing.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.listing.location,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[700]),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _themeColorDark,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/month',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TabBar(
                            labelColor: _themeColorDark,
                            unselectedLabelColor: Colors.grey[600],
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
                        onContactTap: () {
                          SignInRequiredModal.show(
                            context,
                            message: 'Sign in to contact the owner',
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                    child: _ReviewsSection(
                      reviews: _dummyReviews,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      SignInRequiredModal.show(
                        context,
                        message: 'Sign in to contact the owner',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Contact Owner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      SignInRequiredModal.show(
                        context,
                        message: 'Sign in to apply for this property',
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _themeColorDark,
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

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
              return Image.asset(
                images[index],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Details',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DetailItem(
                icon: Icons.bed,
                label: 'Bedrooms',
                value: '${listing.bedrooms}',
              ),
            ),
            Expanded(
              child: _DetailItem(
                icon: Icons.bathroom,
                label: 'Bathrooms',
                value: '${listing.bathrooms}',
              ),
            ),
            Expanded(
              child: _DetailItem(
                icon: Icons.square_foot,
                label: 'Area',
                value: '${listing.area.toStringAsFixed(0)}m²',
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

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: _themeColorDark),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }
}

class _OwnerSection extends StatelessWidget {
  final String ownerName;
  final bool isVerified;
  final VoidCallback onContactTap;

  const _OwnerSection({
    required this.ownerName,
    required this.isVerified,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeColorLight2.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _themeColorLight,
            child: Text(
              ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _themeColorDark,
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      ownerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 20, color: _themeColorDark),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onContactTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColorDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Contact'),
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

  const _ReviewsSection({required this.reviews});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final TextEditingController _controller = TextEditingController();
  final int _selectedRating = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.reviews.isEmpty)
          Text(
            'No reviews yet. Be the first to leave one!',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = widget.reviews[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _themeColorLight2.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
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
                          backgroundColor: _themeColorLight.withValues(alpha: 0.9),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        Text(
          'Add a review',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                SignInRequiredModal.show(
                  context,
                  message: 'Sign in to rate and review this property',
                );
              },
              icon: Icon(
                index < _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 3,
          readOnly: true,
          onTap: () {
            SignInRequiredModal.show(
              context,
              message: 'Sign in to add a review',
            );
          },
          decoration: const InputDecoration(
            hintText: 'Share your experience about this property',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {
              SignInRequiredModal.show(
                context,
                message: 'Sign in to submit your review',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _themeColorDark,
            ),
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

