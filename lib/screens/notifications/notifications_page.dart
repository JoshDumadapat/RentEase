import 'package:flutter/material.dart';
import 'package:rentease_app/services/notification_service.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/notifications/widgets/empty_state_widget.dart';
import 'package:rentease_app/screens/notifications/widgets/notification_skeleton.dart';
import 'package:rentease_app/screens/notifications/widgets/notification_tile.dart';

/// Notifications Page
/// 
/// Displays notifications in a social media style design matching the reference.
/// Features:
/// - Tabs: All and Unread
/// - Time-based sections: New, Friend requests, Today, Earlier
/// - Minimal and aesthetic design
/// - Light and dark mode support
/// - Skeleton loader
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late final NotificationService _controller;
  late final TabController _tabController;
  int _selectedTabIndex = 0; // 0 = All, 1 = Unread

  @override
  void initState() {
    super.initState();
    _controller = NotificationService();
    _controller.initialize();
    _controller.addListener(_onControllerUpdate);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    }
  }

  /// Navigate to the relevant listing based on notification type
  void _navigateToNotificationTarget(NotificationModel notification) {
    // Mark as read when tapped
    _controller.markAsRead(notification.id);

    // Skip navigation for friend requests
    if (notification.type == NotificationType.friendRequest) {
      return;
    }

    // Navigate to listing details if postId is available
    if (notification.postId != null) {
      final listings = ListingModel.getMockListings();
      final listing = listings.firstWhere(
        (l) => l.id == notification.postId,
        orElse: () => listings.first, // Fallback to first listing if not found
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListingDetailsPage(listing: listing),
        ),
      );
    }
  }

  List<NotificationModel> get _filteredNotifications {
    final all = _controller.notifications;
    if (_selectedTabIndex == 1) {
      return all.where((n) => !n.read).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Note: Menu functionality will be implemented when needed
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? Colors.grey[900] : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? Colors.blue[300] : Colors.blue[600],
              labelColor: isDark ? Colors.blue[300] : Colors.blue[600],
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_controller.isLoading && _controller.notifications.isEmpty) {
      return const NotificationSkeleton();
    }

    if (_controller.error != null && _controller.notifications.isEmpty) {
      return _buildErrorState();
    }

    final notifications = _filteredNotifications;
    if (notifications.isEmpty) {
      return const EmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: _controller.refreshNotifications,
      child: ListView(
        children: [
          _buildSection(
            title: 'New',
            notifications: _getNewNotifications(notifications),
            showSeeAll: true,
            isDark: isDark,
          ),
          _buildSection(
            title: 'Friend requests',
            notifications: _getFriendRequests(notifications),
            showSeeAll: true,
            isDark: isDark,
          ),
          _buildSection(
            title: 'Today',
            notifications: _getTodayNotifications(notifications),
            showSeeAll: false,
            isDark: isDark,
          ),
          _buildSection(
            title: 'Earlier',
            notifications: _getEarlierNotifications(notifications),
            showSeeAll: false,
            isDark: isDark,
          ),
          // See previous notifications button
          if (_getEarlierNotifications(notifications).isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'See previous notifications',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<NotificationModel> notifications,
    required bool showSeeAll,
    required bool isDark,
  }) {
    if (notifications.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (showSeeAll)
                TextButton(
                  onPressed: () {
                    // Note: Navigation to see all notifications will be implemented when needed
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.blue[300] : Colors.blue[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...notifications.asMap().entries.map((entry) {
          final index = entry.key;
          final notification = entry.value;
          final isLast = index == notifications.length - 1;
          
          return Column(
            children: [
              NotificationTile(
                notification: notification,
                onTap: () => _navigateToNotificationTarget(notification),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 72, // Align with content (avatar width + spacing)
                  color: isDark 
                      ? Colors.grey[800]!.withValues(alpha: 0.5) 
                      : Colors.grey[300]!.withValues(alpha: 0.5),
                ),
            ],
          );
        }),
      ],
    );
  }

  List<NotificationModel> _getNewNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    return notifications.where((n) {
      final diff = now.difference(n.timestamp);
      return diff.inMinutes < 60 && !n.read;
    }).toList();
  }

  List<NotificationModel> _getFriendRequests(List<NotificationModel> notifications) {
    return notifications.where((n) => n.type == NotificationType.friendRequest).toList();
  }

  List<NotificationModel> _getTodayNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    return notifications.where((n) {
      final diff = now.difference(n.timestamp);
      return diff.inHours < 24 && 
             diff.inMinutes >= 60 && 
             n.type != NotificationType.friendRequest &&
             !_getNewNotifications(notifications).contains(n);
    }).toList();
  }

  List<NotificationModel> _getEarlierNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    return notifications.where((n) {
      final diff = now.difference(n.timestamp);
      return diff.inDays >= 1 && 
             n.type != NotificationType.friendRequest &&
             !_getNewNotifications(notifications).contains(n) &&
             !_getTodayNotifications(notifications).contains(n);
    }).toList();
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
