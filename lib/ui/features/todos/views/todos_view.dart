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
            AppButton.icon(
              icon: viewModel.hideCompleted
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              tooltip: viewModel.hideCompleted
                  ? 'Mostrar concluídas'
                  : 'Ocultar concluídas',
              onPressed: () =>
                  viewModel.setHideCompleted(!viewModel.hideCompleted),
            ),
            AppButton.icon(
              icon: Icons.inventory_2_outlined,
              tooltip: 'Listas arquivadas',
              onPressed: _openArchived,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.md;
        final cards = <Widget>[
          for (final list in viewModel.lists)
            _ListCard(key: ValueKey(list.id), list: list, viewModel: viewModel),
        ];
        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          color: context.colors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (actionError != null) ...[
                  _ActionErrorBanner(
                    message: actionError,
                    onDismiss: viewModel.clearActionError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (isWide)
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      for (final card in cards)
                        SizedBox(
                          width: (constraints.maxWidth - AppSpacing.lg) / 2,
                          child: card,
                        ),
                    ],
                  )
                else
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.md),
                    cards[index],
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListCard extends StatefulWidget {
  const _ListCard({super.key, required this.list, required this.viewModel});

  final TodoList list;
  final TodosViewModel viewModel;

  @override
  State<_ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<_ListCard> {
  bool _isExpanded = false;

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final viewModel = widget.viewModel;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ListHeader(
            list: list,
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
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(
                  context,
                  title: 'Apagar tarefa?',
                  message: '"${item.text}" deixa de aparecer.',
                ),
                onDismissed: (_) => viewModel.deleteItem(list, item),
                background: const _DismissBackground(
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: const _DismissBackground(
                  alignment: Alignment.centerRight,
                ),
                child: _TaskRow(
                  item: item,
                  index: index,
                  allowReorder: !viewModel.hideCompleted,
                  onToggle: () => viewModel.toggleItem(list, item),
                  onEdit: () => _edit(context, item),
                ),
              );
            },
          ),
        if (list.done > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.icon(
              icon: Icons.cleaning_services_outlined,
              tooltip: 'Limpar concluídas',
              onPressed: viewModel.isBusy
                  ? null
                  : () => viewModel.clearCompleted(list),
            ),
          ),
        ],
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
    required this.viewModel,
    required this.isExpanded,
    required this.onToggle,
  });

  final TodoList list;
  final TodosViewModel viewModel;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        AppButton.icon(
          icon: Icons.edit_outlined,
          tooltip: 'Renomear lista',
          onPressed: () => _rename(context),
        ),
        AppButton.icon(
          icon: Icons.delete_outline,
          tooltip: 'Eliminar lista',
          onPressed: () => _delete(context),
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
    final confirmed = await _confirmDelete(
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
    required this.index,
    required this.allowReorder,
    required this.onToggle,
    required this.onEdit,
  });

  final TodoItem item;
  final int index;
  final bool allowReorder;
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
              child: Text(
                item.text,
                style: AppTextStyles.body.copyWith(
                  color: item.done ? context.colors.muted : context.colors.ink,
                  decoration: item.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: context.colors.muted,
                ),
              ),
            ),
          ),
        ),
        if (allowReorder)
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Icon(
                Icons.drag_handle,
                size: AppSizes.iconMedium,
                color: context.colors.faint,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.icon(
          icon: Icons.send,
          tooltip: 'Adicionar tarefa',
          onPressed: _isSaving ? null : _submit,
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
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppBreakpoints.pagePadding(context),
        right: AppBreakpoints.pagePadding(context),
        top: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Listas arquivadas', style: AppTextStyles.pageTitle),
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

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.dangerSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(
        Icons.delete_outline,
        size: AppSizes.iconLarge,
        color: context.colors.dangerOnSoft,
      ),
    );
  }
}

class _ActionErrorBanner extends StatelessWidget {
  const _ActionErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.dangerSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconMedium,
            color: context.colors.dangerOnSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.small(
                context.colors,
              ).copyWith(color: context.colors.dangerOnSoft),
            ),
          ),
          AppButton.icon(
            icon: Icons.close,
            tooltip: 'Fechar aviso',
            onPressed: onDismiss,
          ),
        ],
      ),
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

/// Asks for confirmation before a destructive action.
Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          label: 'Cancelar',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          label: 'Eliminar',
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
