import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// One column of an [AppBarChart]: a label, a raw value, and its state.
///
/// [over] paints the bar coral; [highlighted] paints it at full strength.
/// [planned] adds a thin marker at the planned amount.
typedef AppBarDatum = ({
  String label,
  double value,
  double? planned,
  bool over,
  bool highlighted,
});

/// A compact, dependency-free bar chart: one bar per datum, each scaled to the
/// tallest actual or planned value in the set. Bars grow in on first paint.
///
/// Tapping a bar shows its value above the chart; tapping outside or another
/// bar moves or dismisses the label.
class AppBarChart extends StatefulWidget {
  const AppBarChart({super.key, required this.bars});

  final List<AppBarDatum> bars;

  @override
  State<AppBarChart> createState() => _AppBarChartState();
}

class _AppBarChartState extends State<AppBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant AppBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars != widget.bars) {
      _selected = null;
    }
  }

  AppBarDatum? get _selectedBar {
    final index = _selected;
    if (index == null || index < 0 || index >= widget.bars.length) {
      return null;
    }
    return widget.bars[index];
  }

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    final maxValue = bars.fold<double>(0, (current, bar) {
      final planned = bar.planned ?? 0;
      final tallest = bar.value > planned ? bar.value : planned;
      return tallest > current ? tallest : current;
    });
    final selected = _selectedBar;
    return TapRegion(
      onTapOutside: (_) {
        if (_selected != null) {
          setState(() => _selected = null);
        }
      },
      child: Semantics(
        label: 'Gráfico de barras',
        value: [
          for (final bar in bars) '${bar.label}: ${bar.value}',
        ].join(', '),
        child: ExcludeSemantics(
          child: Column(
            children: [
              SizedBox(
                height: AppSizes.barChartTooltipHeight,
                child: selected == null
                    ? null
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          AppFormatters.currency(selected.value),
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.onHero,
                          ),
                        ),
                      ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < bars.length; index++)
                    Expanded(
                      child: _BarCell(
                        datum: bars[index],
                        fraction: maxValue > 0
                            ? bars[index].value / maxValue
                            : 0,
                        plannedFraction: _plannedFraction(
                          bars[index],
                          maxValue,
                        ),
                        onTap: () => _select(index),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _plannedFraction(AppBarDatum bar, double maxValue) {
    final planned = bar.planned;
    if (planned == null || planned <= 0 || maxValue <= 0) {
      return null;
    }
    return planned / maxValue;
  }
}

class _BarCell extends StatelessWidget {
  const _BarCell({
    required this.datum,
    required this.fraction,
    required this.plannedFraction,
    required this.onTap,
  });

  final AppBarDatum datum;
  final double fraction;
  final double? plannedFraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = datum.over
        ? AppColors.overOnDark
        : datum.highlighted
        ? AppColors.onHero
        : AppColors.onHeroMuted;
    final plannedFraction = this.plannedFraction;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
        child: Column(
          children: [
            SizedBox(
              height: AppSizes.barChartHeight,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: fraction.clamp(0.0, 1.0),
                      ),
                      duration: AppMotion.large,
                      curve: AppMotion.easing,
                      builder: (context, value, _) => Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
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
                    if (plannedFraction != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: constraints.maxHeight * plannedFraction,
                        child: Container(
                          key: ValueKey('bar-chart-planned-${datum.label}'),
                          height: AppSizes.barChartPlannedLine,
                          color: AppColors.onHeroMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              datum.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.badge.copyWith(
                color: datum.highlighted
                    ? AppColors.onHero
                    : AppColors.onHeroMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
