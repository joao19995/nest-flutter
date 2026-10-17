import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A translucent pill on the dark hero that carries a short status phrase.
///
/// [color] defaults to the brand mint highlight; pass `AppColors.overOnDark`
/// when the phrase describes an over-planned state, or
/// `AppColors.onHeroMuted` for neutral information.
class HeroDeltaPill extends StatelessWidget {
  const HeroDeltaPill({
    super.key,
    required this.label,
    this.color = AppColors.mint,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.heroPill,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        label,
        style: AppTextStyles.small(
          context.colors,
        ).copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
