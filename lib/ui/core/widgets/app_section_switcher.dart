import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// One option in an [AppSectionSwitcher].
class AppSectionOption<T> {
  const AppSectionOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented selector for the sections of a screen.
///
/// Used by the Mês and Agenda screens, which host two sections under one
/// primary destination. [compact] drops the icons and the expanded insets so
/// it fits an AppBar title; the regular mode centres the control and stretches
/// it on narrow viewports.
class AppSectionSwitcher<T> extends StatelessWidget {
  const AppSectionSwitcher({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  /// The sections, in display order.
  final List<AppSectionOption<T>> options;

  /// The value of the section currently shown.
  final T selected;

  /// Called with the value of the segment the user picks.
  final ValueChanged<T> onChanged;

  /// Drops the icons and the expanded insets for an AppBar title.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Icons make the segments too tight on phones and the widest label
        // wraps mid-word; drop them when narrow or compact.
        final showIcons = !compact && constraints.maxWidth >= AppBreakpoints.sm;
        final segments = <ButtonSegment<T>>[];
        for (final option in options) {
          final icon = option.icon;
          segments.add(
            ButtonSegment<T>(
              value: option.value,
              label: Text(option.label, maxLines: 1, softWrap: false),
              icon: showIcons && icon != null ? Icon(icon) : null,
            ),
          );
        }
        return Align(
          alignment: compact ? Alignment.centerLeft : Alignment.center,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            expandedInsets: compact || showIcons
                ? null
                : const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            style: ButtonStyle(
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(
                  horizontal: showIcons ? AppSpacing.lg : AppSpacing.md,
                ),
              ),
            ),
            segments: segments,
            selected: {selected},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        );
      },
    );
  }
}
