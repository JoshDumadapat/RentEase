import 'package:flutter/material.dart';
import 'package:rentease_app/models/listing_model.dart';

// Theme colors matching the listing cards
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

/// Property Tile Widget
/// 
/// Reusable tile for displaying a property in lists.
/// Used in both user properties and favorites sections.
class PropertyTile extends StatelessWidget {
  final ListingModel property;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRemove; // For favorites - "Remove" button
  final bool showMenuButton; // For "My Properties" - show three dots menu
  final bool showRemoveButton; // For "Favorites" - show "Remove" text button

  const PropertyTile({
    super.key,
    required this.property,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRemove,
    this.showMenuButton = false,
    this.showRemoveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Thumbnail
              Align(
                alignment: Alignment.topLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      height: 120,
                      child: Container(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        child: property.imagePaths.isNotEmpty
                            ? _buildPropertyImage(property.imagePaths[0], isDark)
                            : _buildPlaceholder(isDark),
                      ),
                    ),
                  ),
              ),
              
              const SizedBox(width: 12),
              
              // Column 2: Property Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      property.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Date and Time
                    Text(
                      property.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey[500]
                            : Colors.grey[500],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Price and Remove button (for favorites)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱${property.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _themeColorDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/mo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (showRemoveButton && onRemove != null)
                          TextButton(
                            onPressed: onRemove,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[300],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Column 3: Three dots menu or Chevron
              if (showMenuButton)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    offset: const Offset(-10, 30),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) onEdit!();
                      if (value == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: isDark ? Colors.white : Colors.black87),
                              const SizedBox(width: 8),
                              Text('Edit', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              else if (!showRemoveButton)
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyImage(String imagePath, bool isDark) {
    final isNetworkImage = imagePath.startsWith('http://') || 
                           imagePath.startsWith('https://');
    
    if (isNetworkImage) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: 100,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: _themeColorDark,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: 100,
        height: 120,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
      );
    }
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
    );
  }
}

