import 'package:flutter/material.dart';

/// Custom SliverPersistentHeaderDelegate for animated TabBar
/// Provides fade and slide animations based on scroll direction
class AnimatedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final double minHeight;
  final double maxHeight;
  final ValueNotifier<double>? scrollOffsetNotifier;

  AnimatedTabBarDelegate({
    required this.tabBar,
    this.minHeight = 40.0,
    this.maxHeight = 40.0,
    this.scrollOffsetNotifier,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Use shrinkOffset to determine visibility
    // When scrolling down, shrinkOffset increases, opacity decreases
    // When scrolling up, shrinkOffset decreases, opacity increases
    final double maxShrinkOffset = maxExtent - minExtent;
    
    // Normalize progress from 0.0 to 1.0
    final double progress = maxShrinkOffset > 0 
        ? (shrinkOffset / maxShrinkOffset).clamp(0.0, 1.0)
        : 0.0;
    
    // Opacity: 1.0 at top, 0.0 when scrolled down
    // Smooth transition with curve
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    // Vertical translation: slide up as we scroll down
    final double translateY = shrinkOffset.clamp(0.0, maxExtent);

    return Container(
      color: Colors.white,
      child: Transform.translate(
        offset: Offset(0, -translateY),
        child: Opacity(
          opacity: opacity,
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(AnimatedTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        scrollOffsetNotifier != oldDelegate.scrollOffsetNotifier;
  }
}

