import 'package:flutter/material.dart';

/// Optimized shimmer effect widget with light reflection (standard gradient sweep)
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool isDark;
  
  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.isDark = false,
  });
  
  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final highlightColor = widget.highlightColor ?? 
        (widget.isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.8));
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final width = constraints.maxWidth;
            final shimmerWidth = width * 0.3;
            final shimmerPosition = -width + (_controller.value * (width + shimmerWidth));
            
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                widget.child,
                Positioned.fill(
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: Transform.translate(
                      offset: Offset(shimmerPosition, 0),
                      child: Container(
                        width: shimmerWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              highlightColor,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Skeleton loading widget for Looking For tab with shimmer effect
class LookingForSkeleton extends StatelessWidget {
  final bool isDark;
  
  const LookingForSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final skeletonColor = isDark ? Colors.grey[700] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header Section Skeleton - matches actual header structure
          // Note: No AppBar in Looking For skeleton - it's part of the parent TabBarView
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                      width: 120,
                      height: 28,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                      width: 70,
                      height: 28,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Posts Skeleton
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == 2 ? 32 : 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (avatar + name + time + more button) - matches actual structure
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                            child: Row(
                              children: [
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ShimmerEffect(
                                            isDark: isDark,
                                            child: Container(
                                              width: 100,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: skeletonColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ShimmerEffect(
                                            isDark: isDark,
                                            child: Container(
                                              width: 60,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                color: skeletonColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Post content - matches actual structure (3 lines of description)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: double.infinity,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: double.infinity,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: 200,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tags Section - matches actual structure (3 tags with icons)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 70,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 80,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 90,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action Bar - matches actual structure (like and comment buttons)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Like Button
                                Row(
                                  children: [
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 30,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 32),
                                // Comment Button
                                Row(
                                  children: [
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 30,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

