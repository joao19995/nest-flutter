import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A compact, optionally tappable pill whose colours come exclusively from an
/// [AppBadgeStyles] pair.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.style,
    this.icon,
    this.onTap,
  });

  final String label;
  final BadgeStyle style;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final borderColor = style.border;
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.fullAll,
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor),
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSmall, color: style.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: style.foreground),
          ),
        ],
      ),
    );
    return Material(
      color: style.background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, customBorder: shape, child: content),
    );
  }
}
