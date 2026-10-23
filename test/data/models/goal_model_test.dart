import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/goal_model.dart';
import 'package:nest/domain/models/goal.dart';

void main() {
  group('GoalModel', () {
    test('maps a JSON payload to a domain Goal', () {
      final Goal goal = GoalModel.fromJson(const {
        'id': 'g1',
        'name': 'Viagem à Madeira',
        'active': true,
        'iconKey': 'plane',
      }).toDomain();

      expect(goal.id, 'g1');
      expect(goal.name, 'Viagem à Madeira');
      expect(goal.active, isTrue);
      expect(goal.iconKey, 'plane');
    });

    test('leaves iconKey null when the API omits it', () {
      final Goal goal = GoalModel.fromJson(const {
        'id': 'g2',
        'name': 'Casa',
        'active': true,
      }).toDomain();

      expect(goal.iconKey, isNull);
    });
  });
}
