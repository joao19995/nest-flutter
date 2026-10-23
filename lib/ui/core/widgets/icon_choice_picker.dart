import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// One selectable icon in an [IconChoicePicker].
class IconOption {
  const IconOption(this.key, this.label, this.icon);

  /// The semantic key shared with the API (e.g. `plane`, `cart`).
  final String key;

  /// Human label, used for accessibility and tooltips.
  final String label;

  /// The Material icon rendered for this key.
  final IconData icon;
}

/// A wrap of tappable icons; the selected one is highlighted.
class IconChoicePicker extends StatelessWidget {
  const IconChoicePicker({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onChanged,
  });

  final List<IconOption> options;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          _IconChoice(
            option: option,
            isSelected: option.key == selectedKey,
            colors: colors,
            onTap: () => onChanged(option.key),
          ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.option,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final IconOption option;
  final bool isSelected;
  final NestColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: Tooltip(
        message: option.label,
        child: Material(
          color: isSelected ? colors.mint : colors.lineSoft,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: AppSizes.goalIconPicker,
              height: AppSizes.goalIconPicker,
              child: Icon(
                option.icon,
                size: AppSizes.iconLarge,
                color: isSelected ? colors.primaryDark : colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
