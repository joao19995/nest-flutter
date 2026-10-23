import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal.dart';
import 'package:nest/domain/models/goal_template.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/goal_badges.dart';
import 'package:nest/ui/features/goals/view_models/goal_templates_view_model.dart';

/// The annual goal distribution: list the versions and create or edit one.
///
/// Every version's entries must total 100%; the server recalculates the year
/// when a version is saved.
class GoalTemplatesView extends StatefulWidget {
  const GoalTemplatesView({super.key});

  @override
  State<GoalTemplatesView> createState() => _GoalTemplatesViewState();
}

class _GoalTemplatesViewState extends State<GoalTemplatesView>
    with ViewModelState<GoalTemplatesView, GoalTemplatesViewModel> {
  @override
  GoalTemplatesViewModel createViewModel() => GoalTemplatesViewModel(
    goalsRepository: DependenciesScope.of(context).goalsRepository,
  );

  @override
  void onViewModelCreated(GoalTemplatesViewModel viewModel) => viewModel.load();

  Future<void> _openForm(GoalTemplate? template) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _GoalTemplateFormSheet(
        template: template,
        goals: viewModel.goals,
        onSave: (validFrom, entries) => template == null
            ? viewModel.createVersion(validFrom: validFrom, entries: entries)
            : viewModel.updateVersion(template, entries: entries),
      ),
    );
  }

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
                emptyMessage: 'Ainda não há versões.',
                emptyIcon: Icons.pie_chart_outline,
                child: TemplateVersionsList<GoalTemplate>(
                  templates: viewModel.templates,
                  errorMessage: viewModel.actionError,
                  onDismissError: viewModel.clearActionError,
                  monthLabel: (template) =>
                      AppFormatters.monthKeyTitle(template.validFrom),
                  subtitle: (template) {
                    final count = template.entries.length;
                    return '$count ${count == 1 ? 'objetivo' : 'objetivos'} · '
                        '${AppFormatters.currency(template.annualTotal)}';
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

typedef _GoalTemplateSave =
    Future<String?> Function(String validFrom, List<GoalTemplateEntry> entries);

/// The create / edit form, shown as a bottom sheet.
class _GoalTemplateFormSheet extends StatefulWidget {
  const _GoalTemplateFormSheet({
    required this.template,
    required this.goals,
    required this.onSave,
  });

  final GoalTemplate? template;
  final List<Goal> goals;
  final _GoalTemplateSave onSave;

  @override
  State<_GoalTemplateFormSheet> createState() => _GoalTemplateFormSheetState();
}

class _GoalTemplateFormSheetState extends State<_GoalTemplateFormSheet> {
  String _validFrom = MonthKey.current();
  late final List<_EntryDraft> _rows = [
    for (final entry in widget.template?.entries ?? const <GoalTemplateEntry>[])
      _EntryDraft.fromEntry(entry),
  ];
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _validFrom = widget.template?.validFrom ?? MonthKey.current();
    for (final row in _rows) {
      row.budget.addListener(_onBudgetChanged);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.budget.removeListener(_onBudgetChanged);
      row.dispose();
    }
    super.dispose();
  }

  void _onBudgetChanged() {
    _recalculatePercentages();
    setState(() {});
  }

  /// Derives every percentage from the entered budgets, so the table still
  /// totals 100% when the user fills only the values.
  void _recalculatePercentages() {
    final budgets = [
      for (final row in _rows) AppFormatters.parseDecimal(row.budget.text) ?? 0,
    ];
    final total = budgets.fold<double>(0, (sum, value) => sum + value);
    final percentages = _percentagesForBudgets(budgets, total);
    for (var index = 0; index < _rows.length; index++) {
      final text = AppFormatters.inputNumber(percentages[index]);
      if (_rows[index].percentage.text != text) {
        _rows[index].percentage.text = text;
      }
    }
  }

  /// Percentages rounded to two decimals whose sum is exactly 100. The
  /// rounding residual goes to the largest budget so the table stays valid.
  static List<double> _percentagesForBudgets(
    List<double> budgets,
    double total,
  ) {
    if (total <= 0) {
      return List<double>.filled(budgets.length, 0);
    }
    final percentages = [
      for (final budget in budgets) (budget / total * 100 * 100).round() / 100,
    ];
    final sum = percentages.fold<double>(0, (value, item) => value + item);
    final missing = 100 - sum;
    if (missing == 0) {
      return percentages;
    }
    var largest = 0;
    for (var index = 1; index < budgets.length; index++) {
      if (budgets[index] > budgets[largest]) {
        largest = index;
      }
    }
    percentages[largest] =
        ((percentages[largest] + missing) * 100).round() / 100;
    return percentages;
  }

  List<Goal> get _availableGoals {
    final used = {for (final row in _rows) row.goalId};
    return [
      for (final goal in widget.goals)
        if (!used.contains(goal.id)) goal,
    ];
  }

  double get _totalPercentage => _rows.fold<double>(
    0,
    (total, row) =>
        total + (AppFormatters.parseDecimal(row.percentage.text) ?? 0),
  );

  String _goalName(String goalId) {
    for (final goal in widget.goals) {
      if (goal.id == goalId) {
        return goal.name;
      }
    }
    return 'Objetivo';
  }

  void _addRow(Goal goal) {
    final row = _EntryDraft(
      goalId: goal.id,
      percentage: TextEditingController(text: '0'),
      budget: TextEditingController(text: '0'),
      timeline: GoalTimeline.annual,
      priority: GoalPriority.niceToHave,
      notes: TextEditingController(),
    );
    row.budget.addListener(_onBudgetChanged);
    setState(() => _rows.add(row));
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index).dispose();
      _recalculatePercentages();
    });
  }

  Future<void> _save() async {
    if (_rows.isEmpty) {
      setState(() => _error = 'Indica pelo menos um objetivo na tabela.');
      return;
    }
    final entries = <GoalTemplateEntry>[];
    for (final row in _rows) {
      final percentage = AppFormatters.parseDecimal(row.percentage.text);
      final budget = AppFormatters.parseDecimal(row.budget.text);
      if (percentage == null ||
          percentage < 0 ||
          percentage > 100 ||
          budget == null ||
          budget < 0) {
        setState(
          () => _error =
              'Cada percentagem tem de estar entre 0 e 100 e cada orçamento '
              'não pode ser negativo.',
        );
        return;
      }
      entries.add(
        GoalTemplateEntry(
          goalId: row.goalId,
          percentage: percentage,
          budget: budget,
          timeline: row.timeline,
          priority: row.priority,
          notes: row.notes.text.trim(),
        ),
      );
    }
    if ((_totalPercentage - 100).abs() >= 0.01) {
      setState(
        () => _error =
            'A tabela tem de somar 100% '
            '(atual: ${_totalPercentage.toStringAsFixed(2)}%).',
      );
      return;
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
    final total = _totalPercentage;
    final totalValid = _rows.isNotEmpty && (total - 100).abs() < 0.01;
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
          Row(
            children: [
              const Expanded(
                child: Text('Total', style: AppTextStyles.sectionHeading),
              ),
              Text(
                '${total.toStringAsFixed(2)}%',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: totalValid
                      ? context.colors.primaryDark
                      : context.colors.over,
                ),
              ),
              if (!totalValid) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(tem de dar 100%)',
                  style: AppTextStyles.small(context.colors),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_rows.isEmpty)
            Text(
              'Sem objetivos na tabela.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            for (var index = 0; index < _rows.length; index++) ...[
              if (index > 0) const Divider(height: AppSpacing.xl),
              _EntryRow(
                key: ValueKey(_rows[index].goalId),
                goalName: _goalName(_rows[index].goalId),
                percentage: _rows[index].percentage,
                budget: _rows[index].budget,
                notes: _rows[index].notes,
                timeline: _rows[index].timeline,
                priority: _rows[index].priority,
                onTimeline: (value) =>
                    setState(() => _rows[index].timeline = value),
                onPriority: (value) =>
                    setState(() => _rows[index].priority = value),
                onRemove: () => _removeRow(index),
              ),
            ],
          if (_availableGoals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Adicionar objetivo',
              style: AppTextStyles.label(context.colors),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final goal in _availableGoals)
                  ActionChip(
                    label: Text(goal.name),
                    onPressed: _isSaving ? null : () => _addRow(goal),
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

/// A pending table row: its goal and editable fields.
class _EntryDraft {
  _EntryDraft({
    required this.goalId,
    required this.percentage,
    required this.budget,
    required this.timeline,
    required this.priority,
    required this.notes,
  });

  factory _EntryDraft.fromEntry(GoalTemplateEntry entry) => _EntryDraft(
    goalId: entry.goalId,
    percentage: TextEditingController(
      text: AppFormatters.inputNumber(entry.percentage),
    ),
    budget: TextEditingController(
      text: AppFormatters.inputNumber(entry.budget),
    ),
    timeline: entry.timeline,
    priority: entry.priority,
    notes: TextEditingController(text: entry.notes),
  );

  final String goalId;
  final TextEditingController percentage;
  final TextEditingController budget;
  GoalTimeline timeline;
  GoalPriority priority;
  final TextEditingController notes;

  void dispose() {
    percentage.dispose();
    budget.dispose();
    notes.dispose();
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    super.key,
    required this.goalName,
    required this.percentage,
    required this.budget,
    required this.notes,
    required this.timeline,
    required this.priority,
    required this.onTimeline,
    required this.onPriority,
    required this.onRemove,
  });

  final String goalName;
  final TextEditingController percentage;
  final TextEditingController budget;
  final TextEditingController notes;
  final GoalTimeline timeline;
  final GoalPriority priority;
  final ValueChanged<GoalTimeline> onTimeline;
  final ValueChanged<GoalPriority> onPriority;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goalName,
                style: AppTextStyles.sectionHeading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppButton.icon(
              icon: Icons.delete_outline,
              tooltip: 'Remover objetivo',
              onPressed: onRemove,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GoalMetaChips(timeline: timeline, priority: priority),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: percentage,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Percentagem',
                  suffixText: '%',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: budget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Orçamento',
                  suffixText: '€',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<GoalTimeline>(
                key: ValueKey('timeline-$goalName-$timeline'),
                initialValue: timeline,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Timeline'),
                items: [
                  for (final value in GoalTimeline.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onTimeline(value);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<GoalPriority>(
                key: ValueKey('priority-$goalName-$priority'),
                initialValue: priority,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Importância'),
                items: [
                  for (final value in GoalPriority.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onPriority(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: notes,
          textCapitalization: TextCapitalization.sentences,
          maxLength: _notesMaxLength,
          decoration: const InputDecoration(
            labelText: 'Notas',
            counterText: '',
          ),
        ),
      ],
    );
  }
}

const int _notesMaxLength = 2000;
