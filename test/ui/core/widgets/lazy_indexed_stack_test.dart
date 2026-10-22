import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/widgets/lazy_indexed_stack.dart';

void main() {
  testWidgets('builds only the selected child and keeps it alive', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LazyIndexedStack(
          index: 0,
          children: [Text('primeiro'), Text('segundo')],
        ),
      ),
    );

    expect(find.text('primeiro'), findsOneWidget);
    expect(find.text('segundo'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: LazyIndexedStack(
          index: 1,
          children: [Text('primeiro'), Text('segundo')],
        ),
      ),
    );

    expect(find.text('primeiro'), findsNothing);
    expect(find.text('segundo'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: LazyIndexedStack(
          index: 0,
          children: [Text('primeiro'), Text('segundo')],
        ),
      ),
    );

    expect(find.text('primeiro'), findsOneWidget);
    expect(find.text('segundo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
