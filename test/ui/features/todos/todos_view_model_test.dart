import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nest/data/repositories/todo_lists_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/ui/features/todos/view_models/todos_view_model.dart';

TodosViewModel _viewModel(MockClient client) => TodosViewModel(
  todoListsRepository: TodoListsRepository(
    client: NestApiClient(
      httpClient: client,
      baseUrl: 'http://test.local',
      apiKey: '',
    ),
  ),
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
  },
];

void main() {
  test('reorders an item and patches the midpoint position', () async {
    Object? patchedBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.method == 'PATCH') {
        patchedBody = jsonDecode(request.body);
        return _json(const {
          'id': 'i1',
          'listId': 'l1',
          'text': 'Comprar leite',
          'done': true,
          'position': 3000,
        });
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.reorderItem(viewModel.lists.single, 0, 1);

    expect((patchedBody as Map<String, dynamic>)['position'], 3000);
    expect(viewModel.lists.single.items.map((item) => item.id), ['i2', 'i1']);
  });

  test('clears completed tasks', () async {
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

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.clearCompleted(viewModel.lists.single);

    expect(deleted, ['/api/todo-lists/l1/items/i1']);
    expect(viewModel.lists.single.items.map((item) => item.id), ['i2']);
    expect(viewModel.lists.single.done, 0);
  });

  test('itemsFor hides done tasks when the filter is on', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists') {
        return _json(_lists());
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    expect(viewModel.itemsFor(viewModel.lists.single), hasLength(2));

    viewModel.setHideCompleted(true);
    expect(viewModel.itemsFor(viewModel.lists.single).map((item) => item.id), [
      'i2',
    ]);
    expect(viewModel.pendingCount, 1);
  });
}
