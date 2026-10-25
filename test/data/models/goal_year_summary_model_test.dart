import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_year_summary_model.dart';

void main() {
  group('GoalYearSummaryModel', () {
    test('maps matrix rows and their completion projection', () {
      final summary = GoalYearSummaryModel.fromJson(const {
        'year': 2026,
        'matrix': {
          'rows': [
            {
              'goalId': 'g1',
              'goalName': 'Viagem',
              'projection': {
                'asOfMonth': '2026-06',
                'pacePerMonth': 100,
                'remainingMonths': 6,
                'projectedAmount': 1200,
                'projectedMonth': '2026-12',
                'reachesBudget': true,
                'completionMonth': '2026-10',
              },
            },
            {'goalId': 'g2', 'goalName': 'Carro', 'projection': null},
          ],
        },
      }).toDomain();

      expect(summary.year, 2026);
      expect(summary.rows, hasLength(2));

      final viagem = summary.rows.first;
      expect(viagem.goalId, 'g1');
      expect(viagem.projection?.asOfMonth, '2026-06');
      expect(viagem.projection?.pacePerMonth, 100);
      expect(viagem.projection?.remainingMonths, 6);
      expect(viagem.projection?.projectedAmount, 1200);
      expect(viagem.projection?.projectedMonth, '2026-12');
      expect(viagem.projection?.reachesBudget, isTrue);
      expect(viagem.projection?.completionMonth, '2026-10');

      expect(summary.rows.last.goalId, 'g2');
      expect(summary.rows.last.projection, isNull);
    });

    test('tolerates a missing matrix and missing projections', () {
      final summary = GoalYearSummaryModel.fromJson(const {
        'year': 2026,
      }).toDomain();

      expect(summary.year, 2026);
      expect(summary.rows, isEmpty);

      final noProjection = GoalYearSummaryModel.fromJson(const {
        'year': 2026,
        'matrix': {
          'rows': [
            {'goalId': 'g1'},
          ],
        },
      }).toDomain();

      expect(noProjection.rows.single.goalId, 'g1');
      expect(noProjection.rows.single.projection, isNull);
    });
  });
}
