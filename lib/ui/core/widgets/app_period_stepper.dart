import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// Where the period stepper is rendered.
enum AppPeriodStepperVariant {
  /// A white pill for the always-dark gradient hero.
  hero,

  /// Plain arrows and a label for a light card.
  inline,
}

/// A period selector: previous arrow, a label, next arrow.
///
/// Passing a null callback disables that arrow. Use [variant] to switch
/// between the hero pill and the light-card inline presentation.
class AppPeriodStepper extends StatelessWidget {
  const AppPeriodStepper({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
    this.variant = AppPeriodStepperVariant.hero,
    this.previousTooltip = 'Anterior',
    this.nextTooltip = 'Seguinte',
  });

  /// The formatted period, e.g. `"Outubro 2026"`.
  final String label;

  /// Selects the previous period; null disables the left arrow.
  final VoidCallback? onPrevious;

  /// Selects the next period; null disables the right arrow.
  final VoidCallback? onNext;

  final AppPeriodStepperVariant variant;
  final String previousTooltip;
  final String nextTooltip;

  bool get _isHero => variant == AppPeriodStepperVariant.hero;

  @override
  Widget build(BuildContext context) {
    final enabledColor = _isHero
        ? AppColors.primaryDark
        : context.colors.primary;
    final disabledColor = _isHero ? AppColors.faint : context.colors.faint;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperArrow(
          icon: Icons.chevron_left,
          onTap: onPrevious,
          tooltip: previousTooltip,
          enabledColor: enabledColor,
          disabledColor: disabledColor,
        ),
        Text(
          label,
          style: AppTextStyles.label(
            context.colors,
          ).copyWith(color: _isHero ? AppColors.primaryDark : enabledColor),
        ),
        _StepperArrow(
          icon: Icons.chevron_right,
          onTap: onNext,
          tooltip: nextTooltip,
          enabledColor: enabledColor,
          disabledColor: disabledColor,
        ),
      ],
    );
    if (!_isHero) {
      return content;
    }
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.fullAll,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

class _StepperArrow extends StatelessWidget {
  const _StepperArrow({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.enabledColor,
    required this.disabledColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color enabledColor;
  final Color disabledColor;

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
            color: onTap == null ? disabledColor : enabledColor,
          ),
        ),
      ),
    );
  }
}
