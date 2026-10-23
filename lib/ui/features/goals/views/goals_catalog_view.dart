import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
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
        isEditing: goal != null,
        onSave: (name) => goal == null
            ? viewModel.createGoal(name)
            : viewModel.updateGoal(goal, name),
      ),
    );
  }

  Future<void> _toggle(Goal goal, bool active) async {
    final failure = active
        ? await viewModel.restoreGoal(goal)
        : await viewModel.deleteGoal(goal);
    if (!mounted || failure != null || active) {
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
                  onToggle: _toggle,
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
    required this.onToggle,
  });

  final GoalsCatalogViewModel viewModel;
  final ValueChanged<Goal> onEdit;
  final void Function(Goal goal, bool active) onToggle;

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
                    onToggle: (value) => onToggle(goals[index], value),
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
    required this.onToggle,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: AppRadius.smAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
            ),
          ),
          Switch(value: goal.active, onChanged: onToggle),
        ],
      ),
    );
  }
}

/// The create / edit form, shown as a bottom sheet.
class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({
    required this.initialName,
    required this.isEditing,
    required this.onSave,
  });

  final String initialName;
  final bool isEditing;
  final Future<String?> Function(String name) onSave;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
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
    final failure = await widget.onSave(name);
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
        ],
      ),
    );
  }
}

const int _nameMaxLength = 100;
