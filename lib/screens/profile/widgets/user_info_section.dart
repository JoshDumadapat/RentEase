import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/models/user_model.dart';
import 'package:rentease_app/backend/BFollowService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/screens/chat/user_chat_page.dart';

// Theme colors matching the listing cards
const Color _themeColorLight = Color(0xFFE5F9FF); // Light background (like blue[50])
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

/// User Info Section Widget

/// 

/// Displays user profile information:

/// - Profile picture/avatar

/// - Display name

/// - Username (optional)

/// - Bio/description (optional)

/// - Contact info (email, phone)

/// - Edit profile button

class UserInfoSection extends StatefulWidget {
  final UserModel user;
  final VoidCallback onEditProfile;
  final VoidCallback? onShareProfile;
  final bool isVisitorView; // If true, this is viewing another user's profile

  const UserInfoSection({
    super.key,
    required this.user,
    required this.onEditProfile,
    this.onShareProfile,
    this.isVisitorView = false,
  });

  @override
  State<UserInfoSection> createState() => _UserInfoSectionState();
}

class _UserInfoSectionState extends State<UserInfoSection> {
  final BFollowService _followService = BFollowService();
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVisitorView) {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _followService.isFollowing(widget.user.id);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow) return;
    
    setState(() {
      _isLoadingFollow = true;
    });

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(widget.user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Unfollowed ${widget.user.displayName}',
            ),
          );
        }
      } else {
        await _followService.followUser(widget.user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(
              context,
              'Following ${widget.user.displayName}',
            ),
          );
        }
      }
      
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoadingFollow = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error: ${e.toString()}',
          ),
        );
      }
    }
  }

  void _handleChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserChatPage(
          otherUser: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 24.0),

      child: Container(

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

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Profile Picture and Edit Button Row

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // Profile Picture

              Container(

                width: 100,

                height: 100,

                decoration: BoxDecoration(

                  shape: BoxShape.circle,

                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],

                  border: Border.all(

                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey[300]!,

                    width: 3,

                  ),

                ),

                child: widget.user.profileImageUrl != null

                    ? ClipOval(

                        child: Image.network(

                          widget.user.profileImageUrl!,

                          fit: BoxFit.cover,

                          errorBuilder: (context, error, stackTrace) =>

                              _buildDefaultAvatar(context),

                        ),

                      )

                    : _buildDefaultAvatar(context),

              ),

              

              const SizedBox(width: 20),

              

              // Name, Username, and Edit Button

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                widget.user.displayName,

                                style: TextStyle(

                                  fontSize: _getFontSize(widget.user.displayName),

                                  fontWeight: FontWeight.bold,

                                  color: isDark

                                      ? Colors.white

                                      : Colors.black87,

                                ),

                                maxLines: 2,

                                overflow: TextOverflow.visible,

                              ),

                            ],

                          ),

                        ),

                      ],

                    ),

                    // Username below name

                    if (widget.user.username != null && widget.user.username!.isNotEmpty) ...[

                      const SizedBox(height: 8),

                      Text(

                        '@${widget.user.username}',

                        style: TextStyle(

                          fontSize: 14,

                          color: isDark

                              ? Colors.grey[400]

                              : Colors.grey[600],

                          fontWeight: FontWeight.w500,

                        ),

                      ),

                    ],

                    // Verified text with icon (below username or below name if no username)

                    if (widget.user.isVerified) ...[

                      SizedBox(height: widget.user.username != null && widget.user.username!.isNotEmpty ? 6 : 8),

                      Row(

                        children: [

                          Container(

                            padding: const EdgeInsets.all(4),

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

                          const SizedBox(width: 4),

                          Text(

                            'Verified',

                            style: TextStyle(

                              fontSize: 13,

                              color: isDark ? Colors.grey[500] : Colors.grey[600],

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                        ],

                      ),

                    ],

                  ],

                ),

              ),

            ],

          ),

          

          // Bio with Follow button for visitors
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.user.bio!,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[300] : const Color(0xFF2D2D2D),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Follow button beside bio for visitors
                if (widget.isVisitorView) ...[
                  const SizedBox(width: 12),
                  _buildFollowButton(isDark),
                ],
              ],
            ),
          ] else if (widget.isVisitorView) ...[
            // If no bio, show follow button in its own row
            const SizedBox(height: 20),
            _buildFollowButton(isDark),
          ],

          // Action Buttons
          const SizedBox(height: 16),
          
          if (widget.isVisitorView) ...[
            // Visitor view: Show Chat and Follow buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleChat,
                    icon: const Icon(Icons.message_outlined, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoadingFollow ? null : _toggleFollow,
                    icon: _isLoadingFollow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isFollowing ? Icons.person_remove : Icons.person_add,
                            size: 18,
                          ),
                    label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: _isFollowing
                          ? (isDark ? Colors.grey[700] : Colors.grey[300])
                          : _themeColorDark,
                      foregroundColor: _isFollowing
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Own profile: Show Edit Profile and Share Profile buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onEditProfile,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 21),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: isDark ? Colors.grey[700] : _themeColorDark,
                    ),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: widget.onShareProfile ?? () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 21),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: isDark ? Colors.grey[700] : _themeColorDark,
                    ),
                    child: Text(
                      'Share Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          

          // Contact Info

          const SizedBox(height: 20),

          Divider(

            height: 1,

            thickness: 1,

            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,

          ),

          const SizedBox(height: 16),

          

          // Email

          _ContactInfoRow(

            iconWidget: SvgPicture.asset(
              'assets/icons/email.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                isDark ? Colors.grey[500]! : Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),

            label: widget.user.email,

            isDark: isDark,

          ),

          

          // Phone (if available)

          if (widget.user.phone != null) ...[

            const SizedBox(height: 12),

            _ContactInfoRow(

              iconWidget: SvgPicture.asset(
                'assets/icons/phone.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                  BlendMode.srcIn,
                ),
              ),

              label: widget.user.phone!,

              isDark: isDark,

            ),

          ],

          

          // Joined Date (if available)

          if (widget.user.joinedDate != null) ...[

            const SizedBox(height: 12),

            _ContactInfoRow(

              icon: Icons.calendar_today_outlined,

              label: 'Joined ${_formatDate(widget.user.joinedDate!)}',

              isDark: isDark,

            ),

          ],

        ],

      ),

      ),

    );

  }

  Widget _buildDefaultAvatar(BuildContext context) {

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    

    return Icon(

      Icons.person,

      size: 50,

      color: isDark ? Colors.grey[600] : Colors.grey[400],

    );

  }

  String _formatDate(DateTime date) {

    final months = [

      'Jan',

      'Feb',

      'Mar',

      'Apr',

      'May',

      'Jun',

      'Jul',

      'Aug',

      'Sep',

      'Oct',

      'Nov',

      'Dec'

    ];

    return '${months[date.month - 1]} ${date.year}';

  }

  /// Calculate responsive font size based on name length

  double _getFontSize(String name) {

    final length = name.length;

    if (length <= 10) {

      return 24;

    } else if (length <= 15) {

      return 22;

    } else if (length <= 20) {

      return 20;

    } else if (length <= 25) {

      return 18;

    } else {

      return 16;

    }

  }

  Widget _buildFollowButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _isFollowing
            ? (isDark ? Colors.grey[700] : Colors.grey[200])
            : _themeColorDark,
        borderRadius: BorderRadius.circular(20),
        border: _isFollowing
            ? Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoadingFollow ? null : _toggleFollow,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _isLoadingFollow
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFollowing ? Icons.person_remove : Icons.person_add,
                        size: 18,
                        color: _isFollowing
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isFollowing ? 'Unfollow' : 'Follow',
                        style: TextStyle(
                          color: _isFollowing
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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

class _ContactInfoRow extends StatelessWidget {

  final IconData? icon;
  final Widget? iconWidget;

  final String label;

  final bool isDark;

  const _ContactInfoRow({

    this.icon,
    this.iconWidget,
    required this.label,

    required this.isDark,

  });

  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        iconWidget ?? Icon(

          icon!,

          size: 18,

          color: isDark ? Colors.grey[500] : Colors.grey[600],

        ),

        const SizedBox(width: 12),

        Expanded(

          child: Text(

            label,

            style: TextStyle(

              fontSize: 14,

              color: isDark ? Colors.grey[300] : Colors.grey[700],

              fontWeight: FontWeight.w400,

            ),

          ),

        ),

      ],

    );

  }

}
