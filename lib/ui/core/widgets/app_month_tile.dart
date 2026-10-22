import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_card.dart';

/// The state of a month in a year overview.
enum AppMonthStatus { missing, open, closed }

/// A mini month card: the short month name, the amount, and a state dot.
class AppMonthTile extends StatelessWidget {
  const AppMonthTile({
    super.key,
    required this.month,
    required this.status,
    this.amount,
    this.over = false,
    this.onTap,
  });

  /// The API month key, formatted `YYYY-MM`.
  final String month;

  final AppMonthStatus status;

  /// The spent/reserved amount; when omitted the card reads as unplanned.
  final double? amount;

  /// Paints the amount coral.
  final bool over;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amount = this.amount;
    final value = amount == null
        ? _statusLabel(status)
        : AppFormatters.currency(amount);
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
