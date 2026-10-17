import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_template_model.dart';
import 'package:nest/domain/models/goal_template.dart';

void main() {
  group('GoalTemplateModel', () {
    test('maps a JSON payload to a domain GoalTemplate', () {
      final GoalTemplate template = GoalTemplateModel.fromJson(const {
        'id': 't1',
        'validFrom': '2026-01',
        'annualTotal': 34565.6,
        'entries': [
          {'goalId': 'g1', 'percentage': 13, 'budget': 4000},
          {'goalId': 'g2', 'percentage': 87, 'budget': 30565.6},
        ],
      }).toDomain();

      expect(template.validFrom, '2026-01');
      expect(template.annualTotal, 34565.6);
      expect(template.entries, hasLength(2));
      expect(template.entries.first.goalId, 'g1');
      expect(template.entries.first.budget, 4000);
      expect(template.entries.first.percentage, 13);
    });
  });
}
