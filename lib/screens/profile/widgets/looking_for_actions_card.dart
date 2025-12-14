import 'package:flutter/material.dart';

// Theme colors matching the listing cards
const Color _themeColorDark = Color(0xFF00B8E6); // Darker shade for text (like blue[700])

/// Looking For Post Actions Card Widget
/// 
/// Top card containing:
/// - Add New Post button
/// - Filter button for My Posts
class LookingForActionsCard extends StatelessWidget {
  final VoidCallback onAddPost;
  final VoidCallback onFilter;

  const LookingForActionsCard({
    super.key,
    required this.onAddPost,
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
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              spreadRadius: 0,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Add Post Button
            Expanded(
              flex: 2,
              child: isDark
                  ? OutlinedButton.icon(
                      onPressed: onAddPost,
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Add New Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onAddPost,
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.black87,
                      ),
                      label: const Text(
                        'Add New Post',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.grey[400]!.withOpacity(0.5),
                          width: 1,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Filter Button
            Container(
              decoration: BoxDecoration(
                color: _themeColorDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _themeColorDark.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: onFilter,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.filter_list, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

