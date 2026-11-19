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
    String? dialogSemanticsId,
    String? confirmSemanticsId,
    String? cancelSemanticsId,
    bool destructive = false,
  }) async {
    // Each button's identifier goes on its child, which merges into the
    // button's own node; the dialog's needs a node of its own (`container`),
    // and `explicitChildNodes` keeps its title, message and buttons apart.
    Widget labelled(String? id, Widget child) =>
        id == null ? child : Semantics(identifier: id, child: child);
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final Widget dialog = AlertDialog(
          key: dialogKey,
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              key: cancelKey,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: labelled(cancelSemanticsId, Text(cancelLabel)),
            ),
            TextButton(
              key: confirmKey,
              style: destructive
                  ? TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: labelled(confirmSemanticsId, Text(confirmLabel)),
            ),
          ],
        );
        if (dialogSemanticsId == null) {
          return dialog;
        }
        return Semantics(
          container: true,
          explicitChildNodes: true,
          identifier: dialogSemanticsId,
          child: dialog,
        );
      },
    );
    return result ?? false;
  }
}
