import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/admin/utils/admin_auth_utils.dart';
import 'package:rentease_app/backend/BAdminService.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:rentease_app/dialogs/confirmation_dialog.dart';

// Theme color constants
const Color _themeColorDark = Color(0xFF00B8E6);

/// Admin Notifications Management Page
/// 
/// Allows admin to view all notifications and remove them
class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final BAdminService _adminService = BAdminService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadNotifications();
  }

  Future<void> _checkAdminAccess() async {
    final userModel = await AdminAuthUtils.verifyAdminAccess();
    if (userModel == null) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Access denied. Admin privileges required.',
          ),
        );
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _adminService.getAllNotifications();
      if (mounted) {
        // Remove duplicates based on notification ID
        final seenIds = <String>{};
        final uniqueNotifications = <Map<String, dynamic>>[];
        for (final notification in notifications) {
          final notificationId = notification['id'] as String?;
          if (notificationId != null && notificationId.isNotEmpty && !seenIds.contains(notificationId)) {
            seenIds.add(notificationId);
            uniqueNotifications.add(notification);
          }
        }
        
        setState(() {
          _notifications = uniqueNotifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading notifications: $e',
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Notification',
      message: 'Are you sure you want to delete this notification?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red[600],
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Notification deleted successfully',
          ),
        );
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error deleting notification: $e',
          ),
        );
      }
    }
  }

  String _getNotificationText(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final actorName = notification['actorName'] as String? ?? 'Someone';
    final postTitle = notification['postTitle'] as String?;
    final reactionEmoji = notification['reactionEmoji'] as String?;

    switch (type) {
      case 'reaction':
        return postTitle != null
            ? '$actorName reacted $reactionEmoji to "$postTitle"'
            : '$actorName reacted $reactionEmoji';
      case 'comment':
        return postTitle != null
            ? '$actorName commented on "$postTitle"'
            : '$actorName commented';
      case 'friendRequest':
        return '$actorName sent a friend request';
      case 'mention':
        return '$actorName mentioned you';
      default:
        return '$actorName $type';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'reaction':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'friendRequest':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notifications'),
        backgroundColor: _themeColorDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications found',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    key: const PageStorageKey<String>('admin_notifications_list'),
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final notificationId = notification['id'] as String? ?? '';
                      // Ensure we have a valid ID
                      if (notificationId.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final isRead = notification['read'] as bool? ?? false;

                      return Card(
                        key: ValueKey('notification_$notificationId'),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: cardColor,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _themeColorDark.withValues(alpha: 0.1),
                            child: Icon(
                              _getNotificationIcon(notification['type'] as String?),
                              color: _themeColorDark,
                            ),
                          ),
                          title: Text(
                            _getNotificationText(notification),
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notification['commentText'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '"${notification['commentText']}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(notification['createdAt']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () => _deleteNotification(notificationId),
                            tooltip: 'Delete notification',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

