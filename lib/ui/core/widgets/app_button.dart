import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// The visual variants of an [AppButton].
enum AppButtonVariant { primary, secondary, ghost, destructive }

/// A Nest button.
///
/// Variants follow the web system: [primary] is ink-filled, [secondary] is
/// outlined, [ghost] is low-emphasis, [destructive] uses the coral pair.
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
    if (label.isEmpty) {
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
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.buttonHeight)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        final isActive =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        switch (variant) {
          case AppButtonVariant.primary:
            return isActive ? AppColors.inkSoft : AppColors.ink;
          case AppButtonVariant.secondary:
            return AppColors.surface;
          case AppButtonVariant.ghost:
            return isActive ? AppColors.mintSoft : Colors.transparent;
          case AppButtonVariant.destructive:
            return AppColors.dangerSoft;
        }
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        final isActive =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        switch (variant) {
          case AppButtonVariant.primary:
            return AppColors.surface;
          case AppButtonVariant.secondary:
            return isActive ? AppColors.primaryDark : AppColors.inkSoft;
          case AppButtonVariant.ghost:
            return isActive ? AppColors.ink : AppColors.muted;
          case AppButtonVariant.destructive:
            return AppColors.dangerOnSoft;
        }
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (variant != AppButtonVariant.secondary) {
          return BorderSide.none;
        }
        final isActive = states.contains(WidgetState.hovered);
        return BorderSide(color: isActive ? AppColors.primary : AppColors.line);
      }),
    );
  }
}
