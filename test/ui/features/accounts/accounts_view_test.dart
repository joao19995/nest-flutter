import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/features/accounts/views/accounts_view.dart';

import '../../../support/test_helpers.dart';

void main() {
  testWidgets('shows the empty accounts state', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const AccountsView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contas'), findsOneWidget);
    expect(find.text('Ainda não há contas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
