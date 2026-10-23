import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/goal_icons.dart';
import 'package:nest/ui/features/goals/view_models/goals_catalog_view_model.dart';

/// The goals catalogue: create, rename and deactivate/restore goals.
///
/// Deactivating is a soft delete and reversible; a goal still funded by a
/// template version for an open month cannot be deactivated.
class GoalsCatalogView extends StatefulWidget {
  const GoalsCatalogView({super.key});

  @override
  State<GoalsCatalogView> createState() => _GoalsCatalogViewState();
}

class _GoalsCatalogViewState extends State<GoalsCatalogView>
    with ViewModelState<GoalsCatalogView, GoalsCatalogViewModel> {
  @override
  GoalsCatalogViewModel createViewModel() => GoalsCatalogViewModel(
    goalsRepository: DependenciesScope.of(context).goalsRepository,
  );

  @override
  void onViewModelCreated(GoalsCatalogViewModel viewModel) => viewModel.load();

  Future<void> _openForm(Goal? goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _GoalFormSheet(
        initialName: goal?.name ?? '',
        initialIconKey: goal?.iconKey,
        isEditing: goal != null,
        onSave: (name, iconKey) => goal == null
            ? viewModel.createGoal(name, iconKey: iconKey)
            : viewModel.updateGoal(goal, name, iconKey: iconKey),
        onDelete: goal == null ? null : () => _deactivateWithUndo(goal),
      ),
    );
  }

  Future<void> _deactivateWithUndo(Goal goal) async {
    final failure = await viewModel.deleteGoal(goal);
    if (!mounted || failure != null) {
      return;
    }
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      message: '"${goal.name}" desativado.',
      onAction: () => viewModel.restoreGoal(goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Catálogo de objetivos'),
          actions: [
            AppButton.icon(
              icon: viewModel.includeInactive
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              tooltip: viewModel.includeInactive
                  ? 'Ocultar inativos'
                  : 'Mostrar inativos',
              onPressed: () =>
                  viewModel.setIncludeInactive(!viewModel.includeInactive),
            ),
            AppButton.icon(
              icon: Icons.add,
              tooltip: 'Novo objetivo',
              onPressed: () => _openForm(null),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: AsyncView(
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                isEmpty: viewModel.isEmpty,
                onRetry: viewModel.load,
                emptyMessage: 'Ainda não há objetivos.',
                emptyIcon: Icons.flag_outlined,
                emptyActionLabel: 'Novo objetivo',
                onEmptyAction: () => _openForm(null),
                child: _CatalogContent(
                  viewModel: viewModel,
                  onEdit: _openForm,
                  onDelete: _deactivateWithUndo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final GoalsCatalogViewModel viewModel;
  final ValueChanged<Goal> onEdit;
  final ValueChanged<Goal> onDelete;

  @override
  Widget build(BuildContext context) {
    final goals = viewModel.goals;
    final actionError = viewModel.actionError;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (actionError != null) ...[
            AppErrorBanner(
              message: actionError,
              onDismiss: viewModel.clearActionError,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            padding: EdgeInsets.symmetric(
              horizontal: AppBreakpoints.cardPadding(context),
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (var index = 0; index < goals.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _GoalRow(
                    goal: goals[index],
                    onEdit: () => onEdit(goals[index]),
                    onDelete: () => onDelete(goals[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: const DismissBackground(alignment: Alignment.centerLeft),
      secondaryBackground: const DismissBackground(
        alignment: Alignment.centerRight,
      ),
      child: Material(
        color: context.colors.surface,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                GoalIcon(name: goal.name, iconKey: goal.iconKey),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    goal.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: goal.active
                          ? context.colors.ink
                          : context.colors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!goal.active) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppBadge(
                    label: 'INATIVO',
                    style: AppBadgeStyles.destructive(context.colors),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right,
                  size: AppSizes.iconMedium,
                  color: context.colors.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The create / edit form, shown as a bottom sheet.
class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({
    required this.initialName,
    required this.initialIconKey,
    required this.isEditing,
    required this.onSave,
    this.onDelete,
  });

  final String initialName;
  final String? initialIconKey;
  final bool isEditing;
  final Future<String?> Function(String name, String iconKey) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late String _iconKey = GoalIcons.resolveKey(widget.initialIconKey);
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final failure = await widget.onSave(name, _iconKey);
    if (!mounted) {
      return;
    }
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = failure;
      });
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Desativar objetivo?',
      message: 'O objetivo deixa de aparecer nas listas.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    Navigator.of(context).pop();
    await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return BottomSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? 'Editar objetivo' : 'Novo objetivo',
            style: AppTextStyles.pageTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            autofocus: !widget.isEditing,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            maxLength: _nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Férias',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ícone', style: AppTextStyles.label(context.colors)),
          const SizedBox(height: AppSpacing.sm),
          GoalIconPicker(
            selectedKey: _iconKey,
            onChanged: (key) => setState(() => _iconKey = key),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) {
              final enabled = _name.text.trim().isNotEmpty;
              return AppButton(
                label: widget.isEditing ? 'Guardar' : 'Criar objetivo',
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: enabled ? _save : null,
              );
            },
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Desativar objetivo',
              icon: Icons.delete_outline,
              variant: AppButtonVariant.ghost,
              isFullWidth: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

const int _nameMaxLength = 100;
