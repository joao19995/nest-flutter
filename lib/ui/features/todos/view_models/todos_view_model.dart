import 'package:flutter/foundation.dart';
import 'package:nest/data/repositories/todo_lists_repository.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/todo_list.dart';

/// Presentation state for the shared to-do lists.
///
/// Item toggles, edits, swipes and reorders are applied optimistically and
/// rolled back on failure, so the list stays responsive. Structural writes (a
/// new list, a rename, adding a task, clearing done tasks) flag [isBusy] and
/// surface errors via [actionError].
class TodosViewModel extends ChangeNotifier {
  TodosViewModel({required TodoListsRepository todoListsRepository})
    : _todoListsRepository = todoListsRepository;

  /// The position increment used between items (the API's 1000 gap).
  static const int _positionGap = 1000;

  final TodoListsRepository _todoListsRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<TodoList> _lists = const [];
  List<TodoList> get lists => _lists;

  bool get isEmpty => _lists.isEmpty;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  String? _actionError;
  String? get actionError => _actionError;

  bool _hideCompleted = false;

  /// When true, done tasks are hidden from every list.
  bool get hideCompleted => _hideCompleted;

  /// The total number of pending (not done) tasks across every list.
  int get pendingCount =>
      _lists.fold<int>(0, (sum, list) => sum + list.remaining);

  /// The tasks to display for [list], honouring [hideCompleted].
  List<TodoItem> itemsFor(TodoList list) => _hideCompleted
      ? [
          for (final item in list.items)
            if (!item.done) item,
        ]
      : list.items;

  /// Loads every active list with its visible items.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _lists = await _todoListsRepository.fetchLists();
    } on ApiFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads the lists without showing the loading skeleton (pull-to-refresh).
  Future<void> refresh() async {
    try {
      _lists = await _todoListsRepository.fetchLists();
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      notifyListeners();
    }
  }

  /// Shows or hides the done tasks.
  void setHideCompleted(bool value) {
    if (_hideCompleted == value) {
      return;
    }
    _hideCompleted = value;
    notifyListeners();
  }

  /// Clears the last action error (e.g. once its banner is dismissed).
  void clearActionError() {
    if (_actionError == null) {
      return;
    }
    _actionError = null;
    notifyListeners();
  }

  /// Toggles the [item]'s `done` state, optimistically.
  Future<void> toggleItem(TodoList list, TodoItem item) async {
    final desired = !item.done;
    _actionError = null;
    _replaceItem(list.id, item.copyWith(done: desired));
    notifyListeners();
    try {
      final updated = await _todoListsRepository.updateItem(
        list.id,
        item.id,
        done: desired,
      );
      _replaceItem(list.id, updated);
    } on ApiFailure catch (failure) {
      _replaceItem(list.id, item);
      _actionError = failure.message;
    } finally {
      notifyListeners();
    }
  }

  /// Changes the [item]'s text, optimistically.
  Future<void> editItem(TodoList list, TodoItem item, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == item.text) {
      return;
    }
    _actionError = null;
    _replaceItem(list.id, item.copyWith(text: trimmed));
    notifyListeners();
    try {
      final updated = await _todoListsRepository.updateItem(
        list.id,
        item.id,
        text: trimmed,
      );
      _replaceItem(list.id, updated);
    } on ApiFailure catch (failure) {
      _replaceItem(list.id, item);
      _actionError = failure.message;
    } finally {
      notifyListeners();
    }
  }

  /// Soft-deletes (hides) the [item], optimistically.
  Future<void> deleteItem(TodoList list, TodoItem item) async {
    _actionError = null;
    _removeItem(list.id, item.id);
    notifyListeners();
    try {
      await _todoListsRepository.deleteItem(list.id, item.id);
    } on ApiFailure catch (failure) {
      _insertItem(list.id, item);
      _actionError = failure.message;
    } finally {
      notifyListeners();
    }
  }

  /// Removes every done task from [list], optimistically.
  Future<void> clearCompleted(TodoList list) async {
    final done = [
      for (final item in list.items)
        if (item.done) item,
    ];
    if (done.isEmpty || _isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    final original = list.items;
    _updateList(
      list.id,
      (current) => current.copyWith(
        items: [
          for (final item in current.items)
            if (!item.done) item,
        ],
      ),
    );
    notifyListeners();
    try {
      for (final item in done) {
        await _todoListsRepository.deleteItem(list.id, item.id);
      }
    } on ApiFailure catch (failure) {
      _updateList(list.id, (current) => current.copyWith(items: original));
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Moves the task at [oldIndex] to [newIndex] (both into [list].items),
  /// renumbering its `position` to the midpoint of its new neighbours.
  Future<void> reorderItem(TodoList list, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= list.items.length ||
        newIndex < 0 ||
        newIndex >= list.items.length) {
      return;
    }
    final items = [...list.items];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    final position = _positionAt(items, newIndex);
    _actionError = null;
    _updateList(list.id, (current) => current.copyWith(items: items));
    notifyListeners();
    try {
      final updated = await _todoListsRepository.updateItem(
        list.id,
        moved.id,
        position: position,
      );
      _replaceItem(list.id, updated);
    } on ApiFailure catch (failure) {
      _updateList(list.id, (current) => current.copyWith(items: list.items));
      _actionError = failure.message;
    } finally {
      notifyListeners();
    }
  }

  /// Adds a task with [text] to the end of [list]. Returns true on success so
  /// the caller can clear its input.
  Future<bool> addItem(TodoList list, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isBusy) {
      return false;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final item = await _todoListsRepository.createItem(list.id, trimmed);
      _insertItem(list.id, item);
      return true;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Creates a list named [name]. Returns true on success.
  Future<bool> createList(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _isBusy) {
      return false;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final list = await _todoListsRepository.createList(name: trimmed);
      _lists = [..._lists, list];
      return true;
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Renames [list], optimistically. Returns true on success.
  Future<bool> renameList(TodoList list, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == list.name || _isBusy) {
      return false;
    }
    _isBusy = true;
    _actionError = null;
    _updateList(list.id, (current) => current.copyWith(name: trimmed));
    notifyListeners();
    try {
      final updated = await _todoListsRepository.renameList(list.id, trimmed);
      _updateList(
        list.id,
        (current) => current.copyWith(
          name: updated.name,
          items: updated.items.isEmpty ? current.items : updated.items,
        ),
      );
      return true;
    } on ApiFailure catch (failure) {
      _updateList(list.id, (current) => current.copyWith(name: list.name));
      _actionError = failure.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Soft-deletes [list] (hides it), optimistically.
  Future<void> deleteList(TodoList list) async {
    _actionError = null;
    _lists = [
      for (final current in _lists)
        if (current.id != list.id) current,
    ];
    notifyListeners();
    try {
      await _todoListsRepository.deleteList(list.id);
    } on ApiFailure catch (failure) {
      _lists = [..._lists, list]
        ..sort((a, b) => a.position.compareTo(b.position));
      _actionError = failure.message;
    } finally {
      notifyListeners();
    }
  }

  /// Returns the soft-deleted lists, or null when the request fails (the
  /// message is exposed through [actionError]).
  Future<List<TodoList>?> fetchArchived() async {
    try {
      final all = await _todoListsRepository.fetchLists(includeInactive: true);
      return [
        for (final list in all)
          if (!list.active) list,
      ];
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
      notifyListeners();
      return null;
    }
  }

  /// Restores a soft-deleted [list], adding it back to the active lists.
  Future<void> restoreList(TodoList list) async {
    if (_isBusy) {
      return;
    }
    _isBusy = true;
    _actionError = null;
    notifyListeners();
    try {
      final restored = await _todoListsRepository.restoreList(list.id);
      _lists = [..._lists, restored]
        ..sort((a, b) => a.position.compareTo(b.position));
    } on ApiFailure catch (failure) {
      _actionError = failure.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// The `position` for an item inserted at [index] in [items]: the midpoint
  /// of its neighbours, or a full gap away at either end.
  static int _positionAt(List<TodoItem> items, int index) {
    final before = index > 0 ? items[index - 1].position : null;
    final after = index < items.length - 1 ? items[index + 1].position : null;
    if (before != null && after != null) {
      return (before + after) ~/ 2;
    }
    if (before != null) {
      return before + _positionGap;
    }
    if (after != null) {
      final candidate = after - _positionGap;
      return candidate < 0 ? 0 : candidate;
    }
    return 0;
  }

  void _updateList(String listId, TodoList Function(TodoList) transform) {
    _lists = [
      for (final list in _lists)
        if (list.id == listId) transform(list) else list,
    ];
  }

  void _replaceItem(String listId, TodoItem item) {
    _updateList(
      listId,
      (list) => list.copyWith(
        items: [
          for (final current in list.items)
            if (current.id == item.id) item else current,
        ],
      ),
    );
  }

  void _removeItem(String listId, String itemId) {
    _updateList(
      listId,
      (list) => list.copyWith(
        items: [
          for (final current in list.items)
            if (current.id != itemId) current,
        ],
      ),
    );
  }

  void _insertItem(String listId, TodoItem item) {
    _updateList(
      listId,
      (list) => list.copyWith(
        items: [
          for (final current in list.items)
            if (current.id != item.id) current,
          item,
        ]..sort((a, b) => a.position.compareTo(b.position)),
      ),
    );
  }
}
