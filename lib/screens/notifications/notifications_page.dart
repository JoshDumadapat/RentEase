import 'package:flutter/material.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';
import 'package:rentease_app/services/notification_service.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/models/notification_model.dart';
import 'package:rentease_app/models/looking_for_post_model.dart';
import 'package:rentease_app/screens/listing_details/listing_details_page.dart';
import 'package:rentease_app/screens/looking_for_post_detail/looking_for_post_detail_page.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BLookingForPostService.dart';
import 'package:rentease_app/screens/notifications/widgets/empty_state_widget.dart';
import 'package:rentease_app/screens/notifications/widgets/notification_skeleton.dart';
import 'package:rentease_app/screens/notifications/widgets/notification_tile.dart';
import 'package:rentease_app/screens/chat/chats_list_page.dart';

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

  /// Navigate to the relevant listing or looking-for post based on notification type
  Future<void> _navigateToNotificationTarget(NotificationModel notification) async {
    // Skip navigation for friend requests
    if (notification.type == NotificationType.friendRequest) {
      return;
    }

    // Validate postId
    if (notification.postId == null || notification.postId!.isEmpty) {
      debugPrint('⚠️ [NotificationsPage] Cannot navigate: empty postId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open post. Post ID is missing.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Mark as read when tapped (after navigation starts, but don't remove the notification)
      if (!notification.read) {
        // Mark as read in background, don't wait for it
        _controller.markAsRead(notification.id).catchError((e) {
          debugPrint('⚠️ [NotificationsPage] Error marking notification as read: $e');
        });
      }

      // Navigate based on postType
      if (notification.postType == 'lookingFor') {
        // Navigate to looking-for post detail page
        final lookingForPostService = BLookingForPostService();
        final postData = await lookingForPostService.getLookingForPost(notification.postId!);
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (postData != null) {
          // Ensure ID is included
          final postDataWithId = {
            'id': notification.postId!,
            ...postData,
          };
          final post = LookingForPostModel.fromMap(postDataWithId);
          
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LookingForPostDetailPage(post: post),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post not found. It may have been deleted.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Default to listing (or if postType is 'listing' or null)
        final listingService = BListingService();
        final listingData = await listingService.getListing(notification.postId!);
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (listingData != null) {
          // Ensure ID is included
          final listingDataWithId = {
            'id': notification.postId!,
            ...listingData,
          };
          final listing = ListingModel.fromMap(listingDataWithId);
          
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailsPage(listing: listing),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Listing not found. It may have been deleted.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationsPage] Error navigating to notification target: $e');
      debugPrint('❌ [NotificationsPage] Stack trace: $stackTrace');
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading post: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return IconButton(
                icon: Image.asset(
                  'assets/chat.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.chat_bubble_outline,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    );
                  },
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatsListPage(),
                    ),
                  );
                },
                tooltip: 'Messages',
              );
            },
          ),
          const SizedBox(width: 2),
          ThreeDotsMenu(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? Colors.grey[900] : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00B8E6),
              labelColor: const Color(0xFF00B8E6),
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
      return NotificationSkeleton(isDark: isDark);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                            color: const Color(0xFF00B8E6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
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
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark
                              ? Colors.grey[800]!.withValues(alpha: 0.5)
                              : Colors.grey[300]!.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<NotificationModel> _getNewNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    return notifications.where((n) {
      final diff = now.difference(n.timestamp);
      // Include all notifications from last 60 minutes (both read and unread)
      return diff.inMinutes < 60;
    }).toList();
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
