import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// One column of an [AppBarChart]: a label, a raw value, and its state.
///
/// [over] paints the bar coral; [highlighted] paints it at full strength.
typedef AppBarDatum = ({
  String label,
  double value,
  bool over,
  bool highlighted,
});

/// A compact, dependency-free bar chart: one bar per datum, each scaled to the
/// tallest value in the set. Bars grow in on first paint.
class AppBarChart extends StatelessWidget {
  const AppBarChart({super.key, required this.bars});

  final List<AppBarDatum> bars;

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(
      0,
      (current, bar) => bar.value > current ? bar.value : current,
    );
    return Column(
      children: [
        SizedBox(
          height: AppSizes.barChartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bar in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs / 2,
                    ),
                    child: _Bar(
                      datum: bar,
                      fraction: maxValue > 0 ? bar.value / maxValue : 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final bar in bars)
              Expanded(
                child: Text(
                  bar.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.badge.copyWith(
                    color: bar.highlighted
                        ? AppColors.onHero
                        : AppColors.onHeroMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.datum, required this.fraction});

  final AppBarDatum datum;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final color = datum.over
        ? AppColors.overOnDark
        : datum.highlighted
        ? AppColors.onHero
        : AppColors.onHeroMuted;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0)),
          duration: AppMotion.large,
          curve: AppMotion.easing,
          builder: (context, value, _) => Container(
            height: constraints.maxHeight * value,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
