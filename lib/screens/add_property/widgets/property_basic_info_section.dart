import 'package:flutter/material.dart';

/// Section for basic property information
/// 
/// Includes:
/// - Property title
/// - Description
/// - Property type selection
class PropertyBasicInfoSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? propertyType;
  final Function(String?) onPropertyTypeChanged;

  const PropertyBasicInfoSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.propertyType,
    required this.onPropertyTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final propertyTypes = [
      'Room',
      'Boarding House',
      'Apartment',
      'Condo',
      'Studio',
      'Dorm',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Title Field
        _buildLabel('Title', colorScheme),
        const SizedBox(height: 8),
        TextFormField(
          controller: titleController,
          maxLength: 50,
          decoration: _buildInputDecoration(
            hintText: 'e.g., Cozy 2BR Apartment near University',
            colorScheme: colorScheme,
            theme: theme,
          ).copyWith(
            counterText: '', // Hide character counter
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            if (value.length < 10) {
              return 'Title must be at least 10 characters';
            }
            if (value.length > 50) {
              return 'Title must not exceed 50 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Description Field
        _buildLabel('Description', colorScheme),
        const SizedBox(height: 8),
        TextFormField(
          controller: descriptionController,
          maxLines: 5,
          decoration: _buildInputDecoration(
            hintText: 'Describe your property in detail...',
            colorScheme: colorScheme,
            theme: theme,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            if (value.length < 30) {
              return 'Description must be at least 30 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Property Type Selection
        _buildLabel('Property Type', colorScheme),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: propertyTypes.map((type) {
            final isSelected = propertyType == type;
            return FilterChip(
              selected: isSelected,
              label: Text(type),
              onSelected: (selected) {
                onPropertyTypeChanged(selected ? type : null);
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, ColorScheme colorScheme) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
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

