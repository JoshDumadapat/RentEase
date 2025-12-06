import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/profile/widgets/property_tile.dart';

/// Favorites Section Widget
/// 
/// Displays user's favorited/saved properties:
/// - List of favorited properties
/// - Tap to open property details
/// - Optional: remove from favorites
class FavoritesSection extends StatelessWidget {
  final List<ListingModel> favorites;
  final Function(ListingModel) onPropertyTap;

  const FavoritesSection({
    super.key,
    required this.favorites,
    required this.onPropertyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Favorites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (favorites.isNotEmpty)
                  Text(
                    '${favorites.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          // Favorites List
          Transform.translate(
            offset: const Offset(0, -12),
            child: favorites.isEmpty
                ? _EmptyState(
                    message: 'No favorites yet',
                    subtitle: 'Save properties you like to view them here',
                    isDark: isDark,
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favorites.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final favorite = favorites[index];
                      return PropertyTile(
                        property: favorite,
                        onTap: () => onPropertyTap(favorite),
                        showRemoveButton: true,
                        onRemove: () {
                          // Note: Remove from favorites functionality will be implemented when backend is ready
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${favorite.title} from favorites'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.message,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/icons/navbar/heart_outlined.svg',
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(
                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

