import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:rentease_app/models/user_model.dart';

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

class UserInfoSection extends StatelessWidget {

  final UserModel user;

  final VoidCallback onEditProfile;
  final VoidCallback? onShareProfile;

  const UserInfoSection({

    super.key,

    required this.user,

    required this.onEditProfile,
    this.onShareProfile,

  });

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

                child: user.profileImageUrl != null

                    ? ClipOval(

                        child: Image.network(

                          user.profileImageUrl!,

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

                                user.displayName,

                                style: TextStyle(

                                  fontSize: 18,

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

                    if (user.username != null && user.username!.isNotEmpty) ...[

                      const SizedBox(height: 8),

                      Text(

                        '@${user.username}',

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

                    if (user.isVerified) ...[

                      SizedBox(height: user.username != null && user.username!.isNotEmpty ? 6 : 8),

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

          

          // Bio

          if (user.bio != null && user.bio!.isNotEmpty) ...[

            const SizedBox(height: 20),

            Text(

              user.bio!,

              style: TextStyle(

                fontSize: 15,

                color: isDark ? Colors.grey[300] : const Color(0xFF2D2D2D),

                height: 1.5,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,

              ),

            ),

          ],

          // Edit Profile and Share Profile Buttons

          const SizedBox(height: 16),

          Row(

            children: [

              Expanded(

                child: TextButton(

                  onPressed: onEditProfile,

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

                  onPressed: onShareProfile ?? () {},

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

            label: user.email,

            isDark: isDark,

          ),

          

          // Phone (if available)

          if (user.phone != null) ...[

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

              label: user.phone!,

              isDark: isDark,

            ),

          ],

          

          // Joined Date (if available)

          if (user.joinedDate != null) ...[

            const SizedBox(height: 12),

            _ContactInfoRow(

              icon: Icons.calendar_today_outlined,

              label: 'Joined ${_formatDate(user.joinedDate!)}',

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
