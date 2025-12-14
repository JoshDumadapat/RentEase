import 'package:flutter/material.dart';
import 'package:rentease_app/screens/home/widgets/home_skeleton.dart';

/// Skeleton loading widget for Profile Page with shimmer effect
class ProfileSkeleton extends StatelessWidget {
  final bool isDark;
  
  const ProfileSkeleton({super.key, required this.isDark});

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
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: ShimmerEffect(
                isDark: isDark,
                child: Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            actions: [
              ShimmerEffect(
                isDark: isDark,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          
          // User Info Section Skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Avatar and Name Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Avatar
                      ShimmerEffect(
                        isDark: isDark,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                        const SizedBox(width: 20),
                        // Name and Username
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      ShimmerEffect(
                        isDark: isDark,
                        child: Container(
                                  width: 150,
                                  height: 22,
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
                                  width: 100,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: skeletonColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Verified badge skeleton
                              ShimmerEffect(
                                isDark: isDark,
                                child: Container(
                                  width: 80,
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
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Bio Skeleton
                  ShimmerEffect(
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
                  const SizedBox(height: 4),
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                      width: 250,
                      height: 16,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                    
                    const SizedBox(height: 16),
                    
                    // Edit Profile and Share Profile Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ShimmerEffect(
                            isDark: isDark,
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                              height: 36,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
                    
                    const SizedBox(height: 20),
                    
                    // Divider
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contact Info Skeleton
                    Row(
                children: [
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                            width: 18,
                            height: 18,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                              shape: BoxShape.circle,
                      ),
                    ),
                  ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                              width: 150,
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
                  ],
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          
          // User Stats Section Skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 30,
                              height: 22,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 30,
                              height: 22,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 60,
                              height: 12,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 30,
                              height: 22,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 60,
                              height: 12,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          
          // Property Actions Card Skeleton
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                    child: ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerEffect(
                    isDark: isDark,
                    child: Container(
                      width: 44,
                      height: 44,
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
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          
          // Properties List Section Skeleton
          SliverToBoxAdapter(
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerEffect(
                          isDark: isDark,
                          child: Container(
                            width: 120,
                            height: 20,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 12),
                    // Property Items
                    ...List.generate(3, (index) {
                  return Padding(
                        padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                    child: ShimmerEffect(
                      isDark: isDark,
                      child: Container(
                            height: 120,
                        decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                                  height: 120,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 80,
                                          height: 18,
                                      decoration: BoxDecoration(
                                        color: skeletonColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                          height: 16,
                                      decoration: BoxDecoration(
                                        color: skeletonColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 150,
                                          height: 16,
                                      decoration: BoxDecoration(
                                        color: skeletonColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 100,
                                          height: 18,
                                      decoration: BoxDecoration(
                                        color: skeletonColor,
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
                    ),
                  );
                    }),
                  ],
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
