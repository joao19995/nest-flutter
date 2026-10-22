import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/month_pager.dart';

void main() {
  testWidgets('keeps swiping inside the configured month range', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MonthPager(
          title: 'Meses',
          month: '2026-01',
          firstMonth: '2026-01',
          lastMonth: '2026-02',
          pageBuilder: (context, month, onPrevious, onNext) => Text(month),
        ),
      ),
    );

    expect(find.text('2026-01'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('2026-01'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('2026-02'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('2026-02'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
