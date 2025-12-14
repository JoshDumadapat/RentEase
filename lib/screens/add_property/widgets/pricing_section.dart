import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Section for property pricing information
///
/// Includes:
/// - Monthly rent
/// - Deposit (optional)
/// - Advance payment (optional)
/// - Utility toggles (Electricity, Water, Internet)
class PricingSection extends StatelessWidget {
  final TextEditingController monthlyRentController;
  final TextEditingController depositController;
  final TextEditingController advanceController;
  final bool electricityIncluded;
  final bool waterIncluded;
  final bool internetIncluded;
  final Function(bool) onElectricityChanged;
  final Function(bool) onWaterChanged;
  final Function(bool) onInternetChanged;

  const PricingSection({
    super.key,
    required this.monthlyRentController,
    required this.depositController,
    required this.advanceController,
    required this.electricityIncluded,
    required this.waterIncluded,
    required this.internetIncluded,
    required this.onElectricityChanged,
    required this.onWaterChanged,
    required this.onInternetChanged,
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
          'Pricing',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        // Monthly Rent
        _buildLabel('Monthly Rent', colorScheme, required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: monthlyRentController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
          decoration: _buildInputDecoration(
            hintText: '0',
            prefixText: '₱',
            colorScheme: colorScheme,
            theme: theme,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Monthly rent is required';
            }
            final amount = _parseAmount(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Deposit
        _buildLabel('Deposit', colorScheme, required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: depositController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
          decoration: _buildInputDecoration(
            hintText: '0 (optional)',
            prefixText: '₱',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
        const SizedBox(height: 24),
        // Advance Payment
        _buildLabel('Advance Payment', colorScheme, required: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: advanceController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
          decoration: _buildInputDecoration(
            hintText: '0 (optional)',
            prefixText: '₱',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
        const SizedBox(height: 24),
        // Utility Toggles
        Text(
          'Utilities Included',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildUtilityToggle(
          label: 'Electricity',
          value: electricityIncluded,
          onChanged: onElectricityChanged,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildUtilityToggle(
          label: 'Water',
          value: waterIncluded,
          onChanged: onWaterChanged,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildUtilityToggle(
          label: 'Internet',
          value: internetIncluded,
          onChanged: onInternetChanged,
          colorScheme: colorScheme,
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

  Widget _buildUtilityToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? prefixText,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16,
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: theme.brightness == Brightness.dark ? Colors.white : colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  double? _parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned);
  }
}

/// Input formatter for currency with thousand separators
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Add thousand separators
    final formatted = _addThousandSeparators(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addThousandSeparators(String value) {
    final reversed = value.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.substring(i, end));
    }
    return chunks.join(',').split('').reversed.join();
  }
}
