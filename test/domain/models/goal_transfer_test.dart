import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/goal_transfer.dart';

void main() {
  group('GoalTransfer.distribute', () {
    test('splits by earning share and fills goals in a waterfall', () {
      final transfers = GoalTransfer.distribute(
        reservedTotal: 1000,
        earnings: const [
          GoalEarning(personId: 'p1', name: 'João', earning: 2500),
          GoalEarning(personId: 'p2', name: 'Nathalia', earning: 1500),
        ],
        goals: const [
          GoalTransferPart(goalId: 'g1', name: 'Viagem', amount: 600),
          GoalTransferPart(goalId: 'g2', name: 'Carro', amount: 400),
        ],
      );

      expect(transfers, hasLength(2));
      final joao = transfers[0];
      final nathalia = transfers[1];

      expect(joao.amount, 625);
      expect(nathalia.amount, 375);
      expect(joao.amount + nathalia.amount, 1000);

      expect(joao.parts.map((p) => p.name), ['Viagem', 'Carro']);
      expect(joao.parts[0].amount, 600);
      expect(joao.parts[1].amount, 25);
      expect(nathalia.parts.single.name, 'Carro');
      expect(nathalia.parts.single.amount, 375);
    });

    test('returns nothing without a reserved amount or income', () {
      expect(
        GoalTransfer.distribute(
          reservedTotal: 0,
          earnings: const [
            GoalEarning(personId: 'p1', name: 'João', earning: 2500),
          ],
          goals: const [],
        ),
        isEmpty,
      );
      expect(
        GoalTransfer.distribute(
          reservedTotal: 500,
          earnings: const [],
          goals: const [],
        ),
        isEmpty,
      );
      expect(
        GoalTransfer.distribute(
          reservedTotal: 500,
          earnings: const [
            GoalEarning(personId: 'p1', name: 'João', earning: 0),
          ],
          goals: const [],
        ),
        isEmpty,
      );
    });
  });
}
