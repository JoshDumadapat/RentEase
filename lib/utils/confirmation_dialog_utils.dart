import 'package:flutter/material.dart';

/// Shows a generic confirmation dialog for discarding changes / clearing input.
///
/// Returns:
/// - `true` if the user confirms the action
/// - `false` if the user cancels or dismisses the dialog
Future<bool> showDiscardChangesDialog(
  BuildContext context, {
  String title = 'Discard changes?',
  String message = 'All entered information will be cleared if you go back.',
  String confirmText = 'Discard',
  String cancelText = 'Stay',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Slightly more rounded corners
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9), // Slightly more rounded button
              ),
            ),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9), // Slightly more rounded button
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );

  return result == true;
}


