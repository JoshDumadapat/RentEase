import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BReviewService.dart';
import 'package:rentease_app/screens/profile/widgets/followers_list_section.dart';

/// User Stats Section Widget
/// 
/// Displays user activity statistics:
/// - User rating
/// - Number of properties listed
/// - Number of favorites/saved properties
/// - Number of looking for posts
class UserStatsSection extends StatefulWidget {
  final UserModel user;
  final Function(String)? onStatTap;
  final List<String> listingIds;
  final bool hideFavorites; // Hide favorites tab for visitors

  const UserStatsSection({
    super.key,
    required this.user,
    this.onStatTap,
    required this.listingIds,
    this.hideFavorites = false,
  });

  @override
  State<UserStatsSection> createState() => _UserStatsSectionState();
}

class _UserStatsSectionState extends State<UserStatsSection> {
  final BReviewService _reviewService = BReviewService();
  final ScrollController _scrollController = ScrollController();
  double _averageRating = 0.0;
  int _totalReviewCount = 0;
  bool _isLoadingRating = true;
  double _scrollPosition = 0.0;
  double _maxScrollExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserRating();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      setState(() {
        _scrollPosition = _scrollController.position.pixels;
        _maxScrollExtent = _scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  void didUpdateWidget(UserStatsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingIds.length != widget.listingIds.length ||
        oldWidget.listingIds != widget.listingIds) {
      _loadUserRating();
    }
  }

  void _showFollowersModal(BuildContext context, String userId) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Followers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Followers list
              Expanded(
                child: FollowersListModal(userId: userId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserRating() async {
    if (widget.listingIds.isEmpty) {
      setState(() {
        _averageRating = 0.0;
        _totalReviewCount = 0;
        _isLoadingRating = false;
      });
      return;
    }

    setState(() {
      _isLoadingRating = true;
    });

    try {
      double totalRating = 0.0;
      int totalReviews = 0;

      for (final listingId in widget.listingIds) {
        try {
          final count = await _reviewService.getReviewCount(listingId);
          if (count > 0) {
            final avgRating = await _reviewService.getAverageRating(listingId);
            totalRating += avgRating * count;
            totalReviews += count;
          }
        } catch (e) {
          debugPrint('⚠️ [UserStatsSection] Error loading rating for listing $listingId: $e');
        }
      }

      final overallAverage = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      if (mounted) {
        setState(() {
          _averageRating = overallAverage;
          _totalReviewCount = totalReviews;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [UserStatsSection] Error loading user rating: $e');
      if (mounted) {
        setState(() {
          _averageRating = 0.0;
          _totalReviewCount = 0;
          _isLoadingRating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate width based on original 3-card layout
    // (screen width - padding*2 - spacing*2) / 3
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 24.0 * 2; // left and right padding
    final spacing = 12.0 * 2; // spacing between 3 cards
    final cardWidth = (screenWidth - padding - spacing) / 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Carousel (horizontal scrollable)
          SizedBox(
            height: 130, // Increased height to accommodate rating card with subtext
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              children: [
                _StatTile(
                  label: 'Properties',
                  value: widget.user.propertiesCount.toString(),
                  iconPath: 'assets/icons/navbar/home_outlined.svg',
                  isDark: isDark,
                  width: cardWidth,
                  onTap: widget.onStatTap != null ? () => widget.onStatTap!('properties') : null,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: 'Posts',
                  value: widget.user.lookingForPostsCount.toString(),
                  icon: Icons.post_add_outlined,
                  isDark: isDark,
                  width: cardWidth,
                  onTap: widget.onStatTap != null ? () => widget.onStatTap!('lookingFor') : null,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: 'Followers',
                  value: (widget.user.followersCount ?? 0).toString(),
                  icon: Icons.people_outline,
                  isDark: isDark,
                  width: cardWidth,
                  onTap: () => _showFollowersModal(context, widget.user.id),
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: 'Rating',
                  value: _isLoadingRating
                      ? '...'
                      : (_averageRating > 0
                          ? _averageRating.toStringAsFixed(1)
                          : 'N/A'),
                  icon: Icons.star_rounded,
                  isDark: isDark,
                  width: cardWidth,
                  showSubtext: !_isLoadingRating && _averageRating > 0 && _totalReviewCount > 0,
                  subtext: _totalReviewCount == 1 ? '1 review' : '$_totalReviewCount reviews',
                ),
                if (!widget.hideFavorites) ...[
                  const SizedBox(width: 12),
                  _StatTile(
                    label: 'Favorites',
                    value: widget.user.favoritesCount.toString(),
                    iconPath: 'assets/icons/navbar/heart_outlined.svg',
                    isDark: isDark,
                    width: cardWidth,
                    onTap: widget.onStatTap != null ? () => widget.onStatTap!('favorites') : null,
                  ),
                ],
              ],
            ),
          ),
          // Scroll indicator bar
          if (_maxScrollExtent > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _ScrollIndicator(
                scrollPosition: _scrollPosition,
                maxScrollExtent: _maxScrollExtent,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? iconPath;
  final IconData? icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool showSubtext;
  final String? subtext;
  final double width;

  const _StatTile({
    required this.label,
    required this.value,
    this.iconPath,
    this.icon,
    required this.isDark,
    this.onTap,
    this.showSubtext = false,
    this.subtext,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final statTileWidget = Container(
      width: width, // Width calculated to fit 3 cards originally
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
      child: Column(
        mainAxisSize: MainAxisSize.min, // Minimize vertical space
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconPath != null
              ? SvgPicture.asset(
                  iconPath!,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF00B8E6),
                    BlendMode.srcIn,
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF00B8E6),
                ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (showSubtext && subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext!,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: statTileWidget,
      );
    }

    return statTileWidget;
  }
}

class _ScrollIndicator extends StatelessWidget {
  final double scrollPosition;
  final double maxScrollExtent;
  final bool isDark;

  const _ScrollIndicator({
    required this.scrollPosition,
    required this.maxScrollExtent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxScrollExtent > 0
        ? (scrollPosition / maxScrollExtent).clamp(0.0, 1.0)
        : 0.0;
    final indicatorWidth = 40.0;
    final totalWidth = MediaQuery.of(context).size.width - 48.0; // Account for padding
    final leftPosition = progress * (totalWidth - indicatorWidth);

    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          // Background track
          Container(
            width: totalWidth,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.3)
                  : Colors.grey[300]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          // Progress indicator
          Positioned(
            left: leftPosition,
            child: Container(
              width: indicatorWidth,
              height: 3,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[400]!.withValues(alpha: 0.6)
                    : Colors.grey[600]!.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

