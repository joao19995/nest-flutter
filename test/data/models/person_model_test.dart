import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/person_model.dart';
import 'package:nest/domain/models/person.dart';

void main() {
  group('PersonModel', () {
    test('maps a JSON payload to a domain Person', () {
      final model = PersonModel.fromJson(const {
        'id': 'p1',
        'name': 'Ana',
        'dailySpendingPercentage': 25,
      });

      final Person person = model.toDomain();

      expect(person.id, 'p1');
      expect(person.name, 'Ana');
      expect(person.dailySpendingPercentage, 25);
      expect(person.applicableIncome, isNull);
    });

    test('maps applicableIncome when the month is requested', () {
      final person = PersonModel.fromJson(const {
        'id': 'p1',
        'name': 'Ana',
        'dailySpendingPercentage': 25,
        'applicableIncome': 2500,
      }).toDomain();

      expect(person.applicableIncome, 2500);
    });
  });
}
