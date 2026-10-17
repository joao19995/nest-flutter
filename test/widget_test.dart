import 'package:flutter_test/flutter_test.dart';

import 'package:nest/app.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Nest'), findsOneWidget);
    expect(find.text('Welcome to Nest'), findsOneWidget);
  });
}
