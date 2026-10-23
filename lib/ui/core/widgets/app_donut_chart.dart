import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// One slice of an [AppDonutChart]: a label, a raw value and its colour.
typedef AppDonutDatum = ({String label, double value, Color color});

/// A dependency-free donut chart with an optional centred total and legend.
///
/// Slices are proportional to their value and grow in on first paint. Empty,
/// zero or negative values are ignored; with no positive value only the track
/// is drawn.
class AppDonutChart extends StatelessWidget {
  const AppDonutChart({
    super.key,
    required this.data,
    this.centerValue,
    this.centerLabel,
    this.showLegend = true,
  });

  final List<AppDonutDatum> data;

  /// The headline figure in the middle of the ring.
  final String? centerValue;

  /// The caption below [centerValue].
  final String? centerLabel;

  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = data.fold<double>(
      0,
      (sum, datum) => datum.value > 0 ? sum + datum.value : sum,
    );
    final centerValue = this.centerValue;
    final centerLabel = this.centerLabel;
    final hasCenter = centerValue != null || centerLabel != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppSizes.donutChart,
          height: AppSizes.donutChart,
          child: Semantics(
            label: 'Gráfico circular',
            value: [
              for (final datum in data)
                '${datum.label}: ${datum.value.toStringAsFixed(2)}',
            ].join(', '),
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: AppMotion.large,
                curve: AppMotion.easing,
                builder: (context, progress, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(AppSizes.donutChart),
                      painter: _DonutPainter(
                        data: data,
                        total: total,
                        progress: progress,
                        trackColor: colors.lineSoft,
                      ),
                    ),
                    if (hasCenter)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (centerValue != null)
                            Text(
                              centerValue,
                              maxLines: 1,
                              style: AppTextStyles.sectionHeading.copyWith(
                                color: colors.ink,
                              ),
                            ),
                          if (centerLabel != null)
                            Text(
                              centerLabel,
                              maxLines: 1,
                              style: AppTextStyles.small(colors),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showLegend && data.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final datum in data)
                if (datum.value > 0) _LegendRow(datum: datum, total: total),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.datum, required this.total});

  final AppDonutDatum datum;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fraction = total > 0 ? datum.value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSizes.donutLegendDot,
            height: AppSizes.donutLegendDot,
            decoration: BoxDecoration(
              color: datum.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              datum.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(colors),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.percentage(fraction * 100),
            style: AppTextStyles.label(colors),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.data,
    required this.total,
    required this.progress,
    required this.trackColor,
  });

  final List<AppDonutDatum> data;
  final double total;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.donutStroke;
    final rect =
        const Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    if (total <= 0 || progress <= 0) {
      return;
    }
    final visible = data.where((datum) => datum.value > 0).toList();
    final gap = visible.length > 1 ? AppSizes.donutSliceGap : 0.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    var start = -math.pi / 2;
    for (final datum in visible) {
      final sweep = 2 * math.pi * (datum.value / total);
      final drawn = math.max(0.0, sweep * progress - gap);
      if (drawn > 0) {
        canvas.drawArc(rect, start, drawn, false, paint..color = datum.color);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.total != total ||
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor;
}
