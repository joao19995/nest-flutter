import 'package:flutter/material.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/categories/view_models/categories_view_model.dart';

/// The expense categories, fixed and variable.
///
/// Each row opens the edit sheet; swiping it away soft-deletes the category and
/// offers an undo. The eye action toggles the soft-deleted categories so they
/// can be restored.
class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView>
    with ViewModelState<CategoriesView, CategoriesViewModel> {
  @override
  CategoriesViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return CategoriesViewModel(
      categoriesRepository: dependencies.categoriesRepository,
    );
  }

  @override
  void onViewModelCreated(CategoriesViewModel viewModel) => viewModel.load();

  Future<void> _openForm(Category? category) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _CategoryFormSheet(
        initialName: category?.name ?? '',
        initialType: category?.type ?? CategoryType.variable,
        initialIconKey: category?.iconKey,
        isEditing: category != null,
        onSave: (name, type, iconKey) => category == null
            ? viewModel.createCategory(name: name, type: type, iconKey: iconKey)
            : viewModel.updateCategory(
                category,
                name: name,
                type: type,
                iconKey: iconKey,
              ),
        onDelete: category == null ? null : () => _deleteWithUndo(category),
      ),
    );
  }

  Future<void> _deleteWithUndo(Category category) async {
    final deleted = await viewModel.deleteCategory(category);
    if (!deleted || !mounted) {
      return;
    }
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      message: '"${category.name}" apagada.',
      onAction: () => viewModel.restoreCategory(category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Categorias'),
          actions: [
            AppButton.icon(
              icon: viewModel.includeInactive
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              tooltip: viewModel.includeInactive
                  ? 'Ocultar inativas'
                  : 'Mostrar inativas',
              onPressed: () =>
                  viewModel.setIncludeInactive(!viewModel.includeInactive),
            ),
            AppButton.icon(
              icon: Icons.add,
              tooltip: 'Nova categoria',
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
                emptyMessage: 'Ainda não há categorias.',
                emptyIcon: Icons.category_outlined,
                emptyActionLabel: 'Nova categoria',
                onEmptyAction: () => _openForm(null),
                child: _CategoriesContent(
                  viewModel: viewModel,
                  onEdit: _openForm,
                  onDelete: _deleteWithUndo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoriesViewModel viewModel;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    final categories = viewModel.categories;
    final actionError = viewModel.actionError;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _countLabel(categories.length),
            style: AppTextStyles.bodyMuted(context.colors),
          ),
          const SizedBox(height: AppSpacing.md),
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
                for (var index = 0; index < categories.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _CategoryRow(
                    category: categories[index],
                    onEdit: () => onEdit(categories[index]),
                    onDelete: () => onDelete(categories[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _countLabel(int count) =>
      count == 1 ? '1 categoria' : '$count categorias';
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(category.id),
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
                CategoryIcon(
                  category: category.name,
                  iconKey: category.iconKey,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: category.active
                          ? context.colors.ink
                          : context.colors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppBadge(
                  label: categoryTypeLabel(category.type).toUpperCase(),
                  style: AppBadgeStyles.outline(context.colors),
                ),
                if (!category.active) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppBadge(
                    label: 'INATIVA',
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
class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    required this.initialName,
    required this.initialType,
    required this.initialIconKey,
    required this.isEditing,
    required this.onSave,
    this.onDelete,
  });

  final String initialName;
  final CategoryType initialType;
  final String? initialIconKey;
  final bool isEditing;
  final Future<String?> Function(String name, CategoryType type, String iconKey)
  onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  CategoryType _type = CategoryType.variable;
  late String _iconKey = CategoryIcons.initialKey(
    widget.initialName,
    widget.initialIconKey,
  );
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

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
    final failure = await widget.onSave(name, _type, _iconKey);
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
      title: 'Eliminar categoria?',
      message: 'A categoria deixa de aparecer nas listas.',
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
            widget.isEditing ? 'Editar categoria' : 'Nova categoria',
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
              hintText: 'Ex.: Supermercado',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Tipo', style: AppTextStyles.label(context.colors)),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<CategoryType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: CategoryType.fixed,
                label: Text('Fixa'),
                icon: Icon(Icons.lock_outline),
              ),
              ButtonSegment(
                value: CategoryType.variable,
                label: Text('Variável'),
                icon: Icon(Icons.tune),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selection) =>
                setState(() => _type = selection.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ícone', style: AppTextStyles.label(context.colors)),
          const SizedBox(height: AppSpacing.sm),
          CategoryIconPicker(
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
                label: widget.isEditing ? 'Guardar' : 'Criar categoria',
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: enabled ? _save : null,
              );
            },
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Eliminar categoria',
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

/// The display label for a [CategoryType].
String categoryTypeLabel(CategoryType type) => switch (type) {
  CategoryType.fixed => 'Fixa',
  CategoryType.variable => 'Variável',
};

const int _nameMaxLength = 100;
