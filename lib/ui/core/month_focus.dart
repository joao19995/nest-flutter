import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/month_key.dart';

/// Which month the closing ritual puts in front.
///
/// On the first days of a month the balance that is due is the previous
/// month's; after that (or once it is closed) the current month is the focus.
abstract final class MonthFocus {
  /// The last day of the month that still belongs to the previous balance.
  static const int balanceWindowLastDay = 3;

  /// True while [now] is inside the previous-balance window.
  static bool isBalanceWindow(DateTime now) => now.day <= balanceWindowLastDay;

  /// The previous month of [now], formatted `YYYY-MM`.
  static String previousMonth(DateTime now) =>
      MonthKey.shift(MonthKey.of(now.year, now.month), -1);

  /// The month to put in front: the previous one while [now] is in the window
  /// and [previousStatus] is open or missing; otherwise the current month.
  /// An unknown status (null) falls back to the current month.
  static String resolve({
    required DateTime now,
    required ExpenseMonthStatus? previousStatus,
  }) {
    final current = MonthKey.of(now.year, now.month);
    if (!isBalanceWindow(now)) {
      return current;
    }
    if (previousStatus == null || previousStatus == ExpenseMonthStatus.closed) {
      return current;
    }
    return previousMonth(now);
  }
}
