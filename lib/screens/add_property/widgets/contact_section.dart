import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text input formatter for Philippine phone numbers
/// Format: 09XX XXX XXXX (11 digits total)
/// Example: 0977 838 8347
class PhilippinePhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }
    
    // Format as 09XX XXX XXXX (11 digits: 09XX + XXX + XXXX)
    String formatted = '';
    if (digitsOnly.isEmpty) {
      formatted = '';
    } else if (digitsOnly.length <= 4) {
      // 09XX (no space after 09)
      formatted = digitsOnly;
    } else if (digitsOnly.length <= 7) {
      // 09XX XXX
      formatted = '${digitsOnly.substring(0, 4)} ${digitsOnly.substring(4)}';
    } else {
      // 09XX XXX XXXX
      formatted = '${digitsOnly.substring(0, 4)} ${digitsOnly.substring(4, 7)} ${digitsOnly.substring(7)}';
    }
    
    // Calculate new cursor position
    int cursorPosition = formatted.length;
    if (oldValue.text.length < newValue.text.length) {
      // User is typing forward
      if (formatted.length > oldValue.text.length) {
        // Check if we added a space
        if (formatted.length == oldValue.text.length + 1 && 
            formatted[formatted.length - 1] == ' ') {
          cursorPosition = formatted.length;
        } else {
          cursorPosition = newValue.selection.baseOffset + (formatted.length - oldValue.text.length);
        }
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition.clamp(0, formatted.length)),
    );
  }
  
  /// Get digits only from formatted phone number
  static String getDigitsOnly(String formattedPhone) {
    return formattedPhone.replaceAll(RegExp(r'[^\d]'), '');
  }
  
  /// Format a phone number string to 09XX XXX XXXX format
  /// Example: 0977 838 8347
  static String formatPhone(String phone) {
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }
    
    if (digitsOnly.isEmpty) {
      return '';
    } else if (digitsOnly.length <= 4) {
      // 09XX (no space after 09)
      return digitsOnly;
    } else if (digitsOnly.length <= 7) {
      // 09XX XXX
      return '${digitsOnly.substring(0, 4)} ${digitsOnly.substring(4)}';
    } else {
      // 09XX XXX XXXX
      return '${digitsOnly.substring(0, 4)} ${digitsOnly.substring(4, 7)} ${digitsOnly.substring(7)}';
    }
  }
}

/// Section for contact information
/// 
/// Includes:
/// - Owner name (read-only, auto-filled from Firestore)
/// - Phone number (editable, pre-filled from Firestore)
/// - Messenger/WhatsApp (optional)
class ContactSection extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController messengerController;
  final String? ownerName; // Fetched from Firestore user data

  const ContactSection({
    super.key,
    required this.phoneController,
    required this.messengerController,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Owner name from Firestore user data
    final displayOwnerName = ownerName ?? 'Loading...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Contact details will be shown to potential renters',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        // Owner Name (Read-only, from Firestore)
        _buildLabel('Owner Name', colorScheme),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayOwnerName,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Phone Number
        _buildLabel('Phone Number', colorScheme, required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            PhilippinePhoneFormatter(),
            LengthLimitingTextInputFormatter(14), // 09XX XXX XXXX = 14 characters with spaces (e.g., "0977 838 8347")
          ],
          decoration: _buildInputDecoration(
            hintText: '0977 838 8347',
            prefixIcon: Icons.phone_outlined,
            colorScheme: colorScheme,
            theme: theme,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            
            // Get digits only for validation
            final digitsOnly = PhilippinePhoneFormatter.getDigitsOnly(value);
            
            // Must be exactly 11 digits
            if (digitsOnly.length != 11) {
              return 'Phone number must be 11 digits';
            }
            
            // Must start with 09
            if (!digitsOnly.startsWith('09')) {
              return 'Phone number must start with 09';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Messenger/WhatsApp
        _buildLabel('Messenger/WhatsApp (Optional)', colorScheme),
        const SizedBox(height: 8),
        TextFormField(
          controller: messengerController,
          keyboardType: TextInputType.text,
          decoration: _buildInputDecoration(
            hintText: 'Username or link',
            prefixIcon: Icons.message_outlined,
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(
    String label,
    ColorScheme colorScheme, {
    bool required = false,
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
    IconData? prefixIcon,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
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

