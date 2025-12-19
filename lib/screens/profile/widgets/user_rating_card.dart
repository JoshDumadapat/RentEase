import 'package:flutter/material.dart';
import 'package:rentease_app/backend/BReviewService.dart';

const Color _themeColorDark = Color(0xFF00B8E6);

/// User Rating Card Widget
/// 
/// Displays the average rating across all user's listings
/// Card is half the height of property/fav post cards
class UserRatingCard extends StatefulWidget {
  final String userId;
  final List<String> listingIds; // List of all user's listing IDs

  const UserRatingCard({
    super.key,
    required this.userId,
    required this.listingIds,
  });

  @override
  State<UserRatingCard> createState() => _UserRatingCardState();
}

class _UserRatingCardState extends State<UserRatingCard> {
  final BReviewService _reviewService = BReviewService();
  double _averageRating = 0.0;
  int _totalReviewCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRating();
  }

  @override
  void didUpdateWidget(UserRatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingIds.length != widget.listingIds.length ||
        oldWidget.listingIds != widget.listingIds) {
      _loadUserRating();
    }
  }

  Future<void> _loadUserRating() async {
    if (widget.listingIds.isEmpty) {
      setState(() {
        _averageRating = 0.0;
        _totalReviewCount = 0;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double totalRating = 0.0;
      int totalReviews = 0;
      int listingsWithReviews = 0;

      // Calculate average rating across all listings
      for (final listingId in widget.listingIds) {
        try {
          final count = await _reviewService.getReviewCount(listingId);
          if (count > 0) {
            final avgRating = await _reviewService.getAverageRating(listingId);
            totalRating += avgRating * count;
            totalReviews += count;
            listingsWithReviews++;
          }
        } catch (e) {
          debugPrint('⚠️ [UserRatingCard] Error loading rating for listing $listingId: $e');
        }
      }

      final overallAverage = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      if (mounted) {
        setState(() {
          _averageRating = overallAverage;
          _totalReviewCount = totalReviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [UserRatingCard] Error loading user rating: $e');
      if (mounted) {
        setState(() {
          _averageRating = 0.0;
          _totalReviewCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];

    // Half height of property cards (property cards are typically ~140-160px, so half is ~70-80px)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Star icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _themeColorDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.star_rounded,
                color: _themeColorDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Rating info - use Expanded to prevent overflow
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'User Rating',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _themeColorDark,
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Rating number - can shrink if needed
                            Flexible(
                              child: Text(
                                _averageRating > 0
                                    ? _averageRating.toStringAsFixed(1)
                                    : 'N/A',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (_averageRating > 0) ...[
                              const SizedBox(width: 4),
                              // Star icon - fixed size
                              Icon(
                                Icons.star_rounded,
                                color: _themeColorDark,
                                size: 18,
                              ),
                              if (_totalReviewCount > 0) ...[
                                const SizedBox(width: 6),
                                // Review count - can shrink and truncate
                                Flexible(
                                  child: Text(
                                    '(${_totalReviewCount} ${_totalReviewCount == 1 ? 'review' : 'reviews'})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtextColor,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
