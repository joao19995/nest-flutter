import 'package:nest/domain/models/todo_list.dart';

/// API-facing representation of a [TodoItem], with JSON mapping.
class TodoItemModel {
  const TodoItemModel({
    required this.id,
    required this.listId,
    required this.text,
    required this.done,
    required this.position,
  });

  factory TodoItemModel.fromJson(Map<String, dynamic> json) => TodoItemModel(
    id: json['id'] as String,
    listId: json['listId'] as String,
    text: json['text'] as String,
    done: json['done'] as bool? ?? false,
    position: (json['position'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String listId;
  final String text;
  final bool done;
  final int position;

  TodoItem toDomain() => TodoItem(
    id: id,
    listId: listId,
    text: text,
    done: done,
    position: position,
  );
}

/// API-facing representation of a [TodoList], with JSON mapping.
///
/// The `total`/`done` counters served by the API are not stored: they are
/// derived from [items], which is the single source of truth.
class TodoListModel {
  const TodoListModel({
    required this.id,
    required this.name,
    required this.position,
    required this.active,
    required this.items,
  });

  factory TodoListModel.fromJson(Map<String, dynamic> json) => TodoListModel(
    id: json['id'] as String,
    name: json['name'] as String,
    position: (json['position'] as num?)?.toInt() ?? 0,
    active: json['active'] as bool? ?? true,
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => TodoItemModel.fromJson(item).toDomain())
        .toList(growable: false),
  );

  final String id;
  final String name;
  final int position;
  final bool active;
  final List<TodoItem> items;

  TodoList toDomain() => TodoList(
    id: id,
    name: name,
    position: position,
    active: active,
    items: items,
  );
}
