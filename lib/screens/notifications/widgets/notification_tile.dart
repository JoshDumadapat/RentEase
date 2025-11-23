import 'package:flutter/material.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/utils/time_ago.dart';

/// Notification Tile Widget
/// 
/// Displays a single notification item with:
/// - Profile avatar
/// - Notification text (like/comment)
/// - Time ago
/// - Read/unread indicator
/// - Remove button
/// - Swipe actions (optional)
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onToggleRead;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onRemove,
    this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                notification.actorName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (!notification.read)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          _buildNotificationText(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: notification.read ? FontWeight.normal : FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            TimeAgo.format(notification.timestamp),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onRemove,
          tooltip: 'Remove',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  String _buildNotificationText() {
    if (notification.type == NotificationType.like) {
      return '${notification.actorName} liked "${notification.postTitle}"';
    } else {
      return '${notification.actorName} commented "${notification.commentText}" on "${notification.postTitle}"';
    }
  }

}

