import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/todos/views/todos_view.dart';

AppDependencies _dependencies(MockClient client) => AppDependencies(
  apiClient: NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

Widget _wrap(AppDependencies dependencies, Widget child) => DependenciesScope(
  dependencies: dependencies,
  child: MaterialApp(theme: AppTheme.light, home: child),
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

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

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders each list with its tasks and progress', (tester) async {
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return _json(_lists());
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('1/2 concluídas'), findsOneWidget);
    expect(find.text('Comprar leite'), findsNothing);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.text('Comprar leite'), findsOneWidget);
    expect(find.text('Pagar renda'), findsOneWidget);

    final done = tester.widget<Text>(find.text('Comprar leite'));
    expect(done.style?.decoration, TextDecoration.lineThrough);
    final pending = tester.widget<Text>(find.text('Pagar renda'));
    expect(pending.style?.decoration, TextDecoration.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when there are no lists', (tester) async {
    _setPhone(tester);
    final client = MockClient((request) async => _json(<Object>[]));

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();

    expect(find.text('Ainda não há listas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles a task and strikes it through', (tester) async {
    _setPhone(tester);
    String? patchedPath;
    Object? patchedBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.method == 'PATCH') {
        patchedPath = request.url.path;
        patchedBody = jsonDecode(request.body);
        return _json(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar renda',
          'done': true,
          'position': 2000,
        });
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Concluir'));
    await tester.pumpAndSettle();

    expect(patchedPath, '/api/todo-lists/l1/items/i2');
    expect((patchedBody as Map<String, dynamic>)['done'], isTrue);
    expect(find.text('2/2 concluídas'), findsOneWidget);
    final updated = tester.widget<Text>(find.text('Pagar renda'));
    expect(updated.style?.decoration, TextDecoration.lineThrough);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping a task to the left deletes it', (tester) async {
    _setPhone(tester);
    String? deletedPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.method == 'DELETE') {
        deletedPath = request.url.path;
        return _json(const {'id': 'i2'});
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Pagar renda'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(deletedPath, '/api/todo-lists/l1/items/i2');
    expect(find.text('Pagar renda'), findsNothing);
    expect(find.text('1/1 concluídas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a task through the inline field', (tester) async {
    _setPhone(tester);
    Object? createdBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.url.path == '/api/todo-lists/l1/items' &&
          request.method == 'POST') {
        createdBody = jsonDecode(request.body);
        return _json(const {
          'id': 'i3',
          'listId': 'l1',
          'text': 'Comprar pão',
          'done': false,
          'position': 3000,
        }, status: 201);
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Comprar pão');
    await tester.tap(find.byTooltip('Adicionar tarefa'));
    await tester.pumpAndSettle();

    expect((createdBody as Map<String, dynamic>)['text'], 'Comprar pão');
    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('1/3 concluídas'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a new list from the app bar action', (tester) async {
    _setPhone(tester);
    Object? createdBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.url.path == '/api/todo-lists' && request.method == 'POST') {
        createdBody = jsonDecode(request.body);
        return _json(const {
          'id': 'l2',
          'name': 'Mercado',
          'position': 2000,
          'active': true,
        }, status: 201);
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
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
    _setPhone(tester);
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return _json(_lists());
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.text('Comprar leite'), findsOneWidget);

    await tester.tap(find.byTooltip('Ocultar concluídas'));
    await tester.pumpAndSettle();

    expect(find.text('Comprar leite'), findsNothing);
    expect(find.text('Pagar renda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clears the completed tasks', (tester) async {
    _setPhone(tester);
    final deleted = <String>[];
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.method == 'DELETE') {
        deleted.add(request.url.path);
        return _json(const {'id': 'i1'});
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Limpar concluídas'));
    await tester.pumpAndSettle();

    expect(deleted, ['/api/todo-lists/l1/items/i1']);
    expect(find.text('Comprar leite'), findsNothing);
    expect(find.text('0/1 concluídas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits a task text', (tester) async {
    _setPhone(tester);
    Object? patchedBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.method == 'PATCH') {
        patchedBody = jsonDecode(request.body);
        return _json(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar água',
          'done': false,
          'position': 2000,
        });
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
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
    _setPhone(tester);
    String? restoredPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        if (request.url.queryParameters['includeInactive'] == 'true') {
          return _json(<Object>[
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
        return _json(_lists());
      }
      if (request.url.path == '/api/todo-lists/l9/restore' &&
          request.method == 'POST') {
        restoredPath = request.url.path;
        return _json(const {
          'id': 'l9',
          'name': 'Arquivada',
          'position': 500,
          'active': true,
        });
      }
      return _json(<Object>[], status: 404);
    });

    await tester.pumpWidget(_wrap(_dependencies(client), const TodosView()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Listas arquivadas'));
    await tester.pumpAndSettle();
    expect(find.text('Arquivada'), findsOneWidget);

    await tester.tap(find.text('Recuperar'));
    await tester.pumpAndSettle();

    expect(restoredPath, '/api/todo-lists/l9/restore');
    expect(find.text('Não há listas arquivadas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
