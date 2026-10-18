import 'package:flutter/material.dart';
import 'package:nest/ui/core/widgets/app_button.dart';

/// Asks the user to confirm a destructive action. Resolves to `false` when
/// dismissed. Shared by every "close month" and "delete" flow.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label: 'Cancelar',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
