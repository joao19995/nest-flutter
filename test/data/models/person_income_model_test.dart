import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/person_income_model.dart';
import 'package:nest/domain/models/person_income.dart';

void main() {
  group('PersonIncomeModel', () {
    test('maps a JSON payload to a domain PersonIncome', () {
      final model = PersonIncomeModel.fromJson(const {
        'id': 'i1',
        'personId': 'p1',
        'amount': 1500,
        'validFrom': '2025-01-01',
      });

      final PersonIncome income = model.toDomain();

      expect(income.id, 'i1');
      expect(income.personId, 'p1');
      expect(income.amount, 1500);
      expect(income.validFrom, '2025-01-01');
      expect(income.validFromMonth, '2025-01');
    });
  });
}
