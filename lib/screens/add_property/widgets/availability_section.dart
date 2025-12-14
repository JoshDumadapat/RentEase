import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Section for property availability information
/// 
/// Includes:
/// - Available from date picker
/// - Max occupants input
class AvailabilitySection extends StatelessWidget {
  final DateTime? availableFrom;
  final TextEditingController maxOccupantsController;
  final VoidCallback onDateSelected;
  final Function(int?) onMaxOccupantsChanged;

  const AvailabilitySection({
    super.key,
    required this.availableFrom,
    required this.maxOccupantsController,
    required this.onDateSelected,
    required this.onMaxOccupantsChanged,
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
          'Availability',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Available From Date
        _buildLabel('Available From', colorScheme, required: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: onDateSelected,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? Colors.grey[800] 
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  availableFrom != null
                      ? _formatDate(availableFrom!)
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 16,
                    color: availableFrom != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Max Occupants
        _buildLabel('Max Occupants', colorScheme, required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: maxOccupantsController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: _buildInputDecoration(
            hintText: 'e.g., 2',
            colorScheme: colorScheme,
            theme: theme,
          ),
          onChanged: (value) {
            final intValue = int.tryParse(value);
            onMaxOccupantsChanged(intValue);
          },
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

