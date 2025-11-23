import 'package:flutter/material.dart';
import 'package:rentease_app/models/user_model.dart';

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

  const UserInfoSection({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.displayName,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.isVerified) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.verified,
                                        size: 20,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (user.username != null) ...[
                                const SizedBox(height: 4),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ),
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
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
          
          // Contact Info
          const SizedBox(height: 20),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          const SizedBox(height: 16),
          
          // Email
          _ContactInfoRow(
            icon: Icons.email_outlined,
            label: user.email,
            isDark: isDark,
          ),
          
          // Phone (if available)
          if (user.phone != null) ...[
            const SizedBox(height: 12),
            _ContactInfoRow(
              icon: Icons.phone_outlined,
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
}

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
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

