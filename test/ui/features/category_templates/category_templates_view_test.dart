import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/features/category_templates/views/category_templates_view.dart';

import '../../../support/test_helpers.dart';

void main() {
  testWidgets('shows the empty distributions state', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(
        testDependencies(client),
        const CategoryTemplatesView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Distribuição'), findsOneWidget);
    expect(find.text('Ainda não há distribuição.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
