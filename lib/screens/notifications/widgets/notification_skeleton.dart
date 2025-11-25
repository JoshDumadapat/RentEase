import 'package:flutter/material.dart';

/// Notification Skeleton Loader
/// 
/// Shows shimmer/skeleton loading state matching the new design.
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final skeletonColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final shimmerColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return ListView(
      children: [
        // Section header skeleton
        _buildSectionHeaderSkeleton(skeletonColor, shimmerColor),
        // Notification items
        ...List.generate(3, (index) => _buildNotificationSkeleton(skeletonColor, shimmerColor)),
        // Another section
        _buildSectionHeaderSkeleton(skeletonColor, shimmerColor),
        ...List.generate(2, (index) => _buildNotificationSkeleton(skeletonColor, shimmerColor)),
      ],
    );
  }

  Widget _buildSectionHeaderSkeleton(Color skeletonColor, Color shimmerColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 50,
            height: 16,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSkeleton(Color skeletonColor, Color shimmerColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar skeleton
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: skeletonColor,
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
                    color: shimmerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
