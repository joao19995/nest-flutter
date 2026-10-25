import 'package:flutter/material.dart';
import 'package:nest/domain/failures/api_failure.dart';
import 'package:nest/domain/models/account.dart';
import 'package:nest/domain/models/category.dart';
import 'package:nest/domain/models/category_template.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/category_templates/view_models/category_templates_view_model.dart';

/// The monthly expense templates: list the versions and create or edit one.
///
/// A version is keyed by the first month it applies to; new versions only move
/// forward. Editing a version replaces its active rows (removed rows are kept
/// as inactive history).
class CategoryTemplatesView extends StatefulWidget {
  const CategoryTemplatesView({super.key});

  @override
  State<CategoryTemplatesView> createState() => _CategoryTemplatesViewState();
}

class _CategoryTemplatesViewState extends State<CategoryTemplatesView>
    with ViewModelState<CategoryTemplatesView, CategoryTemplatesViewModel> {
  @override
  CategoryTemplatesViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return CategoryTemplatesViewModel(
      categoryTemplatesRepository: dependencies.categoryTemplatesRepository,
      categoriesRepository: dependencies.categoriesRepository,
      accountsRepository: dependencies.accountsRepository,
    );
  }

  @override
  void onViewModelCreated(CategoryTemplatesViewModel viewModel) =>
      viewModel.load();

  Future<void> _openForm(CategoryTemplate? template) async {
    final drafts = <CategoryTemplateEntryDraft>[];
    String? defaultAccountId;
    var validFrom = MonthKey.current();
    if (template == null) {
      try {
        final applicable = await viewModel.applicableFor(validFrom);
        defaultAccountId = applicable.defaultAccountId;
        for (final entry
            in applicable.template?.entries ??
                const <CategoryTemplateEntry>[]) {
          if (entry.active) {
            drafts.add(_draftOf(entry));
          }
        }
      } on ApiFailure {
        // Seeding is a convenience; an empty table is still editable.
      }
    } else {
      validFrom = template.validFrom;
      for (final entry in template.entries) {
        if (entry.active) {
          drafts.add(_draftOf(entry));
        }
      }
    }
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _CategoryTemplateFormSheet(
        template: template,
        validFrom: validFrom,
        initialDrafts: drafts,
        defaultAccountId: defaultAccountId,
        categories: viewModel.categories,
        accounts: viewModel.accounts,
        onSave: (month, entries) => template == null
            ? viewModel.createVersion(validFrom: month, entries: entries)
            : viewModel.updateVersion(template, entries),
      ),
    );
  }

  static CategoryTemplateEntryDraft _draftOf(CategoryTemplateEntry entry) =>
      CategoryTemplateEntryDraft(
        categoryId: entry.categoryId,
        accountId: entry.accountId,
        expectedAmount: entry.expectedAmount,
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Distribuição'),
          actions: [
            AppButton.icon(
              icon: Icons.add,
              tooltip: 'Nova versão',
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
                emptyMessage: 'Ainda não há distribuição.',
                emptyIcon: Icons.pie_chart_outline,
                child: TemplateVersionsList<CategoryTemplate>(
                  templates: viewModel.templates,
                  errorMessage: viewModel.actionError,
                  onDismissError: viewModel.clearActionError,
                  monthLabel: (template) =>
                      AppFormatters.monthKeyTitle(template.validFrom),
                  subtitle: (template) {
                    final count = template.entries
                        .where((entry) => entry.active)
                        .length;
                    return '$count '
                        '${count == 1 ? 'categoria' : 'categorias'}';
                  },
                  onTap: _openForm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _CategoryTemplateSave =
    Future<String?> Function(
      String validFrom,
      List<CategoryTemplateEntryDraft> entries,
    );

/// The create / edit form, shown as a bottom sheet.
class _CategoryTemplateFormSheet extends StatefulWidget {
  const _CategoryTemplateFormSheet({
    required this.template,
    required this.validFrom,
    required this.initialDrafts,
    required this.defaultAccountId,
    required this.categories,
    required this.accounts,
    required this.onSave,
  });

  final CategoryTemplate? template;
  final String validFrom;
  final List<CategoryTemplateEntryDraft> initialDrafts;
  final String? defaultAccountId;
  final List<Category> categories;
  final List<Account> accounts;
  final _CategoryTemplateSave onSave;

  @override
  State<_CategoryTemplateFormSheet> createState() =>
      _CategoryTemplateFormSheetState();
}

class _CategoryTemplateFormSheetState
    extends State<_CategoryTemplateFormSheet> {
  String _validFrom = MonthKey.current();
  late final List<_RowDraft> _rows = [
    for (final draft in widget.initialDrafts)
      _RowDraft(
        categoryId: draft.categoryId,
        accountId: draft.accountId,
        amount: TextEditingController(
          text: AppFormatters.inputAmount(draft.expectedAmount),
        ),
      ),
  ];
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _validFrom = widget.validFrom;
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  List<Category> get _availableCategories {
    final used = {for (final row in _rows) row.categoryId};
    return [
      for (final category in widget.categories)
        if (category.active && !used.contains(category.id)) category,
    ];
  }

  String get _newRowAccountId {
    final preferred = widget.defaultAccountId;
    if (preferred != null &&
        widget.accounts.any((account) => account.id == preferred)) {
      return preferred;
    }
    for (final account in widget.accounts) {
      if (account.active) {
        return account.id;
      }
    }
    return widget.accounts.isEmpty ? '' : widget.accounts.first.id;
  }

  void _addRow(Category category) {
    setState(() {
      _rows.add(
        _RowDraft(
          categoryId: category.id,
          accountId: _newRowAccountId,
          amount: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
  }

  Future<void> _save() async {
    if (_rows.isEmpty) {
      setState(() => _error = 'Adiciona pelo menos uma categoria.');
      return;
    }
    final entries = <CategoryTemplateEntryDraft>[];
    for (final row in _rows) {
      final amount = AppFormatters.parseDecimal(row.amount.text);
      if (amount == null || amount < 0) {
        setState(() => _error = 'Indica um valor válido em cada linha.');
        return;
      }
      entries.add(
        CategoryTemplateEntryDraft(
          categoryId: row.categoryId,
          accountId: row.accountId,
          expectedAmount: amount,
        ),
      );
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final failure = await widget.onSave(_validFrom, entries);
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
    final available = _availableCategories;
    return BottomSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing ? 'Editar distribuição' : 'Nova versão',
                  style: AppTextStyles.pageTitle,
                ),
              ),
              AppButton.icon(
                icon: Icons.close,
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isEditing)
            Text(
              'Aplicável a partir de ${AppFormatters.monthKeyTitle(_validFrom)}',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            MonthField(
              value: _validFrom,
              onChanged: (value) => setState(() => _validFrom = value),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (_rows.isEmpty)
            Text(
              'Sem categorias no template.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            for (var index = 0; index < _rows.length; index++) ...[
              if (index > 0) const Divider(height: AppSpacing.xl),
              _RowFields(
                key: ValueKey('template-row-$index'),
                categories: widget.categories,
                accounts: widget.accounts,
                categoryId: _rows[index].categoryId,
                accountId: _rows[index].accountId,
                amount: _rows[index].amount,
                onCategory: (value) =>
                    setState(() => _rows[index].categoryId = value),
                onAccount: (value) =>
                    setState(() => _rows[index].accountId = value),
                onRemove: () => _removeRow(index),
              ),
            ],
          if (available.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Adicionar categoria',
              style: AppTextStyles.label(context.colors),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in available)
                  ActionChip(
                    label: Text(category.name),
                    onPressed: _isSaving ? null : () => _addRow(category),
                  ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _isEditing ? 'Guardar' : 'Criar versão',
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// A pending row: its category, account and amount.
class _RowDraft {
  _RowDraft({
    required this.categoryId,
    required this.accountId,
    required this.amount,
  });

  String categoryId;
  String accountId;
  final TextEditingController amount;

  void dispose() => amount.dispose();
}

class _RowFields extends StatelessWidget {
  const _RowFields({
    super.key,
    required this.categories,
    required this.accounts,
    required this.categoryId,
    required this.accountId,
    required this.amount,
    required this.onCategory,
    required this.onAccount,
    required this.onRemove,
  });

  final List<Category> categories;
  final List<Account> accounts;
  final String categoryId;
  final String accountId;
  final TextEditingController amount;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onAccount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('category-$categoryId'),
                initialValue: categoryId.isEmpty ? null : categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(_categoryLabel(category)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onCategory(value);
                  }
                },
              ),
            ),
            AppButton.icon(
              icon: Icons.delete_outline,
              tooltip: 'Remover categoria',
              onPressed: onRemove,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('account-$accountId'),
                initialValue: accountId.isEmpty ? null : accountId,
                decoration: const InputDecoration(labelText: 'Conta'),
                items: [
                  for (final account in accounts)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(_accountLabel(account)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onAccount(value);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor esperado',
                  suffixText: '€',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _categoryLabel(Category category) =>
    category.active ? category.name : '${category.name} (inativa)';

String _accountLabel(Account account) =>
    account.active ? account.name : '${account.name} (inativa)';
