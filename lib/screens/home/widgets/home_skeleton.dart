import 'package:flutter/material.dart';
import 'package:rentease_app/screens/home/widgets/threedots.dart';

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

/// Skeleton loading widget for HomePage with shimmer effect
class HomeSkeleton extends StatelessWidget {
  final bool isDark;
  final bool isFirstTimeUser;
  
  const HomeSkeleton({
    super.key,
    required this.isDark,
    this.isFirstTimeUser = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final skeletonColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar Skeleton
          SliverAppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            pinned: true,
            leadingWidth: 200,
            leading: Container(
              padding: const EdgeInsets.only(left: 16.0),
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/sign_in_up/signlogo.png',
                height: 38,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.home, color: isDark ? Colors.white : Colors.grey[700], size: 32);
                },
              ),
            ),
            actions: [
              const ThreeDotsMenu(),
              const SizedBox(width: 8),
            ],
          ),
          // Welcome Section Skeleton (only for first-time users)
          if (isFirstTimeUser)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        width: 200,
                        height: 28,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        width: 150,
                        height: 20,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isFirstTimeUser)
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (!isFirstTimeUser)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          // Categories Skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            // Tall card matching _TallCategoryCard (140 + 12 + 140 = 292)
                            ShimmerEffect(
                              isDark: isDark,
                              child: Container(
                                width: double.infinity,
                                height: 292,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Small card matching _SmallCategoryCard
                            ShimmerEffect(
                              isDark: isDark,
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            // First small card (rooms)
                            ShimmerEffect(
                              isDark: isDark,
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Second small card (boardingHouse)
                            ShimmerEffect(
                              isDark: isDark,
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Third small card (studentDorms)
                            ShimmerEffect(
                              isDark: isDark,
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: skeletonColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          // Listings Skeleton - matches actual listing card structure
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == 2 ? 16 : 20,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image skeleton (16:9 aspect ratio) - matches actual structure
                          ShimmerEffect(
                            isDark: isDark,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  color: skeletonColor,
                                ),
                              ),
                            ),
                          ),
                          // Content skeleton - matches actual listing card structure
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category badge and time - matches actual structure
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 80,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 60,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Title - matches actual structure (2 lines)
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: double.infinity,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ShimmerEffect(
                                  isDark: isDark,
                                  child: Container(
                                    width: 200,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Location - matches actual structure
                                Row(
                                  children: [
                                    ShimmerEffect(
                                      isDark: isDark,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: skeletonColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ShimmerEffect(
                                        isDark: isDark,
                                        child: Container(
                                          width: double.infinity,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: skeletonColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Price and Owner - matches actual structure
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ShimmerEffect(
                                          isDark: isDark,
                                          child: Container(
                                            width: 120,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: skeletonColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ShimmerEffect(
                                          isDark: isDark,
                                          child: Container(
                                            width: 70,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: skeletonColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ShimmerEffect(
                                          isDark: isDark,
                                          child: Container(
                                            width: 60,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: skeletonColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ShimmerEffect(
                                          isDark: isDark,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: skeletonColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Divider - matches actual structure
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                                ),
                                const SizedBox(height: 12),
                                // Action buttons - matches actual structure (heart, comment, share icons)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
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
                                        const SizedBox(width: 6),
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
                                        const SizedBox(width: 6),
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
                                        const SizedBox(width: 6),
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
