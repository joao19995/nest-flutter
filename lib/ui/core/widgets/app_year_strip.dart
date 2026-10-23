import 'package:flutter/material.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A compact twelve-month strip: one dot per month, coloured by its state.
///
/// The current month is ringed, and every point carries a month-name tooltip
/// and opens its month on tap.
class AppYearStrip extends StatelessWidget {
  const AppYearStrip({
    super.key,
    required this.months,
    required this.onTap,
    this.currentMonth,
  });

  final List<ExpenseMonthSummary> months;

  /// Called with the tapped month's `YYYY-MM` key.
  final ValueChanged<String> onTap;

  /// The month to ring, or null to ring none.
  final String? currentMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final month in months)
          Expanded(
            child: Align(
              child: _YearMonthDot(
                month: month,
                isCurrent: month.month == currentMonth,
                onTap: () => onTap(month.month),
              ),
            ),
          ),
      ],
    );
  }
}

class _YearMonthDot extends StatelessWidget {
  const _YearMonthDot({
    required this.month,
    required this.isCurrent,
    required this.onTap,
  });

  final ExpenseMonthSummary month;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final closed = month.status == ExpenseMonthStatus.closed;
    final open = month.status == ExpenseMonthStatus.open;
    return Tooltip(
      message: AppFormatters.monthName(month.month),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Container(
            key: ValueKey('year-strip-ring-${month.month}'),
            width: AppSizes.yearStripRing,
            height: AppSizes.yearStripRing,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(
                      color: colors.primary,
                      width: AppSizes.yearStripRingWidth,
                    )
                  : null,
            ),
            child: Container(
              key: ValueKey('year-strip-${month.month}'),
              width: AppSizes.yearStripDot,
              height: AppSizes.yearStripDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: closed
                    ? colors.primary
                    : open
                    ? colors.mint
                    : colors.lineSoft,
                border: open
                    ? Border.all(
                        color: colors.primary,
                        width: AppSizes.yearStripRingWidth,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
