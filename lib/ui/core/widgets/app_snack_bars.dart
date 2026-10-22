import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// Shows the shared Nest snack bar, optionally with an undo-style action.
///
/// The action variant is explicitly non-persistent: Flutter otherwise keeps a
/// snack bar with an action on screen until it is dismissed.
void showAppSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppMotion.snackBar,
        persist: false,
        action: onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel ?? 'Anular',
                onPressed: onAction,
              ),
      ),
    );
}
