import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/async_view.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AsyncView', () {
    testWidgets('hides the child while loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView(
            isLoading: true,
            errorMessage: null,
            isEmpty: false,
            onRetry: () {},
            child: const Text('data'),
          ),
        ),
      );

      expect(find.text('data'), findsNothing);
    });

    testWidgets('shows the error message and retries', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          AsyncView(
            isLoading: false,
            errorMessage: 'Falhou',
            isEmpty: false,
            onRetry: () => retried = true,
            child: const Text('data'),
          ),
        ),
      );

      expect(find.text('Falhou'), findsOneWidget);

      await tester.tap(find.text('Tentar de novo'));
      expect(retried, isTrue);
    });

    testWidgets('shows the empty state without an action', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView(
            isLoading: false,
            errorMessage: null,
            isEmpty: true,
            onRetry: () {},
            emptyMessage: 'Vazio',
            child: const Text('data'),
          ),
        ),
      );

      expect(find.text('Vazio'), findsOneWidget);
      expect(find.text('data'), findsNothing);
      expect(find.text('Criar'), findsNothing);
    });

    testWidgets('shows and fires the empty action', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        _wrap(
          AsyncView(
            isLoading: false,
            errorMessage: null,
            isEmpty: true,
            onRetry: () {},
            emptyMessage: 'Vazio',
            emptyActionLabel: 'Criar',
            onEmptyAction: () => acted = true,
            child: const Text('data'),
          ),
        ),
      );

      await tester.tap(find.text('Criar'));
      expect(acted, isTrue);
    });

    testWidgets('shows the child when data is present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncView(
            isLoading: false,
            errorMessage: null,
            isEmpty: false,
            onRetry: () {},
            child: const Text('data'),
          ),
        ),
      );

      expect(find.text('data'), findsOneWidget);
    });
  });
}
