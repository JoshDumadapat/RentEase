import 'package:flutter/material.dart';

/// Utility class for creating theme-aware SnackBar notifications
/// 
/// Provides consistent toast notification styling across the app:
/// - Dark mode: white background with black text
/// - Light mode: black background with white text
class SnackBarUtils {
  /// Creates a theme-aware SnackBar with custom styling
  /// 
  /// [context] - BuildContext to access theme
  /// [message] - The message to display
  /// [duration] - Optional duration (defaults to 2 seconds)
  /// 
  /// Returns a SnackBar with theme-appropriate colors
  static SnackBar buildThemedSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.black87 : Colors.white,
        ),
      ),
      backgroundColor: isDark ? Colors.white : Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
