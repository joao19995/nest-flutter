import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/month_focus.dart';

void main() {
  group('MonthFocus.resolve', () {
    test('day 2 with the previous month open focuses the previous month', () {
      expect(
        MonthFocus.resolve(
          now: DateTime(2026, 10, 2, 12),
          previousStatus: ExpenseMonthStatus.open,
        ),
        '2026-09',
      );
    });

    test(
      'day 2 with the previous month missing focuses the previous month',
      () {
        expect(
          MonthFocus.resolve(
            now: DateTime(2026, 10, 2, 12),
            previousStatus: ExpenseMonthStatus.missing,
          ),
          '2026-09',
        );
      },
    );

    test('day 2 with the previous month closed stays on the current month', () {
      expect(
        MonthFocus.resolve(
          now: DateTime(2026, 10, 2, 12),
          previousStatus: ExpenseMonthStatus.closed,
        ),
        '2026-10',
      );
    });

    test(
      'day 2 with an unknown previous status stays on the current month',
      () {
        expect(
          MonthFocus.resolve(
            now: DateTime(2026, 10, 2, 12),
            previousStatus: null,
          ),
          '2026-10',
        );
      },
    );

    test('day 4 with the previous month open stays on the current month', () {
      expect(
        MonthFocus.resolve(
          now: DateTime(2026, 10, 4, 12),
          previousStatus: ExpenseMonthStatus.open,
        ),
        '2026-10',
      );
    });

    test('day 8 stays on the current month', () {
      expect(
        MonthFocus.resolve(
          now: DateTime(2026, 10, 8, 12),
          previousStatus: ExpenseMonthStatus.open,
        ),
        '2026-10',
      );
    });
  });

  test('January focuses December of the previous year', () {
    final now = DateTime(2026, 1, 2, 12);

    expect(MonthFocus.previousMonth(now), '2025-12');
    expect(
      MonthFocus.resolve(now: now, previousStatus: ExpenseMonthStatus.open),
      '2025-12',
    );
  });
}
