import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_button.dart';

/// A coral panel stating why the last action failed.
///
/// When [onDismiss] is given the banner gains a close button, so it can be
/// dismissed in place instead of disappearing on the next state change.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final onDismiss = this.onDismiss;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.dangerSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconMedium,
            color: context.colors.dangerOnSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.small(
                context.colors,
              ).copyWith(color: context.colors.dangerOnSoft),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppSpacing.sm),
            AppButton.icon(
              icon: Icons.close,
              tooltip: 'Fechar aviso',
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
