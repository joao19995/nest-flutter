import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/hero_flight.dart';
import 'package:nest/ui/core/widgets/month_summary_hero.dart';

/// The shared shell of a monthly detail page: a hero summary with the month
/// selector followed by the feature-specific body.
class MonthDetailPage extends StatelessWidget {
  const MonthDetailPage({
    super.key,
    required this.heroTag,
    required this.title,
    required this.month,
    required this.actual,
    required this.planned,
    required this.closed,
    required this.hasPlan,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.child,
    this.over,
    this.progressPct,
  });

  final String heroTag;
  final String title;
  final String month;
  final double actual;
  final double planned;
  final bool closed;
  final bool hasPlan;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Widget child;
  final bool? over;
  final double? progressPct;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: heroTag,
            flightShuttleBuilder: heroSurfaceShuttle,
            child: MonthSummaryHero(
              title: title,
              month: month,
              actual: actual,
              planned: planned,
              closed: closed,
              hasPlan: hasPlan,
              over: over,
              progressPct: progressPct,
              onPreviousMonth: onPreviousMonth,
              onNextMonth: onNextMonth,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
