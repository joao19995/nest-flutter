import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nest/data/repositories/todo_lists_repository.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/failures/api_failure.dart';

import '../../support/test_helpers.dart';

TodoListsRepository _repository(MockClient client) => TodoListsRepository(
  client: NestApiClient(
    httpClient: client,
    baseUrl: 'http://test.local',
    apiKey: '',
  ),
);

Map<String, dynamic> _list() => {
  'id': 'l1',
  'name': 'Casa',
  'position': 1000,
  'active': true,
  'items': [
    {
      'id': 'i1',
      'listId': 'l1',
      'text': 'Leite',
      'done': false,
      'position': 1000,
    },
  ],
};

void main() {
  test('fetchLists maps active lists and their items', () async {
    final lists = await _repository(
      MockClient((request) async => jsonResponse([_list()])),
    ).fetchLists();

    expect(lists.single.name, 'Casa');
    expect(lists.single.items.single.text, 'Leite');
  });

  test('writes hit the expected routes', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add('${request.method} ${request.url.path}');
      if (request.url.path.endsWith('/items') ||
          request.url.path.endsWith('/restore') ||
          (RegExp(r'/items/[^/]+$').hasMatch(request.url.path) &&
              !request.url.path.endsWith('/items/reorder'))) {
        return jsonResponse({
          'id': 'i2',
          'listId': 'l1',
          'text': 'Pão',
          'done': false,
          'position': 2000,
        });
      }
      if (request.url.path.endsWith('/clear-completed')) {
        return jsonResponse({'deleted': 2});
      }
      if (request.url.path.endsWith('/items/reorder')) {
        return jsonResponse([
          {
            'id': 'i1',
            'listId': 'l1',
            'text': 'Leite',
            'done': false,
            'position': 1000,
          },
        ]);
      }
      if (request.url.path.endsWith('/reorder')) {
        return jsonResponse([_list()]);
      }
      return jsonResponse(_list());
    });
    final repository = _repository(client);

    await repository.createList(name: 'Casa');
    await repository.createItem('l1', 'Pão');
    await repository.updateItem('l1', 'i2', done: true);
    await repository.reorderItems('l1', ['i1']);
    await repository.reorderLists(['l1']);
    await repository.clearCompleted('l1');
    await repository.deleteItem('l1', 'i2');
    await repository.restoreItem('l1', 'i2');

    expect(paths, [
      'POST /api/todo-lists',
      'POST /api/todo-lists/l1/items',
      'PATCH /api/todo-lists/l1/items/i2',
      'POST /api/todo-lists/l1/items/reorder',
      'POST /api/todo-lists/reorder',
      'POST /api/todo-lists/l1/clear-completed',
      'DELETE /api/todo-lists/l1/items/i2',
      'POST /api/todo-lists/l1/items/i2/restore',
    ]);
  });

  test('fails on an invalid list payload', () async {
    await expectLater(
      _repository(
        MockClient((request) async => jsonResponse(const {'not': 'a list'})),
      ).fetchLists(),
      throwsA(isA<ApiFailure>()),
    );
  });
}
