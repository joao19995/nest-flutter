import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_month_model.dart';
import 'package:nest/domain/models/goal_month_view.dart';

Map<String, dynamic> _view({String? planId = 'p1', bool closed = true}) =>
    <String, dynamic>{
      'month': '2026-01',
      'planId': planId,
      'closed': closed,
      'availableAmount': 1000,
      'allocations': [
        {
          'goalId': 'g1',
          'goalName': 'Viagem',
          'planned': 600,
          'actual': 600,
          'budget': 800,
          'yearReserved': 1200,
        },
        {
          'goalId': 'g2',
          'goalName': 'Carro',
          'planned': 400,
          'actual': 400,
          'budget': null,
          'yearReserved': 0,
        },
      ],
      'quotas': [
        {
          'personId': 'p1',
          'name': 'João',
          'earning': 2500,
          'share': 0.625,
          'amount': 625,
          'parts': [
            {'goalId': 'g1', 'name': 'Viagem', 'amount': 600},
            {'goalId': 'g2', 'name': 'Carro', 'amount': 25},
          ],
        },
      ],
    };

void main() {
  group('GoalMonthModel', () {
    test('maps a saved month with allocations and quotas', () {
      final GoalMonthView view = GoalMonthModel.fromJson(_view()).toDomain();

      final plan = view.plan;
      expect(plan, isNotNull);
      expect(plan?.id, 'p1');
      expect(plan?.month, '2026-01');
      expect(plan?.closed, isTrue);
      expect(plan?.reserved, 1000);
      expect(plan?.fundedCount, 2);
      expect(plan?.allocations.first.goalName, 'Viagem');
      expect(view.availableAmount, 1000);

      expect(view.quotas, hasLength(1));
      final quota = view.quotas.single;
      expect(quota.name, 'João');
      expect(quota.earning, 2500);
      expect(quota.share, 0.625);
      expect(quota.amount, 625);
      expect(quota.parts, hasLength(2));
      expect(quota.parts.first.name, 'Viagem');
    });

    test('a null planId is an uncreated month', () {
      final view = GoalMonthModel.fromJson(_view(planId: null)).toDomain();

      expect(view.plan, isNull);
    });

    test('tolerates missing allocations and quotas', () {
      final view = GoalMonthModel.fromJson(const <String, dynamic>{
        'month': '2026-02',
        'planId': 'p2',
        'closed': false,
        'availableAmount': 0,
      }).toDomain();

      expect(view.plan?.allocations, isEmpty);
      expect(view.quotas, isEmpty);
    });
  });
}
