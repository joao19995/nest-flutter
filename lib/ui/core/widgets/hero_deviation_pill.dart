import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/hero_delta_pill.dart';

/// A translucent pill summarising how far the actual deviates from the plan.
///
/// Shared by the yearly expenses hero and the month summary hero. [zeroLabel]
/// is shown when there is no deviation; [alignment] optionally wraps the pill.
class HeroDeviationPill extends StatelessWidget {
  const HeroDeviationPill({
    super.key,
    required this.diff,
    required this.diffPct,
    required this.over,
    this.zeroLabel = 'No planeado',
    this.alignment,
  });

  /// `actual - planned`, in euros.
  final double diff;

  /// The deviation, as a percentage (sign is ignored in the label).
  final double diffPct;

  /// True when the actual exceeds the plan.
  final bool over;

  /// The label used when there is effectively no deviation.
  final String zeroLabel;

  /// When set, the pill is wrapped in an [Align] with this alignment.
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    final Widget pill;
    if (diff.abs() < 0.005) {
      pill = HeroDeltaPill(label: zeroLabel, color: AppColors.onHeroMuted);
    } else {
      final sign = diff > 0 ? '+' : '';
      final direction = over ? 'acima' : 'abaixo';
      pill = HeroDeltaPill(
        label:
            'Desvio $sign${AppFormatters.currency(diff)}  ·  '
            '${AppFormatters.percentage(diffPct.abs().round())} $direction',
        color: over ? AppColors.overOnDark : AppColors.mint,
      );
    }
    final align = alignment;
    return align == null ? pill : Align(alignment: align, child: pill);
  }
}
