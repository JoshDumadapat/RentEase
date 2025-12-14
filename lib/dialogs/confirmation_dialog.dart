import 'package:flutter/material.dart';

/// Reusable confirmation dialog widget
/// 
/// Shows a confirmation dialog with customizable title, message, and button texts.
/// Returns true if user confirms, false if cancelled.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
  });

  /// Show confirmation dialog
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    const Color _themeColorDark = Color(0xFF00B8E6);

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: subtextColor,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            cancelText,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? (isDark ? _themeColorDark : _themeColorDark),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Discard changes confirmation dialog
/// 
/// Shows a dialog asking if user wants to discard changes.
/// Returns true if user confirms discard, false if cancelled.
Future<bool> showDiscardChangesDialog(
  BuildContext context, {
  String title = 'Discard changes?',
  String message = 'All entered information will be cleared if you go back.',
  String confirmText = 'Discard',
  String cancelText = 'Stay',
}) async {
  return await ConfirmationDialog.show(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: cancelText,
    confirmColor: Colors.red[600],
  );
}

/// Logout confirmation dialog
/// 
/// Shows a dialog asking if user wants to logout.
/// Returns true if user confirms logout, false if cancelled.
Future<bool> showLogoutDialog(BuildContext context) async {
  return await ConfirmationDialog.show(
    context,
    title: 'Logout',
    message: 'Are you sure you want to logout?',
    confirmText: 'Logout',
    cancelText: 'Cancel',
  );
}

/// Delete confirmation dialog
/// 
/// Shows a dialog asking if user wants to delete an item.
/// Returns true if user confirms delete, false if cancelled.
Future<bool> showDeleteDialog(
  BuildContext context, {
  String itemName = 'this item',
}) async {
  return await ConfirmationDialog.show(
    context,
    title: 'Delete $itemName?',
    message: 'This action cannot be undone.',
    confirmText: 'Delete',
    cancelText: 'Cancel',
  );
}



