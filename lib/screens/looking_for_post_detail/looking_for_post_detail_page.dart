import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/models/comment_model.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/add_looking_for_post/add_looking_for_post_screen.dart';
import 'package:rentease_app/backend/BCommentService.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

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
  bool _isLoadingComments = true;
  bool _isSubmittingComment = false;
  
  // Backend services
  final BCommentService _commentService = BCommentService();
  final BLookingForPostService _lookingForPostService = BLookingForPostService();
  final BUserService _userService = BUserService();
  final BListingService _listingService = BListingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _loadComments();
  }

  void _showShareModal() {
    final postLink = 'https://rentease.app/looking-for/${widget.post.id}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
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
                      await Share.share(postLink, subject: widget.post.description);
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

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    
    try {
      debugPrint('📖 [LookingForPostDetail] Loading comments for post: ${widget.post.id}');
      final commentsData = await _commentService.getCommentsByLookingForPost(widget.post.id);
      debugPrint('📊 [LookingForPostDetail] Received ${commentsData.length} comments from service');
      
      final comments = commentsData
          .map((data) {
            try {
              return CommentModel.fromMap(data);
            } catch (e) {
              debugPrint('❌ [LookingForPostDetail] Error parsing comment: $e, data: $data');
              return null;
            }
          })
          .whereType<CommentModel>()
          .toList();
      
      debugPrint('✅ [LookingForPostDetail] Parsed ${comments.length} comments successfully');
      
      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(comments);
          _commentCount = comments.length;
          _isLoadingComments = false;
        });
        debugPrint('🔄 [LookingForPostDetail] UI updated with ${_comments.length} comments');
      }
    } catch (e) {
      debugPrint('❌ [LookingForPostDetail] Error loading comments: $e');
      debugPrint('❌ [LookingForPostDetail] Error stack: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading comments: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _showPostOptions() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final user = _auth.currentUser;
    final isOwner = user != null && user.uid == widget.post.id.split('_').first || 
                    (user != null && await _checkIfOwner(user.uid));
    
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
              if (isOwner) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: iconColor),
                  title: Text(
                    'Edit post',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _editPost();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deletePost();
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: Icon(Icons.visibility_off, color: iconColor),
                title: Text(
                  'Hide post',
                  style: TextStyle(color: textColor),
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

  Future<bool> _checkIfOwner(String userId) async {
    try {
      // First check if we already have the userId in the post model
      // If not, fetch from Firestore
      // Note: LookingForPostModel doesn't store userId, so we need to fetch it
      final postData = await _lookingForPostService.getLookingForPost(widget.post.id);
      return postData?['userId'] == userId;
    } catch (e) {
      debugPrint('❌ [LookingForPostDetail] Error checking owner: $e');
      return false;
    }
  }

  Future<void> _editPost() async {
    final result = await Navigator.push<LookingForPostModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddLookingForPostScreen(post: widget.post),
      ),
    );

    if (result != null && mounted) {
      // Return the updated post to parent
      Navigator.pop(context, result);
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _lookingForPostService.deleteLookingForPost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Post deleted successfully',
            ),
          );
          Navigator.pop(context, true); // Return true to indicate deletion
        }
      } catch (e) {
        debugPrint('❌ [LookingForPostDetail] Error deleting post: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Error deleting post: ${e.toString()}',
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[100];
    final appBarColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
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
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
                          isDark: isDark,
                        ),

                        // Post Body
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

                        // Action Bar
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
                          onShareTap: _showShareModal,
                        ),
                      ],
                    ),
                  ),
                  // Comments in separate card
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    padding: const EdgeInsets.only(bottom: 0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
                    child: _isLoadingComments
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _CommentsList(
                            comments: _comments,
                            isDark: isDark,
                            onPropertyTap: (listingId) async {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                // Fetch listing from Firestore
                                final listingData = await _listingService.getListing(listingId);
                                
                                if (!mounted) return;
                                Navigator.pop(context); // Close loading dialog

                                if (listingData != null) {
                                  final listing = ListingModel.fromMap({
                                    'id': listingId,
                                    ...listingData,
                                  });

                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ListingDetailsPage(listing: listing),
                                      ),
                                    );
                                  }
                                } else {
                                  // Fallback to mock listings if not found in Firestore
                                  final allListings = ListingModel.getMockListings();
                                  final listing = allListings.firstWhere(
                                    (l) => l.id == listingId,
                                    orElse: () => allListings.first,
                                  );

                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ListingDetailsPage(listing: listing),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (!mounted) return;
                                Navigator.pop(context); // Close loading dialog
                                
                                // Show error and fallback to mock listings
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBarUtils.buildThemedSnackBar(
                                    context,
                                    'Error loading listing. Using cached data.',
                                  ),
                                );

                                final allListings = ListingModel.getMockListings();
                                final listing = allListings.firstWhere(
                                  (l) => l.id == listingId,
                                  orElse: () => allListings.first,
                                );

                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ListingDetailsPage(listing: listing),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Fixed Comment Input at Bottom (Facebook-style)
          _FixedCommentInput(
            isDark: isDark,
            isSubmitting: _isSubmittingComment,
            onCommentAdded: _addComment,
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(String commentText, String? propertyListingId) async {
    if (commentText.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please sign in to comment'),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      // Get user data for username
      final userData = await _userService.getUserData(user.uid);
      final username = userData?['username'] as String? ?? 
                      userData?['displayName'] as String? ??
                      (userData?['fname'] != null && userData?['lname'] != null
                          ? '${userData!['fname']} ${userData['lname']}'.trim()
                          : null) ??
                      user.displayName ?? 
                      user.email?.split('@')[0] ?? 
                      'User';

      // Optimistically add comment to UI immediately
      final tempComment = CommentModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        username: username,
        text: commentText,
        postedDate: DateTime.now(),
        isVerified: false,
        propertyListingId: propertyListingId,
      );
      
      setState(() {
        _comments.insert(0, tempComment);
        _commentCount = _comments.length;
      });

      // Create comment in Firestore
      debugPrint('📝 [LookingForPostDetail] Creating comment...');
      if (propertyListingId != null) {
        debugPrint('🔗 [LookingForPostDetail] Detected property link: $propertyListingId');
      }
      final commentId = await _commentService.createComment(
        userId: user.uid,
        username: username,
        text: commentText,
        lookingForPostId: widget.post.id,
        propertyListingId: propertyListingId,
      );
      debugPrint('✅ [LookingForPostDetail] Comment created with ID: $commentId');

      // Increment comment count
      await _lookingForPostService.incrementCommentCount(widget.post.id);
      debugPrint('✅ [LookingForPostDetail] Comment count incremented');

      // Add a small delay to ensure Firestore has processed the write
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload comments to get the new one with proper data from Firestore
      debugPrint('🔄 [LookingForPostDetail] Reloading comments...');
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Comment added successfully!',
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [LookingForPostDetail] Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error adding comment: ${e.toString()}',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }
}

class _PostHeader extends StatelessWidget {
  final LookingForPostModel post;
  final VoidCallback onMoreTap;
  final bool isDark;

  const _PostHeader({
    required this.post,
    required this.onMoreTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
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
                      color: _themeColorDark.withOpacity(0.2), // Glowing blue background
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
  final VoidCallback? onShareTap;

  const _PostActionBar({
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isDark,
    required this.onLikeTap,
    this.onShareTap,
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          
          // Comment Button
          _ActionButton(
            iconPath: 'assets/icons/navbar/comment_outlined.svg',
            count: commentCount,
            isDark: isDark,
            onTap: () {},
          ),
          
          // Share Button
          if (onShareTap != null)
            _ActionButton(
              iconPath: 'assets/icons/navbar/share_outlined.svg',
              count: 0,
              isDark: isDark,
              onTap: onShareTap!,
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
              if (count > 0) ...[
                const SizedBox(width: 8),
                Text(
                  _formatCount(count),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFFE91E63)
                        : inactiveTextColor,
                  ),
                ),
              ],
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
  final bool isDark;
  final Function(String)? onPropertyTap;

  const _CommentsList({
    required this.comments,
    required this.isDark,
    this.onPropertyTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final dividerColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Text(
          'No comments yet',
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: dividerColor),
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
                isDark: isDark,
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
  final bool isDark;
  final Function(String)? onPropertyTap;

  const _CommentItem({
    required this.comment,
    required this.isDark,
    this.onPropertyTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPropertyLink = comment.propertyListingId != null;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[600];
    
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (comment.isVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _themeColorDark.withOpacity(0.2), // Glowing blue background
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified,
                        size: 14,
                        color: _themeColorDark, // Blue icon
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    comment.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.text,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
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
  final bool isDark;
  final bool isSubmitting;
  final Function(String, String?) onCommentAdded;

  const _FixedCommentInput({
    required this.isDark,
    required this.isSubmitting,
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
    // Patterns to detect:
    // - URLs: https://rentease.app/listing/123, http://rentease.app/listing/123
    // - Short patterns: property/123, listing/456, /property/123, etc.
    final patterns = [
      // Full URL patterns
      RegExp(r'https?://[^\s/]+/listing/([a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'https?://[^\s/]+/property/([a-zA-Z0-9_-]+)', caseSensitive: false),
      // Short URL patterns (without domain)
      RegExp(r'rentease\.app/listing/([a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'rentease\.app/property/([a-zA-Z0-9_-]+)', caseSensitive: false),
      // Path patterns
      RegExp(r'/listing/([a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'/property/([a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'listing/([a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'property/([a-zA-Z0-9_-]+)', caseSensitive: false),
      // Hyphen patterns
      RegExp(r'listing-([a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'property-([a-zA-Z0-9_-]+)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final propertyId = match.group(1);
        if (propertyId != null && propertyId.isNotEmpty) {
          // Return the extracted ID - validation will happen when user clicks the button
          debugPrint('🔗 [CommentInput] Detected property link: $propertyId');
          return propertyId;
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
    final backgroundColor = widget.isDark ? Colors.grey[900] : Colors.white;
    final borderColor = widget.isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final inputBorderColor = widget.isDark ? Colors.grey[600]! : Colors.grey[300]!;
    final fillColor = widget.isDark ? Colors.grey[800]! : Colors.grey[50]!;
    final hintColor = widget.isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
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
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Share your property listing...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: hintColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: inputBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: inputBorderColor),
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
                  fillColor: fillColor,
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
                onTap: widget.isSubmitting ? null : _addComment,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isSubmitting 
                        ? _themeColorDark.withValues(alpha: 0.5)
                        : _themeColorDark,
                    shape: BoxShape.circle,
                  ),
                  child: widget.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
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

