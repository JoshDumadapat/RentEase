import 'package:flutter/material.dart';
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

    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
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
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (favorites.isNotEmpty)
                Text(
                  '${favorites.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Favorites List
          if (favorites.isEmpty)
            _EmptyState(
              message: 'No favorites yet',
              subtitle: 'Save properties you like to view them here',
              isDark: isDark,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return PropertyTile(
                  property: favorite,
                  onTap: () => onPropertyTap(favorite),
                  onDelete: () {
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
        ],
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
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

