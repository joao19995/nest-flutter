import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/person_income.dart';

void main() {
  const older = PersonIncome(
    id: 'a',
    personId: 'p1',
    amount: 1000,
    validFrom: '2024-01-01',
  );
  const newer = PersonIncome(
    id: 'b',
    personId: 'p1',
    amount: 1200,
    validFrom: '2025-06-01',
  );
  const other = PersonIncome(
    id: 'c',
    personId: 'p2',
    amount: 900,
    validFrom: '2025-07-01',
  );

  group('PersonIncome.applicableFor', () {
    test('picks the latest record at or before the month', () {
      expect(
        PersonIncome.applicableFor([older, newer], 'p1', '2025-06'),
        newer,
      );
      expect(
        PersonIncome.applicableFor([older, newer], 'p1', '2025-08'),
        newer,
      );
      expect(
        PersonIncome.applicableFor([older, newer], 'p1', '2025-05'),
        older,
      );
    });

    test('returns null before the first record', () {
      expect(PersonIncome.applicableFor([older, newer], 'p1', '2023-12'), null);
    });

    test('ignores other people', () {
      expect(
        PersonIncome.applicableFor([older, newer, other], 'p1', '2025-08'),
        newer,
      );
    });

    test('breaks ties on the record later in the list', () {
      const first = PersonIncome(
        id: 'x',
        personId: 'p1',
        amount: 100,
        validFrom: '2025-01-01',
      );
      const second = PersonIncome(
        id: 'y',
        personId: 'p1',
        amount: 200,
        validFrom: '2025-01-01',
      );
      expect(
        PersonIncome.applicableFor([first, second], 'p1', '2025-03'),
        second,
      );
    });
  });
}
