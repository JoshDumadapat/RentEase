import 'package:flutter/material.dart';

// Theme colors matching the listing cards
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

/// Property Actions Card Widget
/// 
/// Top card containing:
/// - Add New Property button
/// - Filter button for My Properties
class PropertyActionsCard extends StatelessWidget {
  final VoidCallback onAddProperty;
  final VoidCallback onFilter;

  const PropertyActionsCard({
    super.key,
    required this.onAddProperty,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
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
            // Add Property Button
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onAddProperty,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Property'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Filter Button
            FilledButton(
              onPressed: onFilter,
              style: FilledButton.styleFrom(
                backgroundColor: _themeColorDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.filter_list, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

