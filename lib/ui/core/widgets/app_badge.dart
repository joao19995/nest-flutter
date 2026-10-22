import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A compact, non-interactive status pill.
///
/// Colours come exclusively from an [AppBadgeStyles] pair.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    required this.style,
    this.showDot = false,
  });

  final String label;
  final BadgeStyle style;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final borderColor = style.border;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadius.fullAll,
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: AppSizes.badgeDot,
              height: AppSizes.badgeDot,
              decoration: BoxDecoration(
                color: style.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: style.foreground),
          ),
        ],
      ),
    );
  }
}
