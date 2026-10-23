import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A circular, tinted icon chip used in list rows.
///
/// Shared by expense categories and goals so both read identically: same
/// diameter, same tint opacity and same palette source.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = AppSizes.categoryIcon,
    this.iconSize = AppSizes.iconLarge,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.tint),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
