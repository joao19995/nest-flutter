import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nest/domain/models/person.dart';
import 'package:nest/domain/models/person_income.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/people/view_models/people_view_model.dart';

/// The household members and their salaries.
///
/// Each card opens the edit form; the app bar creates a new person. When a
/// salary change raises the money available for goals, the server reports it
/// and the screen offers to allocate the extra to a goal.
class PeopleView extends StatefulWidget {
  const PeopleView({super.key});

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView>
    with ViewModelState<PeopleView, PeopleViewModel> {
  @override
  PeopleViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return PeopleViewModel(
      peopleRepository: dependencies.peopleRepository,
      goalsRepository: dependencies.goalsRepository,
    );
  }

  @override
  void onViewModelCreated(PeopleViewModel viewModel) => viewModel.load();

  Future<void> _openForm(Person? person, List<PersonIncome> incomes) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _PersonFormSheet(
        person: person,
        initialIncomes: incomes,
        onSave: (name, percentage, months, drafts) => viewModel.savePerson(
          person: person,
          name: name,
          dailySpendingPercentage: percentage,
          emergencyFundMonths: months,
          incomes: drafts,
        ),
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    if (viewModel.pendingRaise != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => _RaiseDialog(viewModel: viewModel),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pessoas'),
        actions: [
          AppButton.icon(
            icon: Icons.add,
            tooltip: 'Nova pessoa',
            onPressed: () => _openForm(null, const []),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
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
                emptyMessage: 'Ainda não há pessoas.',
                child: _PeopleContent(viewModel: viewModel, onEdit: _openForm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeopleContent extends StatelessWidget {
  const _PeopleContent({required this.viewModel, required this.onEdit});

  final PeopleViewModel viewModel;
  final void Function(Person person, List<PersonIncome> incomes) onEdit;

  @override
  Widget build(BuildContext context) {
    final summaries = viewModel.summaries;
    final cards = <Widget>[
      for (final summary in summaries)
        _SalaryCard(
          summary: summary,
          onTap: () => onEdit(summary.person, summary.incomes),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.sm;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HouseholdIncomeHero(income: viewModel.householdIncome),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Por pessoa',
                style: AppTextStyles.navSection(context.colors),
              ),
              const SizedBox(height: AppSpacing.md),
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
        );
      },
    );
  }
}

/// The household total shown above the per-person breakdown.
///
/// A dark, gradient panel so it reads as a summary banner rather than
/// another entry in the list below.
class _HouseholdIncomeHero extends StatelessWidget {
  const _HouseholdIncomeHero({required this.income});

  final double income;

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Renda do agregado',
            style: AppTextStyles.navSection(
              context.colors,
            ).copyWith(color: AppColors.onHeroMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedAmount(
            value: income,
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.onHero),
          ),
        ],
      ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.summary, required this.onTap});

  final PersonSalarySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = summary.person;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(name: person.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  person.name,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSizes.iconMedium,
                color: context.colors.faint,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  label: 'Vencimento',
                  value: AppFormatters.currency(summary.monthlyIncome),
                  accent: context.colors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Figure(
                  label:
                      'Gasto diário '
                      '(${AppFormatters.percentage(person.dailySpendingPercentage)})',
                  value: AppFormatters.currency(summary.dailySpending),
                  accent: context.colors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small(context.colors)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.sectionHeading.copyWith(color: accent),
        ),
      ],
    );
  }
}

typedef _PersonFormSave =
    Future<String?> Function(
      String name,
      double dailySpendingPercentage,
      int emergencyFundMonths,
      List<PersonIncomeDraft> incomes,
    );

/// The create / edit form, shown as a bottom sheet.
class _PersonFormSheet extends StatefulWidget {
  const _PersonFormSheet({
    required this.person,
    required this.initialIncomes,
    required this.onSave,
  });

  final Person? person;
  final List<PersonIncome> initialIncomes;
  final _PersonFormSave onSave;

  @override
  State<_PersonFormSheet> createState() => _PersonFormSheetState();
}

class _PersonFormSheetState extends State<_PersonFormSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.person?.name ?? '',
  );
  late final TextEditingController _percentage = TextEditingController(
    text: _formatPercentage(
      widget.person?.dailySpendingPercentage ?? _defaultDailySpendingPercentage,
    ),
  );
  late final TextEditingController _emergencyMonths = TextEditingController(
    text:
        '${widget.person?.emergencyFundMonths ?? _defaultEmergencyFundMonths}',
  );
  late final List<_IncomeDraft> _incomes = [
    for (final income in widget.initialIncomes)
      _IncomeDraft(
        id: income.id,
        amount: TextEditingController(text: _formatAmount(income.amount)),
        validFrom: _parseDate(income.validFrom),
      ),
  ];
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.person != null;

  @override
  void dispose() {
    _name.dispose();
    _percentage.dispose();
    _emergencyMonths.dispose();
    for (final income in _incomes) {
      income.dispose();
    }
    super.dispose();
  }

  void _addIncome() {
    setState(() {
      _incomes.add(
        _IncomeDraft(
          amount: TextEditingController(),
          validFrom: DateTime.now(),
        ),
      );
    });
  }

  void _removeIncome(int index) {
    setState(() => _incomes.removeAt(index).dispose());
  }

  Future<void> _pickDate(int index) async {
    final current = _incomes[index].validFrom;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(_minDateYear),
      lastDate: DateTime(_maxDateYear),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _incomes[index].validFrom = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final percentage = _parseDecimal(_percentage.text);
    final months = int.tryParse(_emergencyMonths.text.trim());
    if (name.isEmpty || percentage == null || months == null || months < 0) {
      setState(
        () => _error =
            'Preenche o nome, a percentagem e os meses de fundo de emergência.',
      );
      return;
    }
    final drafts = <PersonIncomeDraft>[];
    for (final income in _incomes) {
      final amount = _parseDecimal(income.amount.text);
      if (amount == null || amount < 0) {
        setState(() => _error = 'Indica um vencimento válido em cada linha.');
        return;
      }
      drafts.add(
        PersonIncomeDraft(
          id: income.id,
          amount: amount,
          validFrom: _formatDate(income.validFrom),
        ),
      );
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final failure = await widget.onSave(name, percentage, months, drafts);
    if (!mounted) {
      return;
    }
    if (failure == null) {
      Navigator.of(context).pop(true);
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
            _isEditing ? 'Editar pessoa' : 'Nova pessoa',
            style: AppTextStyles.pageTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            autofocus: !_isEditing,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: _nameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: João',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _percentage,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Gastos variáveis',
                    suffixText: '%',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _emergencyMonths,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Fundo de emergência',
                    suffixText: 'meses',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Vencimentos', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Subsídios fixos para todos: junho e dezembro, no valor do '
            'vencimento.',
            style: AppTextStyles.helper(context.colors),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_incomes.isEmpty)
            Text(
              'Sem vencimentos registados.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            for (var index = 0; index < _incomes.length; index++) ...[
              if (index > 0) const Divider(height: AppSpacing.xl),
              _IncomeField(
                amountController: _incomes[index].amount,
                validFrom: _incomes[index].validFrom,
                onPickDate: () => _pickDate(index),
                onRemove: () => _removeIncome(index),
              ),
            ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Adicionar alteração salarial',
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              onPressed: _addIncome,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _isEditing ? 'Guardar' : 'Criar pessoa',
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// A pending income row: its amount controller and its `validFrom` date.
class _IncomeDraft {
  _IncomeDraft({this.id, required this.amount, required this.validFrom});

  final String? id;
  final TextEditingController amount;
  DateTime validFrom;

  void dispose() => amount.dispose();
}

class _IncomeField extends StatelessWidget {
  const _IncomeField({
    required this.amountController,
    required this.validFrom,
    required this.onPickDate,
    required this.onRemove,
  });

  final TextEditingController amountController;
  final DateTime validFrom;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Vencimento',
                  suffixText: '€',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.icon(
              icon: Icons.delete_outline,
              tooltip: 'Remover vencimento',
              onPressed: onRemove,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DateField(
          label: 'Válido desde',
          value: AppFormatters.shortDate(validFrom),
          onTap: onPickDate,
        ),
      ],
    );
  }
}

/// A tappable, read-only date input that opens the picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.event_outlined,
            size: AppSizes.iconMedium,
          ),
        ),
        child: Text(value, style: AppTextStyles.body),
      ),
    );
  }
}

/// Asks where to allocate the extra money a salary rise produced.
class _RaiseDialog extends StatefulWidget {
  const _RaiseDialog({required this.viewModel});

  final PeopleViewModel viewModel;

  @override
  State<_RaiseDialog> createState() => _RaiseDialogState();
}

class _RaiseDialogState extends State<_RaiseDialog> {
  String? _goalId;

  Future<void> _confirm() async {
    final goalId = _goalId;
    final raise = widget.viewModel.pendingRaise;
    final goalName = widget.viewModel.raiseGoalOptions
        .where((goal) => goal.id == goalId)
        .map((goal) => goal.name)
        .firstOrNull;
    if (goalId == null || raise == null) {
      return;
    }
    final failure = await widget.viewModel.allocateRaise(goalId);
    if (!mounted || failure != null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Nova versão a partir de ${raise.validFromMonth}: '
            '+${AppFormatters.currency(raise.extra)} no '
            '${goalName ?? 'objetivo'}.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;
        final raise = viewModel.pendingRaise;
        if (raise == null) {
          return const SizedBox.shrink();
        }
        final options = viewModel.raiseGoalOptions;
        final busy = viewModel.isAllocatingRaise;
        final monthTaken = viewModel.raiseMonthTaken;
        final error = viewModel.raiseError;
        return AlertDialog(
          title: const Text('Dinheiro extra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Há ${AppFormatters.currency(raise.extra)} a mais em '
                  '${raise.year}. Onde alocar?',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Cria uma nova versão a partir de ${raise.validFromMonth} e '
                  'recalcula o ano; meses fechados nunca mudam.',
                  style: AppTextStyles.bodyMuted(context.colors),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (viewModel.isLoadingRaiseOptions)
                  const Center(child: CircularProgressIndicator())
                else if (options.isEmpty)
                  Text(
                    'Sem objetivos disponíveis na tabela aplicável.',
                    style: AppTextStyles.bodyMuted(context.colors),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _goalId,
                    decoration: const InputDecoration(labelText: 'Objetivo'),
                    items: [
                      for (final goal in options)
                        DropdownMenuItem(
                          value: goal.id,
                          child: Text(goal.name),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(() => _goalId = value),
                  ),
                if (monthTaken) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Já existe uma versão com efeito a partir de '
                    '${raise.validFromMonth}.',
                    style: AppTextStyles.small(
                      context.colors,
                    ).copyWith(color: context.colors.over),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppErrorBanner(message: error),
                ],
              ],
            ),
          ),
          actions: [
            AppButton(
              label: 'Agora não',
              variant: AppButtonVariant.ghost,
              onPressed: busy
                  ? null
                  : () {
                      viewModel.dismissRaise();
                      Navigator.of(context).pop();
                    },
            ),
            AppButton(
              label: 'Alocar e recalcular',
              isLoading: busy,
              onPressed: (busy || _goalId == null || monthTaken)
                  ? null
                  : _confirm,
            ),
          ],
        );
      },
    );
  }
}

String _formatAmount(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

String _formatPercentage(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceAll('.', ',');

double? _parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _parseDate(String value) => DateTime.tryParse(value) ?? DateTime.now();

const int _nameMaxLength = 100;
const int _minDateYear = 2000;
const int _maxDateYear = 2100;
const double _defaultDailySpendingPercentage = 25;
const int _defaultEmergencyFundMonths = 6;
