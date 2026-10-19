import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/widgets/period_swipe_detector.dart';

void main() {
  testWidgets('maps horizontal swipes to the previous and next period', (
    tester,
  ) async {
    var previous = 0;
    var next = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodSwipeDetector(
            onPrevious: () => previous++,
            onNext: () => next++,
            child: const Center(child: Text('conteúdo')),
          ),
        ),
      ),
    );

    await tester.fling(find.text('conteúdo'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(previous, 1);
    expect(next, 0);

    await tester.fling(find.text('conteúdo'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(previous, 1);
    expect(next, 1);
  });

  testWidgets('ignores vertical swipes', (tester) async {
    var previous = 0;
    var next = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodSwipeDetector(
            onPrevious: () => previous++,
            onNext: () => next++,
            child: const Center(child: Text('conteúdo')),
          ),
        ),
      ),
    );

    await tester.fling(find.text('conteúdo'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(previous, 0);
    expect(next, 0);
  });
}
