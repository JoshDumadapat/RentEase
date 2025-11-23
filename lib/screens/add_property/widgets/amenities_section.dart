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
          'Amenities & Rules',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        TextFormField(
          controller: curfewController,
          decoration: _buildInputDecoration(
            hintText: 'e.g., 10:00 PM',
            colorScheme: colorScheme,
          ),
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

  InputDecoration _buildInputDecoration({
    required String hintText,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16,
      ),
      filled: true,
      fillColor: colorScheme.surface,
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
