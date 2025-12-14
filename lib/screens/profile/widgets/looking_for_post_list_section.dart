import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';

const Color _themeColorDark = Color(0xFF00B8E6);

/// Looking For Post List Section Widget
/// 
/// Displays user's "Looking For" posts:
/// - List of posts with details
/// - Tap to open post details
/// - Edit/delete actions per post
class LookingForPostListSection extends StatelessWidget {
  final List<LookingForPostModel> posts;
  final Function(LookingForPostModel) onPostTap;
  final Function(LookingForPostModel)? onEdit;
  final Function(LookingForPostModel)? onDelete;

  const LookingForPostListSection({
    super.key,
    required this.posts,
    required this.onPostTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (posts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _themeColorDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${posts.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _themeColorDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Posts List
            posts.isEmpty
                ? Center(
                    child: _EmptyState(
                      message: 'No posts yet',
                      subtitle: 'Create your first "Looking For" post',
                      isDark: isDark,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 0),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _LookingForPostTile(
                        post: post,
                        onTap: () => onPostTap(post),
                        onEdit: onEdit != null ? () => onEdit!(post) : null,
                        onDelete: onDelete != null ? () => onDelete!(post) : null,
                        isDark: isDark,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _LookingForPostTile extends StatelessWidget {
  final LookingForPostModel post;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDark;

  const _LookingForPostTile({
    required this.post,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    required this.isDark,
  });

  void _showMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

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
              if (onEdit != null)
                ListTile(
                  leading: Icon(Icons.edit, color: textColor),
                  title: Text(
                    'Edit',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoveInDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays < 0) {
      return 'Past due';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return 'In ${(difference.inDays / 7).floor()}w';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final themeColor = const Color(0xFF00B8E6);
    final themeColorLight = themeColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Property Type Badge + Menu
                Row(
                  children: [
                    // Property Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 14,
                            color: themeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.propertyType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Menu Button
                    if (onEdit != null || onDelete != null)
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: subtextColor,
                        ),
                        onPressed: () => _showMenu(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  post.description,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Info Row: Location, Budget, Move-in Date
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    // Location
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Budget
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money_outlined,
                          size: 16,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.budget,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Move-in Date (if available)
                    if (post.moveInDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: subtextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatMoveInDate(post.moveInDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Footer: Stats + Time
                Row(
                  children: [
                    // Stats
                    if (post.likeCount > 0 || post.commentCount > 0)
                      Row(
                        children: [
                          if (post.likeCount > 0) ...[
                            Icon(
                              Icons.favorite_outline,
                              size: 14,
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
                            const SizedBox(width: 12),
                          ],
                          if (post.commentCount > 0) ...[
                            Icon(
                              Icons.comment_outlined,
                              size: 14,
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
                    const Spacer(),
                    // Time Ago
                    Text(
                      post.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.message,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _themeColorDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_outlined,
              size: 48,
              color: _themeColorDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
