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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(confirmText),
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



