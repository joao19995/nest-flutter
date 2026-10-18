import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/bottom_sheet_body.dart';

void main() {
  testWidgets('clears both the keyboard and the system navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: 48),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: BottomSheetBody(child: Text('conteúdo')),
        ),
      ),
    );

    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final padding = scroll.padding! as EdgeInsets;

    expect(padding.bottom, 300 + 48 + AppSpacing.xl);
  });
}
