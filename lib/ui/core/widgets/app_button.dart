import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// The visual variants of an [AppButton], following Material 3 roles.
enum AppButtonVariant { primary, secondary, ghost, destructive }

/// Material 3 state-layer opacities.
const double _stateHoverOpacity = 0.08;
const double _statePressedOpacity = 0.10;

/// A Nest button in the Material 3 style.
///
/// [primary] is a filled button, [secondary] a tonal one, [ghost] a text
/// button and [destructive] a filled error button. Corner radius, height,
/// ripple and state layers follow the Material 3 button specs.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : tooltip = null,
       assert(label != '', 'Use AppButton.icon for an icon-only button.');

  /// Creates an icon-only button. The [tooltip] carries the accessible label.
  const AppButton.icon({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.variant = AppButtonVariant.ghost,
  }) : label = '',
       isLoading = false,
       isFullWidth = false;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final String? tooltip;

  bool get _isIconOnly => label.isEmpty;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      style: _style(),
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(),
    );

    final tooltip = this.tooltip;
    final wrapped = tooltip == null
        ? button
        : Tooltip(message: tooltip, child: button);

    if (!isFullWidth) {
      return wrapped;
    }
    return SizedBox(width: double.infinity, child: wrapped);
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: AppSizes.iconSmall,
        height: AppSizes.iconSmall,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_isIconOnly) {
      return Icon(icon, size: AppSizes.iconMedium);
    }
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconMedium),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }

  ButtonStyle _style() {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(AppTextStyles.button),
      alignment: Alignment.center,
      padding: WidgetStatePropertyAll(
        _isIconOnly
            ? const EdgeInsets.all(AppSpacing.sm)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
      ),
      minimumSize: WidgetStatePropertyAll(
        _isIconOnly
            ? const Size.square(AppSizes.buttonHeight)
            : const Size(0, AppSizes.buttonHeight),
      ),
      shape: WidgetStatePropertyAll(
        _isIconOnly ? const CircleBorder() : const StadiumBorder(),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      enableFeedback: true,
      animationDuration: AppMotion.standard,
      splashFactory: InkSparkle.splashFactory,
      overlayColor: WidgetStateProperty.resolveWith(_overlayColor),
      backgroundColor: WidgetStateProperty.resolveWith(_backgroundColor),
      foregroundColor: WidgetStateProperty.resolveWith(_foregroundColor),
    );
  }

  Color _backgroundColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return variant == AppButtonVariant.ghost
          ? AppColors.transparent
          : AppColors.lineSoft;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.mint;
      case AppButtonVariant.ghost:
        return AppColors.transparent;
      case AppButtonVariant.destructive:
        return AppColors.over;
    }
  }

  Color _foregroundColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.faint;
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.surface;
      case AppButtonVariant.secondary:
        return AppColors.primaryDark;
      case AppButtonVariant.ghost:
        return AppColors.primary;
      case AppButtonVariant.destructive:
        return AppColors.surface;
    }
  }

  /// The Material 3 state layer: a translucent tint of the label colour.
  Color _overlayColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.transparent;
    }
    final base = _foregroundColor(states);
    if (states.contains(WidgetState.pressed)) {
      return base.withValues(alpha: _statePressedOpacity);
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return base.withValues(alpha: _stateHoverOpacity);
    }
    return AppColors.transparent;
  }
}
