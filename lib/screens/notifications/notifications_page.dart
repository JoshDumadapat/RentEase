import 'package:flutter/material.dart';
import 'package:rentease_app/controllers/notification_controller.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/notifications/widgets/empty_state_widget.dart';
import 'package:rentease_app/screens/notifications/widgets/notification_skeleton.dart';
import 'package:rentease_app/screens/notifications/widgets/notification_tile.dart';

/// Notifications Page
/// 
/// Displays all likes and comments on user's posts/properties.
/// Features:
/// - Pull-to-refresh
/// - Remove button on each notification
/// - Swipe to delete or mark as read/unread
/// - Tap to navigate to relevant post/property
/// - Read/unread indicators
/// - Empty state
/// - Skeleton loader
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController();
    _controller.initialize();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Navigate to the relevant post/property
  void _navigateToPost(NotificationModel notification) {
    // Mark as read when tapped
    _controller.markAsRead(notification.id);

    // Find the listing by postId
    final listings = ListingModel.getMockListings();
    final listing = listings.firstWhere(
      (l) => l.id == notification.postId,
      orElse: () => listings.first, // Fallback to first listing if not found
    );

    // Navigate to listing details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsPage(listing: listing),
      ),
    );
  }

  /// Handle notification removal
  void _handleRemove(NotificationModel notification) {
    _controller.deleteNotification(notification.id);
  }

  /// Show clear all confirmation dialog
  Future<void> _showClearAllDialog() async {
    if (_controller.notifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _controller.clearAllNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_controller.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _showClearAllDialog,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const NotificationSkeleton();
    }

    if (_controller.error != null && _controller.notifications.isEmpty) {
      return _buildErrorState();
    }

    if (_controller.notifications.isEmpty) {
      return const EmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: _controller.refreshNotifications,
      child: ListView.separated(
        itemCount: _controller.notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = _controller.notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _navigateToPost(notification),
            onRemove: () => _handleRemove(notification),
            onToggleRead: () => _controller.toggleReadStatus(notification.id),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _controller.error ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _controller.fetchNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

