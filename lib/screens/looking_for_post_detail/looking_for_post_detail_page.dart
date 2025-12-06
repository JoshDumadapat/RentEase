import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/models/comment_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';

// Theme colors aligned with Home and Listing details review cards
const Color _themeColorLight = Color(0xFFE5F9FF);
const Color _themeColorDark = Color(0xFF00B8E6);

class LookingForPostDetailPage extends StatefulWidget {
  final LookingForPostModel post;

  const LookingForPostDetailPage({
    super.key,
    required this.post,
  });

  @override
  State<LookingForPostDetailPage> createState() => _LookingForPostDetailPageState();
}

class _LookingForPostDetailPageState extends State<LookingForPostDetailPage> {
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scrollable Content (Post + Comments)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    padding: const EdgeInsets.only(bottom: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Header
                        _PostHeader(
                          post: widget.post,
                          onMoreTap: _showPostOptions,
                        ),

                        // Post Body
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Text(
                            widget.post.description,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                              height: 1.6,
                            ),
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

                        // Action Bar
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
                        ),

                        // Comments List (inside same card)
                        _CommentsList(
                          comments: _comments,
                          onPropertyTap: (listingId) {
                            final allListings = ListingModel.getMockListings();
                            final listing = allListings.firstWhere(
                              (l) => l.id == listingId,
                              orElse: () => allListings.first,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListingDetailsPage(listing: listing),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Fixed Comment Input at Bottom (Facebook-style)
          _FixedCommentInput(
            onCommentAdded: (commentText, propertyListingId) {
              setState(() {
                _commentCount++;
                // Add new comment to the list
                final newComment = CommentModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  username: 'You',
                  text: commentText,
                  postedDate: DateTime.now(),
                  propertyListingId: propertyListingId,
                );
                _comments.insert(0, newComment);
              });
            },
          ),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final LookingForPostModel post;
  final VoidCallback onMoreTap;

  const _PostHeader({
    required this.post,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                Text(
                  post.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (post.isVerified) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _themeColorLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified,
                      size: 16,
                      color: _themeColorDark,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  post.timeAgo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Three dots menu
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
                  color: Colors.grey[600],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
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

  const _PostActionBar({
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            iconPath: isLiked 
                ? 'assets/icons/navbar/heart_filled.svg'
                : 'assets/icons/navbar/heart_outlined.svg',
            count: likeCount,
            isActive: isLiked,
            onTap: onLikeTap,
          ),
          const SizedBox(width: 32),
          
          // Comment Button
          _ActionButton(
            iconPath: 'assets/icons/navbar/comment_outlined.svg',
            count: commentCount,
            onTap: () {},
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
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
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
              SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isActive
                      ? const Color(0xFFE91E63)
                      : Colors.grey[600]!,
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

// Comments List Widget
class _CommentsList extends StatelessWidget {
  final List<CommentModel> comments;
  final Function(String)? onPropertyTap;

  const _CommentsList({
    required this.comments,
    this.onPropertyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Text(
          'No comments yet',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text(
            'Comments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == comments.length - 1 ? 0 : 16,
              ),
              child: _CommentItem(
                comment: comments[index],
                onPropertyTap: onPropertyTap,
              ),
            );
          },
        ),
      ],
    );
  }
}

// Comment Item Widget
class _CommentItem extends StatelessWidget {
  final CommentModel comment;
  final Function(String)? onPropertyTap;

  const _CommentItem({
    required this.comment,
    this.onPropertyTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPropertyLink = comment.propertyListingId != null;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Picture
        Container(
          width: 40,
          height: 40,
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
              comment.username[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Comment Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (comment.isVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _themeColorLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified,
                        size: 14,
                        color: _themeColorDark,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    comment.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              // Property Link Button
              if (hasPropertyLink) ...[
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (onPropertyTap != null) {
                        onPropertyTap!(comment.propertyListingId!);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B8E6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00B8E6).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: _themeColorDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Property Listing',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _themeColorDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: _themeColorDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Fixed Comment Input Widget (Facebook-style)
class _FixedCommentInput extends StatefulWidget {
  final Function(String, String?) onCommentAdded;

  const _FixedCommentInput({
    required this.onCommentAdded,
  });

  @override
  State<_FixedCommentInput> createState() => _FixedCommentInputState();
}

class _FixedCommentInputState extends State<_FixedCommentInput> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Detects property links in comment text and extracts property ID
  String? _detectAndExtractPropertyId(String text) {
    // Patterns to detect: property/123, listing/456, /property/123, etc.
    final patterns = [
      RegExp(r'property/(\d+)', caseSensitive: false),
      RegExp(r'listing/(\d+)', caseSensitive: false),
      RegExp(r'/property/(\d+)', caseSensitive: false),
      RegExp(r'/listing/(\d+)', caseSensitive: false),
      RegExp(r'property-(\d+)', caseSensitive: false),
      RegExp(r'listing-(\d+)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final propertyId = match.group(1);
        if (propertyId != null) {
          // Validate against mock listings
          final allListings = ListingModel.getMockListings();
          final isValid = allListings.any((listing) => listing.id == propertyId);
          if (isValid) {
            return propertyId;
          }
        }
      }
    }

    return null;
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    final commentText = _commentController.text.trim();
    
    // Detect and extract property ID from the comment text
    final propertyListingId = _detectAndExtractPropertyId(commentText);

    widget.onCommentAdded(commentText, propertyListingId);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Share your property listing...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _themeColorDark, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addComment,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _themeColorDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 20,
                    color: Colors.white,
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

