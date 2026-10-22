import 'package:nest/data/models/json_mapper.dart';
import 'package:nest/data/models/todo_list_model.dart';
import 'package:nest/data/services/nest_api_client.dart';
import 'package:nest/domain/models/todo_list.dart';

/// Reads and writes the shared to-do lists and their items.
class TodoListsRepository {
  TodoListsRepository({required NestApiClient client}) : _client = client;

  final NestApiClient _client;

  /// Returns the lists ordered by `position`, each with its visible items.
  ///
  /// Inactive (soft-deleted) lists are excluded unless [includeInactive].
  Future<List<TodoList>> fetchLists({bool includeInactive = false}) async {
    final path = includeInactive
        ? '/api/todo-lists?includeInactive=true'
        : '/api/todo-lists';
    final data = await _client.get(path);
    return mapJsonList(data, (json) => TodoListModel.fromJson(json).toDomain());
  }

  /// Creates a list named [name] and returns it (without items).
  Future<TodoList> createList({required String name}) async {
    final data = await _client.post('/api/todo-lists', {'name': name});
    return mapJson(data, (json) => TodoListModel.fromJson(json).toDomain());
  }

  /// Renames the active list [id].
  Future<TodoList> renameList(String id, String name) async {
    final data = await _client.put('/api/todo-lists/$id', {
      'name': name,
      'active': true,
    });
    return mapJson(data, (json) => TodoListModel.fromJson(json).toDomain());
  }

  /// Restores a soft-deleted list [id].
  Future<TodoList> restoreList(String id) async {
    final data = await _client.post('/api/todo-lists/$id/restore', const {});
    return mapJson(data, (json) => TodoListModel.fromJson(json).toDomain());
  }

  /// Persists the given [ids] as the new list order, renumbered by the server.
  Future<List<TodoList>> reorderLists(List<String> ids) async {
    final data = await _client.post('/api/todo-lists/reorder', {'ids': ids});
    return mapJsonList(data, (json) => TodoListModel.fromJson(json).toDomain());
  }

  /// Soft-deletes the list [id] (sets `active = false`).
  Future<void> deleteList(String id) => _client.delete('/api/todo-lists/$id');

  /// Adds a task with [text] to the end of the list [listId].
  Future<TodoItem> createItem(String listId, String text) async {
    final data = await _client.post('/api/todo-lists/$listId/items', {
      'text': text,
    });
    return mapJson(data, (json) => TodoItemModel.fromJson(json).toDomain());
  }

  /// Updates a task. At least one of [text], [done] or [position] is required.
  Future<TodoItem> updateItem(
    String listId,
    String itemId, {
    String? text,
    bool? done,
    int? position,
  }) async {
    final data = await _client.patch('/api/todo-lists/$listId/items/$itemId', {
      'text': ?text,
      'done': ?done,
      'position': ?position,
    });
    return mapJson(data, (json) => TodoItemModel.fromJson(json).toDomain());
  }

  /// Persists the given [ids] as the new item order of [listId], renumbered by
  /// the server.
  Future<List<TodoItem>> reorderItems(String listId, List<String> ids) async {
    final data = await _client.post('/api/todo-lists/$listId/items/reorder', {
      'ids': ids,
    });
    return mapJsonList(data, (json) => TodoItemModel.fromJson(json).toDomain());
  }

  /// Soft-deletes the task [itemId] (the swipe gesture).
  Future<void> deleteItem(String listId, String itemId) =>
      _client.delete('/api/todo-lists/$listId/items/$itemId');

  /// Restores a soft-deleted task [itemId].
  Future<TodoItem> restoreItem(String listId, String itemId) async {
    final data = await _client.post(
      '/api/todo-lists/$listId/items/$itemId/restore',
      const {},
    );
    return mapJson(data, (json) => TodoItemModel.fromJson(json).toDomain());
  }

  /// Deletes every done task of [listId] in one request; returns how many.
  Future<int> clearCompleted(String listId) async {
    final data = await _client.post(
      '/api/todo-lists/$listId/clear-completed',
      const {},
    );
    return mapJson(data, (json) => (json['deleted'] as num?)?.toInt() ?? 0);
  }
}
