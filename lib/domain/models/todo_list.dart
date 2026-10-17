/// A task inside a [TodoList].
class TodoItem {
  const TodoItem({
    required this.id,
    required this.listId,
    required this.text,
    required this.done,
    required this.position,
  });

  /// The item's unique identifier.
  final String id;

  /// The id of the list the item belongs to.
  final String listId;

  /// The item's display text.
  final String text;

  /// Whether the item is checked. Reversible, unlike deletion.
  final bool done;

  /// The item's ordering position within its list.
  final int position;

  /// Returns a copy of this item with the given fields replaced.
  TodoItem copyWith({String? text, bool? done, int? position}) => TodoItem(
    id: id,
    listId: listId,
    text: text ?? this.text,
    done: done ?? this.done,
    position: position ?? this.position,
  );
}

/// A named list of tasks in the shared to-do feature.
///
/// [items] holds only the visible (non-deleted) items; the API soft-deletes
/// items on swipe and can restore them on undo.
class TodoList {
  const TodoList({
    required this.id,
    required this.name,
    required this.position,
    required this.active,
    required this.items,
  });

  final String id;
  final String name;
  final int position;
  final bool active;
  final List<TodoItem> items;

  /// The number of visible items.
  int get total => items.length;

  /// The number of visible items already done.
  int get done => items.where((item) => item.done).length;

  /// The number of visible items still to do.
  int get remaining => total - done;

  /// True when the list has items and all of them are done.
  bool get isComplete => total > 0 && done == total;

  /// Returns a copy of this list with the given fields replaced.
  TodoList copyWith({
    String? name,
    int? position,
    bool? active,
    List<TodoItem>? items,
  }) => TodoList(
    id: id,
    name: name ?? this.name,
    position: position ?? this.position,
    active: active ?? this.active,
    items: items ?? this.items,
  );
}
