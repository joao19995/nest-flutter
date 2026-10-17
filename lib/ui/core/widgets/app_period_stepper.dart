import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A pill-shaped period selector: previous arrow, a label, next arrow.
///
/// Designed for the dark gradient hero, so it uses the fixed on-hero surface
/// and ink — identical to the month and year selectors it replaces. Passing a
/// null callback disables that arrow.
class AppPeriodStepper extends StatelessWidget {
  const AppPeriodStepper({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
  });

  /// The formatted period, e.g. `"Outubro 2026"`.
  final String label;

  /// Selects the previous period; null disables the left arrow.
  final VoidCallback? onPrevious;

  /// Selects the next period; null disables the right arrow.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.fullAll,
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperArrow(
            icon: Icons.chevron_left,
            onTap: onPrevious,
            tooltip: 'Anterior',
          ),
          Text(
            label,
            style: AppTextStyles.label(
              context.colors,
            ).copyWith(color: AppColors.primaryDark),
          ),
          _StepperArrow(
            icon: Icons.chevron_right,
            onTap: onNext,
            tooltip: 'Seguinte',
          ),
        ],
      ),
    );
  }
}

class _StepperArrow extends StatelessWidget {
  const _StepperArrow({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: AppSizes.iconMedium,
            color: onTap == null ? AppColors.faint : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
