import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/animated_amount.dart';
import 'package:nest/ui/core/widgets/app_badge.dart';
import 'package:nest/ui/core/widgets/app_period_stepper.dart';
import 'package:nest/ui/core/widgets/app_progress_ring.dart';
import 'package:nest/ui/core/widgets/hero_delta_pill.dart';
import 'package:nest/ui/core/widgets/hero_panel.dart';

/// The month summary panel used by the monthly detail screens: real vs planned
/// totals, an over/under deviation and the month selector.
class MonthSummaryHero extends StatelessWidget {
  const MonthSummaryHero({
    super.key,
    required this.title,
    required this.month,
    required this.actual,
    required this.planned,
    required this.closed,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.hasPlan = true,
  });

  /// The eyebrow, e.g. `DESPESA DO MÊS`.
  final String title;

  /// The month, formatted `YYYY-MM`.
  final String month;

  /// The real total, in euros.
  final double actual;

  /// The planned total, in euros.
  final double planned;

  /// Whether the month is closed.
  final bool closed;

  /// False when the month has no saved plan yet.
  final bool hasPlan;

  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final ratio = planned > 0 ? actual / planned : (actual > 0 ? 1.0 : 0.0);
    final over = actual - planned > 0.005;
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.navSection(
                    context.colors,
                  ).copyWith(color: AppColors.onHeroMuted),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppPeriodStepper(
                label: AppFormatters.monthName(month),
                onPrevious: onPreviousMonth,
                onNext: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedAmount(
                      value: actual,
                      style: AppTextStyles.statDisplay.copyWith(
                        color: AppColors.onHero,
                      ),
                    ),
                    if (hasPlan) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Planeado ${AppFormatters.currency(planned)}',
                        style: AppTextStyles.small(
                          context.colors,
                        ).copyWith(color: AppColors.onHeroMuted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DeviationPill(actual: actual, planned: planned),
                    ],
                  ],
                ),
              ),
              if (hasPlan) ...[
                const SizedBox(width: AppSpacing.md),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppProgressRing(
                      progress: ratio,
                      label: AppFormatters.percentage((ratio * 100).round()),
                      color: over ? AppColors.overOnDark : AppColors.mint,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppBadge(
                      label: closed ? 'Fechado' : 'Aberto',
                      style: closed
                          ? AppBadgeStyles.closedOnHero
                          : AppBadgeStyles.openOnHero,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A translucent pill: how far the real total deviates from the plan.
class _DeviationPill extends StatelessWidget {
  const _DeviationPill({required this.actual, required this.planned});

  final double actual;
  final double planned;

  @override
  Widget build(BuildContext context) {
    final diff = actual - planned;
    final over = diff > 0.005;
    final under = diff < -0.005;
    if (!over && !under) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: HeroDeltaPill(
          label: 'No planeado',
          color: AppColors.onHeroMuted,
        ),
      );
    }
    final pct = planned > 0 ? (diff / planned * 100) : 0.0;
    final sign = diff > 0 ? '+' : '';
    final direction = over ? 'acima' : 'abaixo';
    return Align(
      alignment: Alignment.centerLeft,
      child: HeroDeltaPill(
        label:
            'Desvio $sign${AppFormatters.currency(diff)}  ·  '
            '${AppFormatters.percentage(pct.abs().round())} $direction',
        color: over ? AppColors.overOnDark : AppColors.mint,
      ),
    );
  }
}
