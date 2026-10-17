import 'package:flutter_test/flutter_test.dart';
import 'package:nest/data/models/todo_list_model.dart';
import 'package:nest/domain/models/todo_list.dart';

void main() {
  group('TodoItemModel', () {
    test('maps a JSON payload to a domain TodoItem', () {
      final model = TodoItemModel.fromJson(const {
        'id': 'i1',
        'listId': 'l1',
        'text': 'Comprar leite',
        'done': true,
        'position': 1000,
      });

      final TodoItem item = model.toDomain();

      expect(item.id, 'i1');
      expect(item.listId, 'l1');
      expect(item.text, 'Comprar leite');
      expect(item.done, isTrue);
      expect(item.position, 1000);
    });
  });

  group('TodoListModel', () {
    test('maps a list with items and derives the counters', () {
      final model = TodoListModel.fromJson(const {
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
      });

      final TodoList list = model.toDomain();

      expect(list.id, 'l1');
      expect(list.name, 'Casa');
      expect(list.position, 1000);
      expect(list.active, isTrue);
      expect(list.items, hasLength(2));
      expect(list.total, 2);
      expect(list.done, 1);
      expect(list.remaining, 1);
      expect(list.isComplete, isFalse);
    });

    test('flags a list as complete only when it has done items', () {
      final list = TodoListModel.fromJson(const {
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
        ],
      }).toDomain();

      expect(list.isComplete, isTrue);
      expect(list.done, 1);
    });

    test('handles a list without items and without counters', () {
      final list = TodoListModel.fromJson(const {
        'id': 'l1',
        'name': 'Nova',
      }).toDomain();

      expect(list.items, isEmpty);
      expect(list.total, 0);
      expect(list.done, 0);
      expect(list.isComplete, isFalse);
      expect(list.active, isTrue);
    });
  });
}
