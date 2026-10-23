import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';
import 'package:nest/ui/features/goals/views/goals_breakdown_view.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  group('GoalsBreakdownView', () {
    testWidgets('shows a ring with the percentage for a goal with a target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GoalsBreakdownView(
            year: 2026,
            goals: [GoalSummary(name: 'Carro', reserved: 500, target: 1000)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppProgressRing), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Carro'), findsOneWidget);
      expect(find.text('Completo'), findsNothing);
      expect(find.byType(AppChip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows complete and unbudgeted states', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GoalsBreakdownView(
            year: 2026,
            goals: [
              GoalSummary(name: 'Viagem', reserved: 800, target: 800),
              GoalSummary(name: 'Extra', reserved: 0, target: 0),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppProgressRing), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Completo'), findsOneWidget);
      expect(find.byType(AppSavedTick), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.text('Sem orçamento'), findsOneWidget);
      expect(find.byType(AppChip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows template timeline and priority chips', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GoalsBreakdownView(
            year: 2026,
            goals: [
              GoalSummary(
                name: 'Carro',
                reserved: 0,
                target: 1000,
                timeline: GoalTimeline.t1,
                priority: GoalPriority.grande,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppChip, 'T1'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'Grande'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
