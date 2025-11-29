import 'package:flutter/material.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/profile/widgets/property_tile.dart';

/// Property List Section Widget
/// 
/// Displays user's posted properties:
/// - List of properties with thumbnails
/// - Tap to open property details
/// - Edit/delete actions per property
/// - Add new property button
class PropertyListSection extends StatelessWidget {
  final List<ListingModel> properties;
  final Function(ListingModel) onPropertyTap;
  final VoidCallback onAddProperty;

  const PropertyListSection({
    super.key,
    required this.properties,
    required this.onPropertyTap,
    required this.onAddProperty,
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
                'My Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (properties.isNotEmpty)
                Text(
                  '${properties.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Add Property Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddProperty,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New Property'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Properties List
          if (properties.isEmpty)
            _EmptyState(
              message: 'No properties yet',
              subtitle: 'Add your first property to get started',
              isDark: isDark,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: properties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final property = properties[index];
                return PropertyTile(
                  property: property,
                  onTap: () => onPropertyTap(property),
                  onEdit: () {
                    // Note: Navigation to edit property page will be implemented when backend is ready
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Edit property: ${property.title}'),
                      ),
                    );
                  },
                  onDelete: () {
                    // Note: Delete confirmation and property deletion will be implemented when backend is ready
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Delete property: ${property.title}'),
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
            Icons.home_outlined,
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

