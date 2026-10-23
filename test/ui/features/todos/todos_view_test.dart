import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/todos/views/todos_view.dart';

import '../../../support/test_helpers.dart';

List<Object> _lists() => <Object>[
  {
    'id': 'l1',
    'name': 'Casa',
    'position': 1000,
    'active': true,
    'items': [
      {
        'id': 'i1',
        'listId': 'l1',
        'text': 'Comprar leite',
        'done': true,
        'position': 1000,
      },
      {
        'id': 'i2',
        'listId': 'l1',
        'text': 'Pagar renda',
        'done': false,
        'position': 2000,
      },
    ],
    'total': 2,
    'done': 1,
  },
];

/// The animated text style applied to a task's label.
TextStyle _taskStyle(WidgetTester tester, String text) {
  final finder = find.ancestor(
    of: find.text(text),
    matching: find.byType(AnimatedDefaultTextStyle),
  );
  return tester.widget<AnimatedDefaultTextStyle>(finder.first).style;
}

void main() {
  testWidgets('renders each list with its tasks and progress', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('1/2 concluídas'), findsOneWidget);
    expect(find.text('Comprar leite'), findsOneWidget);
    expect(find.text('Pagar renda'), findsOneWidget);

    expect(
      _taskStyle(tester, 'Comprar leite').decoration,
      TextDecoration.lineThrough,
    );
    expect(_taskStyle(tester, 'Pagar renda').decoration, TextDecoration.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when there are no lists', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async => jsonResponse(<Object>[]));

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ainda não há listas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles a task and strikes it through', (tester) async {
    setPhoneSize(tester);
    String? patchedPath;
    Object? patchedBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        patchedBody = jsonDecode(request.body);
        return jsonResponse(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar renda',
          'done': true,
          'position': 2000,
        });
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Concluir'));
    await tester.pumpAndSettle();

    expect(patchedPath, '/api/todo-lists/l1/items/i2');
    expect((patchedBody as Map<String, dynamic>)['done'], isTrue);
    expect(find.text('2/2 concluídas'), findsOneWidget);
    expect(
      _taskStyle(tester, 'Pagar renda').decoration,
      TextDecoration.lineThrough,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping a task right marks it done without removing it', (
    tester,
  ) async {
    setPhoneSize(tester);
    String? patchedPath;
    String? deletedPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        return jsonResponse(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar renda',
          'done': true,
          'position': 2000,
        });
      }
      if (request.method == 'DELETE') {
        deletedPath = request.url.path;
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.text('Pagar renda'), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    expect(patchedPath, '/api/todo-lists/l1/items/i2');
    expect(deletedPath, isNull);
    expect(find.text('Pagar renda'), findsOneWidget);
    expect(find.text('2/2 concluídas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping a task deletes it and offers undo', (tester) async {
    setPhoneSize(tester);
    String? deletedPath;
    String? restoredPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.method == 'DELETE') {
        deletedPath = request.url.path;
        return jsonResponse(const {'id': 'i2'});
      }
      if (request.url.path == '/api/todo-lists/l1/items/i2/restore' &&
          request.method == 'POST') {
        restoredPath = request.url.path;
        return jsonResponse(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar renda',
          'done': false,
          'position': 2000,
        });
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Pagar renda'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(deletedPath, '/api/todo-lists/l1/items/i2');
    expect(find.text('Pagar renda'), findsNothing);
    expect(find.text('1/1 concluídas'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    expect(restoredPath, '/api/todo-lists/l1/items/i2/restore');
    expect(find.text('Pagar renda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reorders lists through the drag handles', (tester) async {
    setPhoneSize(tester);
    Object? reorderBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(<Object>[
          {
            'id': 'l1',
            'name': 'Casa',
            'position': 1000,
            'active': true,
            'items': <Object>[],
          },
          {
            'id': 'l2',
            'name': 'Mercado',
            'position': 2000,
            'active': true,
            'items': <Object>[],
          },
        ]);
      }
      if (request.url.path == '/api/todo-lists/reorder' &&
          request.method == 'POST') {
        reorderBody = jsonDecode(request.body);
        return jsonResponse(const <Object>[]);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);

    final listView = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    listView.onReorder(1, 0);
    await tester.pumpAndSettle();

    expect((reorderBody as Map<String, dynamic>)['ids'], ['l2', 'l1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a task through the inline field', (tester) async {
    setPhoneSize(tester);
    Object? createdBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.url.path == '/api/todo-lists/l1/items' &&
          request.method == 'POST') {
        createdBody = jsonDecode(request.body);
        return jsonResponse(const {
          'id': 'i3',
          'listId': 'l1',
          'text': 'Comprar pão',
          'done': false,
          'position': 3000,
        }, status: 201);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Comprar pão');
    await tester.pump();
    await tester.tap(find.byTooltip('Adicionar tarefa'));
    await tester.pumpAndSettle();

    expect((createdBody as Map<String, dynamic>)['text'], 'Comprar pão');
    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('1/3 concluídas'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('places the add-task button after the input', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    final input = tester.getRect(find.byType(TextField));
    final button = tester.getRect(find.byTooltip('Adicionar tarefa'));
    expect(button.left, greaterThanOrEqualTo(input.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismisses the delete notification automatically', (
    tester,
  ) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.method == 'DELETE') {
        return jsonResponse(const {'id': 'i2'});
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Pagar renda'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('"Pagar renda" apagada.'), findsOneWidget);

    await tester.pump(AppMotion.snackBar + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('"Pagar renda" apagada.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a new list from the app bar action', (tester) async {
    setPhoneSize(tester);
    Object? createdBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.url.path == '/api/todo-lists' && request.method == 'POST') {
        createdBody = jsonDecode(request.body);
        return jsonResponse(const {
          'id': 'l2',
          'name': 'Mercado',
          'position': 2000,
          'active': true,
        }, status: 201);
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nova lista'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Mercado',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect((createdBody as Map<String, dynamic>)['name'], 'Mercado');
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Sem tarefas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides completed tasks when the filter is on', (tester) async {
    setPhoneSize(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return jsonResponse(_lists());
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comprar leite'), findsOneWidget);

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ocultar concluídas'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Comprar leite'), findsNothing);
    expect(find.text('Pagar renda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clears the completed tasks', (tester) async {
    setPhoneSize(tester);
    String? clearedPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.url.path == '/api/todo-lists/l1/clear-completed' &&
          request.method == 'POST') {
        clearedPath = request.url.path;
        return jsonResponse(const {'deleted': 1});
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opções da lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar concluídas'));
    await tester.pumpAndSettle();

    expect(clearedPath, '/api/todo-lists/l1/clear-completed');
    expect(find.text('Comprar leite'), findsNothing);
    expect(find.text('0/1 concluídas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits a task text', (tester) async {
    setPhoneSize(tester);
    Object? patchedBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return jsonResponse(_lists());
      }
      if (request.method == 'PATCH') {
        patchedBody = jsonDecode(request.body);
        return jsonResponse(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar água',
          'done': false,
          'position': 2000,
        });
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pagar renda'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Pagar água',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect((patchedBody as Map<String, dynamic>)['text'], 'Pagar água');
    expect(find.text('Pagar água'), findsOneWidget);
    expect(find.text('Pagar renda'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores an archived list', (tester) async {
    setPhoneSize(tester);
    String? restoredPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        if (request.url.queryParameters['includeInactive'] == 'true') {
          return jsonResponse(<Object>[
            ..._lists(),
            {
              'id': 'l9',
              'name': 'Arquivada',
              'position': 500,
              'active': false,
              'items': <Object>[],
            },
          ]);
        }
        return jsonResponse(_lists());
      }
      if (request.url.path == '/api/todo-lists/l9/restore' &&
          request.method == 'POST') {
        restoredPath = request.url.path;
        return jsonResponse(const {
          'id': 'l9',
          'name': 'Arquivada',
          'position': 500,
          'active': true,
        });
      }
      return jsonResponse(<Object>[], status: 404);
    });

    await tester.pumpWidget(
      wrapWithDependencies(testDependencies(client), const TodosView()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listas arquivadas'));
    await tester.pumpAndSettle();
    expect(find.text('Arquivada'), findsOneWidget);

    await tester.tap(find.text('Recuperar'));
    await tester.pumpAndSettle();

    expect(restoredPath, '/api/todo-lists/l9/restore');
    expect(find.text('Não há listas arquivadas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
