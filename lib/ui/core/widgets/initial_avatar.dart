import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A circular avatar holding the first letter of [name].
///
/// Falls back to `?` for a blank name. Shared by the people, expense and goal
/// screens so every person reads the same.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Container(
      width: AppSizes.buttonHeight,
      height: AppSizes.buttonHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.terraSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.label(
          context.colors,
        ).copyWith(color: context.colors.terraDark),
      ),
    );
  }
}
