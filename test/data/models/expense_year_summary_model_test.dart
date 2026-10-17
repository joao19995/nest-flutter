import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/expense_year_summary_model.dart';
import 'package:nest/domain/models/expense_year_summary.dart';

void main() {
  group('ExpenseYearSummaryModel', () {
    test('maps a JSON payload to a domain ExpenseYearSummary', () {
      final model = ExpenseYearSummaryModel.fromJson(const {
        'year': 2026,
        'monthsWithPlan': 2,
        'planned': 2000.5,
        'actual': 2200.75,
        'diff': 200.25,
        'diffPct': 10.01,
        'actualPct': 110.01,
        'over': true,
        'under': false,
        'hasData': true,
        'remainingMonths': 3,
        'perRemainingMonth': 66.75,
        'byCategory': <Object>[],
        'months': [
          {
            'month': '2026-01',
            'status': 'closed',
            'planned': 1000,
            'actual': 1200.25,
            'progressPct': 100,
            'over': true,
          },
          {
            'month': '2026-02',
            'status': 'open',
            'planned': 1000.5,
            'actual': 1000.5,
            'progressPct': 50,
            'over': false,
          },
          {
            'month': '2026-03',
            'status': 'missing',
            'planned': 0,
            'actual': 0,
            'progressPct': 0,
            'over': false,
          },
        ],
      });

      final ExpenseYearSummary summary = model.toDomain();

      expect(summary.year, 2026);
      expect(summary.planned, 2000.5);
      expect(summary.actual, 2200.75);
      expect(summary.diff, 200.25);
      expect(summary.diffPct, 10.01);
      expect(summary.over, isTrue);
      expect(summary.remainingMonths, 3);
      expect(summary.perRemainingMonth, 66.75);
      expect(summary.hasData, isTrue);
      expect(summary.months, hasLength(3));

      final january = summary.months.first;
      expect(january.month, '2026-01');
      expect(january.status, ExpenseMonthStatus.closed);
      expect(january.actual, 1200.25);
      expect(january.over, isTrue);

      expect(summary.months[1].status, ExpenseMonthStatus.open);
      expect(summary.months[2].status, ExpenseMonthStatus.missing);
    });

    test('tolerates a missing months list', () {
      final summary = ExpenseYearSummaryModel.fromJson(const {
        'year': 2026,
        'planned': 0,
        'actual': 0,
        'diff': 0,
        'diffPct': 0,
        'over': false,
        'remainingMonths': 0,
        'perRemainingMonth': 0,
        'hasData': false,
      }).toDomain();

      expect(summary.hasData, isFalse);
      expect(summary.months, isEmpty);
    });
  });
}
