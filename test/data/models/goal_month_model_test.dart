import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_month_model.dart';
import 'package:nest/domain/models/goal_year.dart';

void main() {
  group('GoalMonthModel', () {
    test('maps a saved month to a domain GoalPlan', () {
      final plan = GoalMonthModel.fromJson(const <String, dynamic>{
        'month': '2026-01',
        'planId': 'p1',
        'closed': true,
        'availableAmount': 1000,
        'allocations': [
          {'goalId': 'g1', 'goalName': 'Viagem', 'planned': 600, 'actual': 600},
          {'goalId': 'g2', 'goalName': 'Carro', 'planned': 400, 'actual': 400},
        ],
      }).toDomain();

      expect(plan, isA<GoalPlan>());
      expect(plan!.id, 'p1');
      expect(plan.month, '2026-01');
      expect(plan.closed, isTrue);
      expect(plan.availableAmount, 1000);
      expect(plan.reserved, 1000);
      expect(plan.fundedCount, 2);
      expect(plan.allocations.first.goalName, 'Viagem');
    });

    test('returns null when the month has not been created', () {
      final plan = GoalMonthModel.fromJson(const <String, dynamic>{
        'month': '2026-02',
        'planId': null,
        'closed': false,
        'availableAmount': 0,
        'allocations': <Object>[],
      }).toDomain();

      expect(plan, isNull);
    });
  });
}
