import 'package:flutter/material.dart';

/// Section for property amenities and rules
///
/// Includes checkboxes/toggles for:
/// - Private CR
/// - Shared CR
/// - Kitchen access
/// - WiFi
/// - Laundry
/// - Parking
/// - Security/CCTV
/// - Aircon
/// - Pet friendly
/// - Curfew (optional text input)
class AmenitiesSection extends StatelessWidget {
  final bool privateCR;
  final bool sharedCR;
  final bool kitchenAccess;
  final bool wifi;
  final bool laundry;
  final bool parking;
  final bool security;
  final bool aircon;
  final bool petFriendly;
  final TextEditingController curfewController;
  final Function(bool) onPrivateCRChanged;
  final Function(bool) onSharedCRChanged;
  final Function(bool) onKitchenAccessChanged;
  final Function(bool) onWifiChanged;
  final Function(bool) onLaundryChanged;
  final Function(bool) onParkingChanged;
  final Function(bool) onSecurityChanged;
  final Function(bool) onAirconChanged;
  final Function(bool) onPetFriendlyChanged;

  const AmenitiesSection({
    super.key,
    required this.privateCR,
    required this.sharedCR,
    required this.kitchenAccess,
    required this.wifi,
    required this.laundry,
    required this.parking,
    required this.security,
    required this.aircon,
    required this.petFriendly,
    required this.curfewController,
    required this.onPrivateCRChanged,
    required this.onSharedCRChanged,
    required this.onKitchenAccessChanged,
    required this.onWifiChanged,
    required this.onLaundryChanged,
    required this.onParkingChanged,
    required this.onSecurityChanged,
    required this.onAirconChanged,
    required this.onPetFriendlyChanged,
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
          'Amenities',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Amenities Grid
        _buildAmenityToggle(
          label: 'Private CR',
          value: privateCR,
          onChanged: onPrivateCRChanged,
          icon: Icons.bathroom_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Shared CR',
          value: sharedCR,
          onChanged: onSharedCRChanged,
          icon: Icons.bathroom_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Kitchen Access',
          value: kitchenAccess,
          onChanged: onKitchenAccessChanged,
          icon: Icons.kitchen_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'WiFi',
          value: wifi,
          onChanged: onWifiChanged,
          icon: Icons.wifi_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Laundry',
          value: laundry,
          onChanged: onLaundryChanged,
          icon: Icons.local_laundry_service_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Parking',
          value: parking,
          onChanged: onParkingChanged,
          icon: Icons.local_parking_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Security/CCTV',
          value: security,
          onChanged: onSecurityChanged,
          icon: Icons.security_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Air Conditioning',
          value: aircon,
          onChanged: onAirconChanged,
          icon: Icons.ac_unit_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAmenityToggle(
          label: 'Pet Friendly',
          value: petFriendly,
          onChanged: onPetFriendlyChanged,
          icon: Icons.pets_outlined,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),
        // Curfew Input
        _buildLabel('Curfew (Optional)', colorScheme),
        const SizedBox(height: 8),
        _buildCurfewTimePicker(
          curfewController: curfewController,
            colorScheme: colorScheme,
            theme: theme,
          context: context,
        ),
      ],
    );
  }

  Widget _buildAmenityToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
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

  Widget _buildCurfewTimePicker({
    required TextEditingController curfewController,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required BuildContext context,
  }) {
    // Format time to 12-hour format with AM/PM
    String _formatTime(TimeOfDay time) {
      final hour = time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }

    // Parse time from string (if already set)
    TimeOfDay? _parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      
      try {
        // Try to parse formats like "10:00 PM" or "22:00"
        final parts = timeStr.replaceAll(' ', '').toUpperCase();
        final isPM = parts.contains('PM');
        final isAM = parts.contains('AM');
        
        final timeOnly = parts.replaceAll('AM', '').replaceAll('PM', '');
        final timeParts = timeOnly.split(':');
        
        if (timeParts.length == 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          
          if (isPM && hour != 12) hour += 12;
          if (isAM && hour == 12) hour = 0;
          
          return TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        // If parsing fails, return null
      }
      return null;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: curfewController,
      builder: (context, value, child) {
        final currentTime = _parseTime(value.text);
        final displayText = value.text.isNotEmpty 
            ? value.text 
            : 'Select curfew time';

        return InkWell(
          onTap: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: currentTime ?? const TimeOfDay(hour: 22, minute: 0),
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: colorScheme,
                  ),
                  child: child!,
                );
              },
            );

            if (pickedTime != null) {
              curfewController.text = _formatTime(pickedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: value.text.isNotEmpty
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 16,
                        color: value.text.isNotEmpty
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
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
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
