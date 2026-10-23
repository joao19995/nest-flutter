import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_card.dart';

/// The state of a month in a year overview.
enum AppMonthStatus { missing, open, closed }

/// A mini month card: the short month name, the amount, a state dot and a
/// tiny progress bar.
class AppMonthTile extends StatelessWidget {
  const AppMonthTile({
    super.key,
    required this.month,
    required this.status,
    this.amount,
    this.over = false,
    this.progress = 0,
    this.caption,
    this.onTap,
  });

  /// The API month key, formatted `YYYY-MM`.
  final String month;

  final AppMonthStatus status;

  /// The spent/reserved amount; when omitted the card reads as unplanned.
  final double? amount;

  /// Paints the amount and the progress bar coral.
  final bool over;

  /// Progress of the mini bar, as a 0..1 fraction.
  final double progress;

  /// Optional line below the amount, e.g. the funded goal count.
  final String? caption;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = this.amount;
    final caption = this.caption;
    final value = amount == null ? '—' : AppFormatters.currency(amount);
    final valueStyle = amount == null
        ? AppTextStyles.small(colors)
        : AppTextStyles.label(
            colors,
          ).copyWith(color: over ? colors.over : colors.ink);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppFormatters.monthShort(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: colors.ink,
                  ),
                ),
              ),
              Semantics(
                label: _statusLabel(status),
                child: Container(
                  width: AppSizes.badgeDot,
                  height: AppSizes.badgeDot,
                  decoration: BoxDecoration(
                    color: _statusColor(colors),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(colors),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: AppSizes.monthTileProgressHeight,
            backgroundColor: colors.lineSoft,
            color: over ? colors.over : colors.primary,
            borderRadius: AppRadius.fullAll,
          ),
        ],
      ),
    );
  }

  Color _statusColor(NestColors colors) => switch (status) {
    AppMonthStatus.missing => colors.faint,
    AppMonthStatus.open => colors.primary,
    AppMonthStatus.closed => colors.muted,
  };

  String _statusLabel(AppMonthStatus status) => switch (status) {
    AppMonthStatus.missing => 'Sem plano',
    AppMonthStatus.open => 'Aberto',
    AppMonthStatus.closed => 'Fechado',
  };
}
