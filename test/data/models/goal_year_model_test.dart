import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_year_model.dart';
import 'package:nest/domain/models/goal_year.dart';

void main() {
  group('GoalYearModel', () {
    test('maps plans, allocations and funding to a domain GoalYear', () {
      final json = <String, dynamic>{
        'plans': [
          {
            'id': 'p1',
            'month': '2026-01',
            'availableAmount': 1725,
            'closed': true,
            'allocations': [
              {
                'goalId': 'g1',
                'goalName': 'Viagem',
                'planned': 800,
                'actual': 800,
              },
              {
                'goalId': 'g2',
                'goalName': 'Carro',
                'planned': 925,
                'actual': 925,
              },
            ],
          },
        ],
        'funding': {
          'year': 2026,
          'annualTotal': 34565.6,
          'months': [
            {
              'month': '2026-01',
              'incomeNormal': 4500,
              'bonus': 0,
              'dailyAllowance': 1125,
              'contributionRequired': 1335,
              'available': 2040,
            },
          ],
        },
      };

      final GoalYear year = GoalYearModel.fromJson(json).toDomain();

      expect(year.year, 2026);
      expect(year.annualTotal, 34565.6);
      expect(year.plans, hasLength(1));
      expect(year.months, hasLength(1));

      final january = year.plans.first;
      expect(january.month, '2026-01');
      expect(january.availableAmount, 1725);
      expect(january.closed, isTrue);
      expect(january.reserved, 1725);
      expect(january.fundedCount, 2);
      expect(january.allocations.first.goalName, 'Viagem');

      expect(year.months.first.available, 2040);
    });

    test('tolerates missing plans and funding', () {
      final year = GoalYearModel.fromJson(const <String, dynamic>{
        'plans': <Object>[],
      }).toDomain();

      expect(year.year, 0);
      expect(year.annualTotal, 0);
      expect(year.plans, isEmpty);
      expect(year.months, isEmpty);
    });
  });
}
