import 'package:flutter/material.dart';
import 'package:nest/domain/models/todo_list.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/todos/view_models/todos_view_model.dart';

/// The shared to-do lists: one expandable card per list, with checkable tasks
/// that can be struck through, edited, reordered and swiped away.
class TodosView extends StatefulWidget {
  const TodosView({super.key, this.viewModel});

  /// An externally owned view model. When null the view creates and owns one.
  final TodosViewModel? viewModel;

  @override
  State<TodosView> createState() => _TodosViewState();
}

class _TodosViewState extends State<TodosView> {
  TodosViewModel? _viewModel;
  bool _ownsViewModel = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final injected = widget.viewModel;
    if (injected != null) {
      _viewModel = injected;
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = TodosViewModel(
      todoListsRepository: dependencies.todoListsRepository,
    )..load();
    _ownsViewModel = true;
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel?.dispose();
    }
    super.dispose();
  }

  Future<void> _createList() async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }
    final name = await _promptText(
      context,
      title: 'Nova lista',
      hintText: 'Nome da lista',
      confirmLabel: 'Criar',
    );
    if (name != null) {
      await viewModel.createList(name);
    }
  }

  Future<void> _openArchived() async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _ArchivedListsSheet(viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Tarefas'),
          actions: [
            PopupMenuButton<_TodosMenu>(
              tooltip: 'Mais opções',
              icon: Icon(
                Icons.more_vert,
                size: AppSizes.iconLarge,
                color: context.colors.faint,
              ),
              onSelected: (menu) {
                switch (menu) {
                  case _TodosMenu.toggleCompleted:
                    viewModel.setHideCompleted(!viewModel.hideCompleted);
                  case _TodosMenu.archived:
                    _openArchived();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _TodosMenu.toggleCompleted,
                  child: Row(
                    children: [
                      const Expanded(child: Text('Ocultar concluídas')),
                      if (viewModel.hideCompleted)
                        Icon(
                          Icons.check,
                          size: AppSizes.iconMedium,
                          color: context.colors.primary,
                        ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _TodosMenu.archived,
                  child: Text('Listas arquivadas'),
                ),
              ],
            ),
            AppButton.icon(
              icon: Icons.add,
              tooltip: 'Nova lista',
              onPressed: _createList,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há listas.',
            emptyIcon: Icons.checklist_outlined,
            emptyActionLabel: 'Criar lista',
            onEmptyAction: _createList,
            child: _TodosContent(viewModel: viewModel),
          ),
        ),
      ),
    );
  }
}

class _TodosContent extends StatelessWidget {
  const _TodosContent({required this.viewModel});

  final TodosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final actionError = viewModel.actionError;
    final lists = viewModel.lists;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          color: context.colors.primary,
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TodosHero(viewModel: viewModel),
                if (actionError != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppErrorBanner(
                    message: actionError,
                    onDismiss: viewModel.clearActionError,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
            itemCount: lists.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              viewModel.reorderLists(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final list = lists[index];
              return Padding(
                key: ValueKey(list.id),
                padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.md),
                child: _ListCard(
                  list: list,
                  index: index,
                  viewModel: viewModel,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The to-do overview hero: how many tasks remain and the overall completion.
class _TodosHero extends StatelessWidget {
  const _TodosHero({required this.viewModel});

  final TodosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final total = viewModel.totalCount;
    final done = viewModel.doneCount;
    final fraction = total > 0 ? done / total : 0.0;
    return HeroPanel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POR FAZER',
                  style: AppTextStyles.navSection(
                    context.colors,
                  ).copyWith(color: AppColors.onHeroMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${viewModel.pendingCount}',
                  style: AppTextStyles.statDisplay.copyWith(
                    color: AppColors.onHero,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$done de $total concluídas',
                    style: AppTextStyles.small(
                      context.colors,
                    ).copyWith(color: AppColors.onHeroMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppProgressRing(
            progress: fraction,
            label: AppFormatters.percentage((fraction * 100).round()),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatefulWidget {
  const _ListCard({
    required this.list,
    required this.index,
    required this.viewModel,
  });

  final TodoList list;
  final int index;
  final TodosViewModel viewModel;

  @override
  State<_ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<_ListCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.list.remaining > 0;
  }

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final viewModel = widget.viewModel;
    return Opacity(
      opacity: list.isComplete ? AppOpacity.dimmed : AppOpacity.full,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ListHeader(
              list: list,
              index: widget.index,
              viewModel: viewModel,
              isExpanded: _isExpanded,
              onToggle: _toggle,
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.easing,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? _ListBody(list: list, viewModel: viewModel)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.list, required this.viewModel});

  final TodoList list;
  final TodosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final items = viewModel.itemsFor(list);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              viewModel.hideCompleted && list.total > 0
                  ? 'Nada pendente.'
                  : 'Sem tarefas.',
              style: AppTextStyles.bodyMuted(context.colors),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              viewModel.reorderItem(list, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final row = Dismissible(
                key: ValueKey('${item.id}-dismiss'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  viewModel.deleteItem(list, item);
                  showAppSnackBar(
                    ScaffoldMessenger.of(context),
                    message: '"${item.text}" apagada.',
                    actionLabel: 'Desfazer',
                    onAction: () => viewModel.restoreItem(list, item),
                  );
                },
                background: const DismissBackground(
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: const DismissBackground(
                  alignment: Alignment.centerRight,
                ),
                child: _TaskRow(
                  item: item,
                  onToggle: () => viewModel.toggleItem(list, item),
                  onEdit: () => _edit(context, item),
                ),
              );
              if (viewModel.hideCompleted) {
                return KeyedSubtree(key: ValueKey(item.id), child: row);
              }
              return ReorderableDelayedDragStartListener(
                key: ValueKey(item.id),
                index: index,
                child: row,
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        _AddTaskField(onSubmit: (text) => viewModel.addItem(list, text)),
      ],
    );
  }

  Future<void> _edit(BuildContext context, TodoItem item) async {
    final text = await _promptText(
      context,
      title: 'Editar tarefa',
      initialValue: item.text,
      hintText: 'Texto da tarefa',
      maxLength: 500,
    );
    if (text != null) {
      await viewModel.editItem(list, item, text);
    }
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.list,
    required this.index,
    required this.viewModel,
    required this.isExpanded,
    required this.onToggle,
  });

  final TodoList list;
  final int index;
  final TodosViewModel viewModel;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.sm,
              top: AppSpacing.xs,
            ),
            child: Icon(
              Icons.drag_indicator,
              size: AppSizes.iconMedium,
              color: context.colors.faint,
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.smAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: AppSizes.iconLarge,
                    color: context.colors.faint,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.name,
                          style: AppTextStyles.sectionHeading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _progressLabel(list),
                              style: AppTextStyles.small(context.colors),
                            ),
                            if (list.isComplete)
                              AppBadge(
                                label: 'CONCLUÍDA',
                                style: AppBadgeStyles.open(context.colors),
                              ),
                          ],
                        ),
                        if (list.total > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: AppRadius.fullAll,
                            child: LinearProgressIndicator(
                              value: list.done / list.total,
                              minHeight: AppSizes.progressBarHeight,
                              backgroundColor: context.colors.lineSoft,
                              color: list.isComplete
                                  ? context.colors.primaryDark
                                  : context.colors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        PopupMenuButton<_ListAction>(
          tooltip: 'Opções da lista',
          icon: Icon(
            Icons.more_vert,
            size: AppSizes.iconLarge,
            color: context.colors.faint,
          ),
          onSelected: (action) {
            switch (action) {
              case _ListAction.rename:
                _rename(context);
              case _ListAction.clear:
                viewModel.clearCompleted(list);
              case _ListAction.delete:
                _delete(context);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _ListAction.rename,
              child: Text('Renomear'),
            ),
            if (list.done > 0)
              const PopupMenuItem(
                value: _ListAction.clear,
                child: Text('Limpar concluídas'),
              ),
            const PopupMenuItem(
              value: _ListAction.delete,
              child: Text('Eliminar lista'),
            ),
          ],
        ),
      ],
    );
  }

  static String _progressLabel(TodoList list) =>
      list.total == 0 ? 'Sem tarefas' : '${list.done}/${list.total} concluídas';

  Future<void> _rename(BuildContext context) async {
    final name = await _promptText(
      context,
      title: 'Renomear lista',
      initialValue: list.name,
      hintText: 'Nome da lista',
    );
    if (name != null) {
      await viewModel.renameList(list, name);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar lista?',
      message: 'A lista "${list.name}" deixa de aparecer com as suas tarefas.',
    );
    if (confirmed) {
      await viewModel.deleteList(list);
    }
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onToggle,
          iconSize: AppSizes.iconLarge,
          tooltip: item.done ? 'Desmarcar' : 'Concluir',
          color: item.done ? context.colors.primary : context.colors.faint,
          icon: Icon(item.done ? Icons.check_circle : Icons.circle_outlined),
        ),
        Expanded(
          child: InkWell(
            onTap: onEdit,
            borderRadius: AppRadius.smAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.standard,
                curve: AppMotion.easing,
                style: AppTextStyles.body.copyWith(
                  color: item.done ? context.colors.muted : context.colors.ink,
                  decoration: item.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: context.colors.muted,
                ),
                child: Text(item.text),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTaskField extends StatefulWidget {
  const _AddTaskField({required this.onSubmit});

  final Future<bool> Function(String text) onSubmit;

  @override
  State<_AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends State<_AddTaskField> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    final saved = await widget.onSubmit(text);
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    if (saved) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 500,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Adicionar tarefa',
              counterText: '',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(
          onPressed: _hasText && !_isSaving ? _submit : null,
          tooltip: 'Adicionar tarefa',
          iconSize: AppSizes.iconLarge,
          color: context.colors.primary,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _ArchivedListsSheet extends StatefulWidget {
  const _ArchivedListsSheet({required this.viewModel});

  final TodosViewModel viewModel;

  @override
  State<_ArchivedListsSheet> createState() => _ArchivedListsSheetState();
}

class _ArchivedListsSheetState extends State<_ArchivedListsSheet> {
  bool _isLoading = true;
  bool _hasError = false;
  List<TodoList> _lists = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final lists = await widget.viewModel.fetchArchived();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _hasError = lists == null;
      _lists = lists ?? const [];
    });
  }

  Future<void> _restore(TodoList list) async {
    await widget.viewModel.restoreList(list);
    if (!mounted) {
      return;
    }
    setState(() {
      _lists = [
        for (final current in _lists)
          if (current.id != list.id) current,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Listas arquivadas', style: AppTextStyles.pageTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'As listas eliminadas ficam aqui e podem ser recuperadas.',
            style: AppTextStyles.bodyMuted(context.colors),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            const Column(
              children: [
                AppSkeleton(),
                SizedBox(height: AppSpacing.sm),
                AppSkeleton(width: 220),
              ],
            )
          else if (_hasError)
            Text(
              'Não foi possível carregar as listas.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else if (_lists.isEmpty)
            Text(
              'Não há listas arquivadas.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            for (var index = 0; index < _lists.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              _ArchivedRow(
                list: _lists[index],
                onRestore: () => _restore(_lists[index]),
              ),
            ],
        ],
      ),
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({required this.list, required this.onRestore});

  final TodoList list;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            list.name,
            style: AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppButton(
          label: 'Recuperar',
          variant: AppButtonVariant.secondary,
          onPressed: onRestore,
        ),
      ],
    );
  }
}

/// Prompts for a single line of text; resolves to the trimmed value or null.
Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hintText = '',
  String confirmLabel = 'Guardar',
  int maxLength = 100,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextPromptDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      confirmLabel: confirmLabel,
      maxLength: maxLength,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.confirmLabel,
    required this.maxLength,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final String confirmLabel;
  final int maxLength;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        maxLength: widget.maxLength,
        decoration: InputDecoration(hintText: widget.hintText, counterText: ''),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(label: widget.confirmLabel, onPressed: _confirm),
      ],
    );
  }
}

/// The secondary actions in the app bar's overflow menu.
enum _TodosMenu { toggleCompleted, archived }

/// The per-list actions in a card's overflow menu.
enum _ListAction { rename, clear, delete }
