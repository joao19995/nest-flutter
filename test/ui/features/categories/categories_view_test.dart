import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/features/categories/views/categories_view.dart';

import '../../../support/test_helpers.dart';

void main() {
  testWidgets('shows the empty categories state', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      return jsonResponse(const <Object>[]);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const CategoriesView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('Ainda não há categorias.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
