// ignore_for_file: file_names

/// Backend utility class for phone number formatting and validation
class BPhoneNumberUtils {
  /// Format phone number based on country code
  /// Returns formatted phone number string
  /// 
  /// For Philippines (+63): Formats to XXX XXX XXXX (10 digits after country code)
  /// Example: 09366669571 -> 936 666 9571
  static String formatPhoneNumber(String phoneNumber, String countryCode) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Philippines (+63)
    if (countryCode == '+63') {
      // Remove leading 0 if present (e.g., 09366669571 -> 9366669571)
      // Only remove if it's followed by 9 and makes it 11 digits total
      if (digitsOnly.startsWith('09') && digitsOnly.length == 11) {
        digitsOnly = digitsOnly.substring(1);
      } else if (digitsOnly.startsWith('0') && digitsOnly.length > 10) {
        digitsOnly = digitsOnly.substring(1);
      }
      
      // Format as XXX XXX XXXX (10 digits)
      if (digitsOnly.length <= 3) {
        return digitsOnly;
      } else if (digitsOnly.length <= 6) {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
      } else if (digitsOnly.length <= 10) {
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
      } else {
        // If more than 10 digits, truncate to 10
        return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6, 10)}';
      }
    }
    
    // For other countries, return digits only (no formatting yet)
    return digitsOnly;
  }

  /// Validate phone number based on country code
  /// Returns error message if invalid, null if valid
  static String? validatePhoneNumber(String phoneNumber, String countryCode) {
    // Remove all non-digit characters for validation
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Philippines (+63)
    if (countryCode == '+63') {
      // Remove leading 0 if present (e.g., 09366669571 -> 9366669571)
      if (digitsOnly.startsWith('0') && digitsOnly.length > 10) {
        digitsOnly = digitsOnly.substring(1);
      }
      
      // Must be exactly 10 digits
      if (digitsOnly.isEmpty) {
        return 'Phone number is required';
      }
      
      if (digitsOnly.length < 10) {
        return 'Please enter a valid phone number';
      }
      
      if (digitsOnly.length > 10) {
        return 'Please enter a valid phone number';
      }
      
      // Philippines mobile numbers must start with 9 (after removing leading 0)
      // Valid formats: 09XXXXXXXXX or 9XXXXXXXXX (10 digits starting with 9)
      if (!digitsOnly.startsWith('9')) {
        return 'Must start with 9';
      }
    } else {
      // For other countries, basic validation
      if (digitsOnly.isEmpty) {
        return 'Phone number is required';
      }
      
      if (digitsOnly.length < 10) {
        return 'Please enter a valid phone number';
      }
    }
    
    return null; // Valid
  }

  /// Get the digits-only version of phone number (for storage)
  static String getDigitsOnly(String phoneNumber, String countryCode) {
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle Philippines (+63) - remove leading 0 if present
    // Only remove if it's followed by 9 and makes it 11 digits total
    if (countryCode == '+63') {
      if (digitsOnly.startsWith('09') && digitsOnly.length == 11) {
        digitsOnly = digitsOnly.substring(1);
      } else if (digitsOnly.startsWith('0') && digitsOnly.length > 10) {
        digitsOnly = digitsOnly.substring(1);
      }
    }
    
    return digitsOnly;
  }
}

