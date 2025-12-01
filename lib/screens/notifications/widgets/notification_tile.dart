import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/utils/time_ago.dart';

/// Notification Tile Widget
/// 
/// Displays a single notification item matching the reference design:
/// - Profile avatar with overlay icon (emoji, person icon, speech bubble)
/// - Notification text
/// - Time ago
/// - Minimal and aesthetic design
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Skip if friend request was removed
    if (notification.type == NotificationType.friendRequest && 
        notification.requestRemoved == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          'Request removed',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture with overlay icon
            _buildAvatarWithOverlay(context, isDark),
            const SizedBox(width: 12),
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationText(context, isDark),
                  const SizedBox(height: 4),
                  Text(
                    TimeAgo.format(notification.timestamp, includeAgo: false),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  // Show reaction count if available
                  if (notification.reactionCount != null && 
                      notification.reactionCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${notification.reactionCount} Reactions',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithOverlay(BuildContext context, bool isDark) {
    // Build avatar
    Widget avatar = CircleAvatar(
      radius: 24,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
      child: notification.actorAvatarUrl != null
          ? ClipOval(
              child: Image.network(
                notification.actorAvatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(context, isDark),
              ),
            )
          : _buildInitialsAvatar(context, isDark),
    );

    // Build overlay icon
    Widget? overlayIcon = _buildOverlayIcon(context, isDark);

    if (overlayIcon != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(child: overlayIcon),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildInitialsAvatar(BuildContext context, bool isDark) {
    final initials = notification.actorName.isNotEmpty
        ? notification.actorName[0].toUpperCase()
        : '?';
    
    return Text(
      initials,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }

  Widget? _buildOverlayIcon(BuildContext context, bool isDark) {
    switch (notification.type) {
      case NotificationType.reaction:
        if (notification.reactionEmoji != null) {
          return Text(
            notification.reactionEmoji!,
            style: const TextStyle(fontSize: 14),
          );
        }
        return SvgPicture.asset(
          'assets/icons/navbar/heart_filled.svg',
          width: 14,
          height: 14,
          colorFilter: const ColorFilter.mode(
            Colors.red,
            BlendMode.srcIn,
          ),
        );
      case NotificationType.friendRequest:
        return Icon(
          Icons.person_add,
          size: 14,
          color: isDark ? Colors.blue[300] : Colors.blue[600],
        );
      case NotificationType.comment:
      case NotificationType.mention:
        return SvgPicture.asset(
          'assets/icons/navbar/comment_filled.svg',
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(
            isDark ? Colors.green[300]! : Colors.green[600]!,
            BlendMode.srcIn,
          ),
        );
    }
  }

  Widget _buildNotificationText(BuildContext context, bool isDark) {
    String text = '';
    
    switch (notification.type) {
      case NotificationType.reaction:
        if (notification.otherActors != null && notification.otherActors!.isNotEmpty) {
          // Calculate total count including main actor
          final totalCount = 1 + notification.otherActors!.length;
          final reactionCount = notification.reactionCount ?? totalCount;
          
          if (reactionCount <= 3) {
            // Show all names if 3 or fewer
            final allNames = [notification.actorName, ...notification.otherActors!];
            text = allNames.join(', ');
            text += ' liked your post';
          } else {
            // Show first name, then others, then count
            final otherNames = notification.otherActors!.take(1).join(', ');
            final remainingCount = reactionCount - 2; // Subtract main actor and one other
            text = '${notification.actorName}, $otherNames and $remainingCount other people';
            text += ' liked your post';
          }
          
          if (notification.postTitle != null) {
            text += ': "${notification.postTitle}"';
          }
        } else {
          text = '${notification.actorName} liked your post';
          if (notification.postTitle != null) {
            text += ': "${notification.postTitle}"';
          }
        }
        break;
      case NotificationType.friendRequest:
        text = '${notification.actorName} sent you a friend request.';
        break;
      case NotificationType.comment:
        text = '${notification.actorName} commented on your post';
        if (notification.postTitle != null) {
          text += ': "${notification.postTitle}"';
        }
        text += '.';
        break;
      case NotificationType.mention:
        text = '${notification.actorName} mentioned you in a comment';
        if (notification.commentText != null) {
          text += ' in ${notification.commentText}';
        }
        text += '.';
        break;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
