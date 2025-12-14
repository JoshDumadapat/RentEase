import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/screens/profile/widgets/property_tile.dart';
import 'package:rentease_app/screens/drafts/drafts_page.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';

const Color _themeColorDark = Color(0xFF00B8E6);

/// Property List Section Widget
/// 
/// Displays user's posted properties:
/// - List of properties with thumbnails
/// - Tap to open property details
/// - Edit/delete actions per property
class PropertyListSection extends StatelessWidget {
  final List<ListingModel> properties;
  final Function(ListingModel) onPropertyTap;

  const PropertyListSection({
    super.key,
    required this.properties,
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
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
          mainAxisSize: MainAxisSize.min,
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
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DraftsPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.drafts_outlined,
                    size: 18,
                    color: _themeColorDark,
                  ),
                  label: Text(
                    'Drafts',
                    style: TextStyle(
                      fontSize: 14,
                      color: _themeColorDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          // Properties List
          Transform.translate(
            offset: const Offset(0, -12),
            child: properties.isEmpty
                ? _EmptyState(
                    message: 'No properties yet',
                    subtitle: 'Add your first property to get started',
                    isDark: isDark,
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: properties.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return PropertyTile(
                        property: property,
                        onTap: () => onPropertyTap(property),
                        showMenuButton: true,
                        onEdit: () {
                          // Note: Navigation to edit property page will be implemented when backend is ready
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBarUtils.buildThemedSnackBar(context, 'Edit property: ${property.title}'),
                          );
                        },
                        onDelete: () {
                          // Note: Delete confirmation and property deletion will be implemented when backend is ready
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBarUtils.buildThemedSnackBar(context, 'Delete property: ${property.title}'),
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
              'assets/icons/navbar/home_outlined.svg',
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

