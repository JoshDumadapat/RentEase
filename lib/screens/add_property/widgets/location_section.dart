import 'package:flutter/material.dart';

/// Section for property location information
/// 
/// Includes:
/// - Address input
/// - Landmark
/// - Map picker button
/// - GPS auto-fill button
class LocationSection extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController landmarkController;
  final VoidCallback onMapPicker;
  final VoidCallback onGPSFill;

  const LocationSection({
    super.key,
    required this.addressController,
    required this.landmarkController,
    required this.onMapPicker,
    required this.onGPSFill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Address Field
        _buildLabel('Address', colorScheme, required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: addressController,
          maxLines: 2,
          decoration: _buildInputDecoration(
            hintText: 'Enter full address',
            colorScheme: colorScheme,
            theme: theme,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Landmark Field
        _buildLabel('Landmark', colorScheme, required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: landmarkController,
          decoration: _buildInputDecoration(
            hintText: 'e.g., Near SM Mall, Behind University',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
        const SizedBox(height: 24),
        // Action Buttons - Enhanced with lighter borders
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2), // Lighter border
                    width: 1.5,
                  ),
                ),
                child: OutlinedButton.icon(
                  onPressed: onMapPicker,
                  icon: Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Pick on Map',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide.none, // Remove default border, using container border
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2), // Lighter border
                    width: 1.5,
                  ),
                ),
                child: OutlinedButton.icon(
                  onPressed: onGPSFill,
                  icon: Icon(
                    Icons.my_location,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Use GPS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide.none, // Remove default border, using container border
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(
    String label,
    ColorScheme colorScheme, {
    required bool required,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16,
      ),
      filled: true,
      fillColor: theme.brightness == Brightness.dark 
          ? Colors.grey[800] 
          : colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}

