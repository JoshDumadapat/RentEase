import 'package:flutter/material.dart';
import 'package:rentease_app/screens/home/widgets/home_skeleton.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';

/// Notification Skeleton Loader with shimmer effect
/// 
/// Shows shimmer/skeleton loading state matching the notification design.
class NotificationSkeleton extends StatelessWidget {
  final bool isDark;
  
  const NotificationSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = isDark || theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final skeletonColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: ShimmerEffect(
            isDark: isDarkMode,
            child: Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            const ThreeDotsMenu(),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              child: TabBar(
                indicatorColor: const Color(0xFF00B8E6),
                labelColor: const Color(0xFF00B8E6),
                unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unread'),
                ],
              ),
            ),
          ),
        ),
      body: ListView(
        children: [
          // New Section
          _buildSection(
            title: 'New',
            showSeeAll: true,
            itemCount: 3,
            isDark: isDarkMode,
            skeletonColor: skeletonColor,
            cardColor: cardColor,
          ),
          const SizedBox(height: 8),
          // Today Section
          _buildSection(
            title: 'Today',
            showSeeAll: false,
            itemCount: 2,
            isDark: isDarkMode,
            skeletonColor: skeletonColor,
            cardColor: cardColor,
          ),
          const SizedBox(height: 8),
          // Earlier Section
          _buildSection(
            title: 'Earlier',
            showSeeAll: false,
            itemCount: 2,
            isDark: isDarkMode,
            skeletonColor: skeletonColor,
            cardColor: cardColor,
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool showSeeAll,
    required int itemCount,
    required bool isDark,
    required Color skeletonColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerEffect(
            isDark: isDark,
            child: Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                    color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
              if (showSeeAll)
          ShimmerEffect(
            isDark: isDark,
            child: Container(
              width: 50,
              height: 16,
              decoration: BoxDecoration(
                      color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
        ),
        // Notification items in card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
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
                children: [
                  ...List.generate(
                    itemCount,
                    (index) => _buildNotificationSkeleton(
                      isDark,
                      skeletonColor,
                      index == itemCount - 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSkeleton(bool isDark, Color skeletonColor, bool isLast) {
    final avatarColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final borderColor = isDark ? Colors.grey[900]! : Colors.white;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar skeleton with overlay icon
              ShimmerEffect(
                isDark: isDark,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Overlay icon skeleton
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Text skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification text (2-3 lines)
                    ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Time ago
                    ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        width: 80,
                        height: 13,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 72.0),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: dividerColor.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}
