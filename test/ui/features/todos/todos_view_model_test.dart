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

List<Object> _twoLists() => <Object>[
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
];

void main() {
  test('reorders an item through the items reorder endpoint', () async {
    Object? reorderBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.url.path == '/api/todo-lists/l1/items/reorder' &&
          request.method == 'POST') {
        reorderBody = jsonDecode(request.body);
        return _json(const [
          {
            'id': 'i2',
            'listId': 'l1',
            'text': 'Pagar renda',
            'done': false,
            'position': 1000,
          },
          {
            'id': 'i1',
            'listId': 'l1',
            'text': 'Comprar leite',
            'done': true,
            'position': 2000,
          },
        ]);
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.reorderItem(viewModel.lists.single, 0, 1);

    expect((reorderBody as Map<String, dynamic>)['ids'], ['i2', 'i1']);
    expect(viewModel.lists.single.items.map((item) => item.id), ['i2', 'i1']);
  });

  test('reorders lists and adopts the server order', () async {
    Object? reorderBody;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_twoLists());
      }
      if (request.url.path == '/api/todo-lists/reorder' &&
          request.method == 'POST') {
        reorderBody = jsonDecode(request.body);
        return _json(const [
          {
            'id': 'l2',
            'name': 'Mercado',
            'position': 1000,
            'active': true,
            'items': <Object>[],
          },
          {
            'id': 'l1',
            'name': 'Casa',
            'position': 1000,
            'active': true,
            'items': <Object>[],
          },
        ]);
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.reorderLists(1, 0);

    expect((reorderBody as Map<String, dynamic>)['ids'], ['l2', 'l1']);
    expect(viewModel.lists.map((list) => list.id), ['l2', 'l1']);
  });

  test('clears completed tasks in one request', () async {
    String? clearedPath;
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.url.path == '/api/todo-lists/l1/clear-completed' &&
          request.method == 'POST') {
        clearedPath = request.url.path;
        return _json(const {'deleted': 1});
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    await viewModel.clearCompleted(viewModel.lists.single);

    expect(clearedPath, '/api/todo-lists/l1/clear-completed');
    expect(viewModel.lists.single.items.map((item) => item.id), ['i2']);
    expect(viewModel.lists.single.done, 0);
  });

  test('restores a swiped task through the restore endpoint', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/todo-lists' && request.method == 'GET') {
        return _json(_lists());
      }
      if (request.method == 'DELETE') {
        return _json(const {'id': 'i2'});
      }
      if (request.url.path == '/api/todo-lists/l1/items/i2/restore' &&
          request.method == 'POST') {
        return _json(const {
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pagar renda',
          'done': false,
          'position': 2000,
        });
      }
      return _json(<Object>[], status: 404);
    });

    final viewModel = _viewModel(client);
    await viewModel.load();
    final list = viewModel.lists.single;
    final item = list.items.firstWhere((candidate) => candidate.id == 'i2');

    await viewModel.deleteItem(list, item);
    expect(viewModel.lists.single.items.map((candidate) => candidate.id), [
      'i1',
    ]);

    await viewModel.restoreItem(list, item);
    expect(viewModel.lists.single.items.map((candidate) => candidate.id), [
      'i1',
      'i2',
    ]);
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
