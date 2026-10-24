import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/money_field.dart';

void main() {
  testWidgets(
    'the keyboard advances to the next field and closes on the last',
    (tester) async {
      final saved = <double>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(0),
                    child: MoneyField(
                      value: 0,
                      originalValue: 0,
                      onSave: saved.add,
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: MoneyField(
                      value: 0,
                      originalValue: 0,
                      onSave: saved.add,
                      isLast: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList(growable: false);
      expect(fields.first.textInputAction, TextInputAction.next);
      expect(fields.last.textInputAction, TextInputAction.done);

      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(fields.first.focusNode?.hasFocus, isFalse);
      expect(fields.last.focusNode?.hasFocus, isTrue);
      expect(saved, [10]);
    },
  );
}
