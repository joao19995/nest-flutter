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
        'byCategory': [
          {
            'name': 'Casa',
            'planned': 900,
            'actual': 1200.25,
            'overPlanMonths': {'count': 3, 'suggestAdjustment': true},
          },
          {'name': 'Transporte', 'actual': 200},
        ],
        'months': [
          {
            'month': '2026-01',
            'status': 'closed',
            'planned': 1000,
            'actual': 1200.25,
            'progressPct': 100,
            'over': true,
            'filledEntries': 8,
            'totalEntries': 8,
          },
          {
            'month': '2026-02',
            'status': 'open',
            'planned': 1000.5,
            'actual': 1000.5,
            'progressPct': 50,
            'over': false,
            'filledEntries': 3,
            'totalEntries': 8,
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
      expect(summary.byCategory, hasLength(2));

      final casa = summary.byCategory.first;
      expect(casa.categoryName, 'Casa');
      expect(casa.planned, 900);
      expect(casa.actual, 1200.25);
      expect(casa.overPlanMonths?.count, 3);
      expect(casa.overPlanMonths?.suggestAdjustment, isTrue);

      final transporte = summary.byCategory.last;
      expect(transporte.categoryName, 'Transporte');
      expect(transporte.planned, 0);
      expect(transporte.actual, 200);
      expect(transporte.overPlanMonths, isNull);

      expect(summary.months, hasLength(3));

      final january = summary.months.first;
      expect(january.month, '2026-01');
      expect(january.status, ExpenseMonthStatus.closed);
      expect(january.actual, 1200.25);
      expect(january.over, isTrue);
      expect(january.filledEntries, 8);
      expect(january.totalEntries, 8);

      expect(summary.months[1].status, ExpenseMonthStatus.open);
      expect(summary.months[1].filledEntries, 3);
      expect(summary.months[1].totalEntries, 8);
      expect(summary.months[2].status, ExpenseMonthStatus.missing);
    });

    test('tolerates a missing months and byCategory list', () {
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
      expect(summary.byCategory, isEmpty);
    });
  });
}
