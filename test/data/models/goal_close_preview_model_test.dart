import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_close_preview_model.dart';

void main() {
  group('GoalClosePreviewModel', () {
    test('maps the projected totals, defaulted goals and quotas', () {
      final preview = GoalClosePreviewModel.fromJson(<String, dynamic>{
        'month': '2026-01',
        'availableAmount': 1000,
        'plannedTotal': 900,
        'reservedTotal': 950,
        'unallocated': 100,
        'adjustedFromTemplate': true,
        'affectedFutureMonths': ['2026-02', '2026-03'],
        'defaulted': [
          {'goalId': 'g2', 'goalName': 'Carro', 'amount': 400},
        ],
        'quotas': [
          {
            'personId': 'p1',
            'name': 'João',
            'earning': 2500,
            'share': 1,
            'amount': 950,
            'parts': [
              {'goalId': 'g1', 'name': 'Viagem', 'amount': 550},
              {'goalId': 'g2', 'name': 'Carro', 'amount': 400},
            ],
          },
        ],
      }).toDomain();

      expect(preview.availableAmount, 1000);
      expect(preview.plannedTotal, 900);
      expect(preview.reservedTotal, 950);
      expect(preview.unallocated, 100);
      expect(preview.adjustedFromTemplate, isTrue);
      expect(preview.affectedFutureMonths, ['2026-02', '2026-03']);
      expect(preview.defaulted.single.goalName, 'Carro');
      expect(preview.defaulted.single.amount, 400);
      expect(preview.quotas.single.name, 'João');
      expect(preview.quotas.single.amount, 950);
      expect(preview.quotas.single.parts, hasLength(2));
    });

    test('tolerates missing lists', () {
      final preview = GoalClosePreviewModel.fromJson(<String, dynamic>{
        'month': '2026-01',
      }).toDomain();

      expect(preview.defaulted, isEmpty);
      expect(preview.quotas, isEmpty);
      expect(preview.affectedFutureMonths, isEmpty);
      expect(preview.adjustedFromTemplate, isFalse);
    });
  });
}
