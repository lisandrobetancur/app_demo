import 'package:flutter/material.dart';

/// Standard confirmation dialog.
///
/// Callers pass already-translated strings and stable keys; the dialog only
/// owns structure and theming. Resolves to `true` when confirmed.
class AppDialog {
  const AppDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    Key? dialogKey,
    Key? confirmKey,
    Key? cancelKey,
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        key: dialogKey,
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            key: cancelKey,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            key: confirmKey,
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
