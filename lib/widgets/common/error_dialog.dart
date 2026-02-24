import 'package:flutter/material.dart';

/// Error Dialog Widget
/// Displays error messages in a Material Dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF3B30)),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onDismiss: () => Navigator.pop(context),
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}
