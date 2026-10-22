import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/features/goals/views/goals_catalog_view.dart';

import '../../../support/test_helpers.dart';

void main() {
  testWidgets('shows the empty catalogue state', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const GoalsCatalogView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catálogo de objetivos'), findsOneWidget);
    expect(find.text('Ainda não há objetivos.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
