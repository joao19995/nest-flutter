import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal_close_preview.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/month_transfers.dart';
import 'package:nest/domain/models/monthly_plan.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';
import 'package:nest/ui/features/finances/view_models/close_month_wizard_view_model.dart';
import 'package:nest/ui/features/finances/views/month_transfers_summary.dart';
import 'package:nest/ui/features/goals/goal_icons.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';

/// The month-end assistant: review and close Despesas, then Objetivos, then
/// see the combined final transfers.
class CloseMonthWizardView extends StatefulWidget {
  const CloseMonthWizardView({
    super.key,
    required this.month,
    this.startStep = 0,
  }) : assert(startStep == 0 || startStep == 1);

  /// The month to close, formatted `YYYY-MM`.
  final String month;

  /// The step to open on. Objetivos can jump straight to its review when the
  /// expenses month is already closed; otherwise the expenses step wins.
  final int startStep;

  @override
  State<CloseMonthWizardView> createState() => _CloseMonthWizardViewState();
}

class _CloseMonthWizardViewState extends State<CloseMonthWizardView>
    with ViewModelState<CloseMonthWizardView, CloseMonthWizardViewModel> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _step = widget.startStep;
  }

  @override
  CloseMonthWizardViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return CloseMonthWizardViewModel(
      expensesRepository: dependencies.expensesRepository,
      goalsRepository: dependencies.goalsRepository,
      month: widget.month,
    );
  }

  @override
  void onViewModelCreated(CloseMonthWizardViewModel viewModel) =>
      viewModel.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fechar ${AppFormatters.monthName(widget.month)}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  final effectiveStep = _step > 0 && !viewModel.expensesClosed
                      ? 0
                      : _step;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WizardSteps(
                        current: effectiveStep,
                        expensesDone: viewModel.expensesClosed,
                        goalsDone: viewModel.goalsClosed,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      switch (effectiveStep) {
                        0 => _ExpensesStep(
                          viewModel: viewModel,
                          onNext: () {
                            if (mounted) {
                              setState(() => _step = 1);
                            }
                          },
                        ),
                        1 => _GoalsStep(
                          viewModel: viewModel,
                          onNext: () {
                            if (mounted) {
                              setState(() => _step = 2);
                            }
                          },
                        ),
                        _ => _FinalStep(
                          viewModel: viewModel,
                          onDone: () {
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      },
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WizardSteps extends StatelessWidget {
  const _WizardSteps({
    required this.current,
    required this.expensesDone,
    required this.goalsDone,
  });

  final int current;
  final bool expensesDone;
  final bool goalsDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StepBadge(
            index: 1,
            label: 'Despesas',
            active: current == 0,
            done: expensesDone,
          ),
        ),
        Expanded(
          child: _StepBadge(
            index: 2,
            label: 'Objetivos',
            active: current == 1,
            done: goalsDone,
          ),
        ),
        Expanded(
          child: _StepBadge(
            index: 3,
            label: 'Transferências',
            active: current == 2,
            done: false,
          ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highlighted = active || done;
    return Column(
      children: [
        Container(
          width: AppSizes.buttonHeight,
          height: AppSizes.buttonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted ? colors.primary : colors.lineSoft,
            shape: BoxShape.circle,
          ),
          child: done
              ? Icon(
                  Icons.check,
                  size: AppSizes.iconMedium,
                  color: colors.surface,
                )
              : Text(
                  '$index',
                  style: AppTextStyles.label(colors).copyWith(
                    color: highlighted ? colors.surface : colors.muted,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: active
              ? AppTextStyles.label(colors).copyWith(color: colors.ink)
              : AppTextStyles.small(colors),
        ),
      ],
    );
  }
}

class _ExpensesStep extends StatelessWidget {
  const _ExpensesStep({required this.viewModel, required this.onNext});

  final CloseMonthWizardViewModel viewModel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel.expenses;
    final plan = vm.plan;
    if (vm.isLoading) {
      return const _StepLoading();
    }
    final error = vm.errorMessage;
    if (error != null) {
      return _StepError(message: error, onRetry: viewModel.retryExpenses);
    }
    if (plan == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepTitle(
            title: 'Despesas',
            subtitle: 'Cria o mês de despesas para começar.',
          ),
          const SizedBox(height: AppSpacing.md),
          CreateMonthCard(
            description:
                'Ao criar, copia-se o template aplicável a '
                '${AppFormatters.monthName(viewModel.month)}.',
            isBusy: vm.isBusy,
            errorMessage: vm.actionError,
            onCreate: viewModel.createExpenses,
          ),
        ],
      );
    }
    final actionError = vm.actionError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle(
          title: 'Despesas',
          subtitle: plan.closed
              ? 'Este mês já está fechado.'
              : 'Confirma o real e as transferências antes de fechar.',
        ),
        if (actionError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppErrorBanner(message: actionError),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!plan.closed) ...[
          AppButton(
            label: 'Editar despesas',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => _edit(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _ExpenseReview(plan: plan),
        const SizedBox(height: AppSpacing.lg),
        _SettlementSection(
          settlement: viewModel.expenseSettlement,
          isLoading: vm.isPreviewLoading,
          error: vm.previewError,
          closed: plan.closed,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (plan.closed)
          AppButton(
            label: 'Continuar',
            icon: Icons.arrow_forward,
            isFullWidth: true,
            onPressed: onNext,
          )
        else
          AppButton(
            label: 'Fechar despesas',
            icon: Icons.lock_outlined,
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
            isLoading: vm.isBusy,
            onPressed: vm.isBusy || vm.isPreviewLoading
                ? null
                : () => _close(context),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MonthDetailView(month: viewModel.month),
      ),
    );
    if (context.mounted) {
      await viewModel.retryExpenses();
    }
  }

  Future<void> _close(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title:
          'Fechar despesas de '
          '${AppFormatters.monthName(viewModel.month)}?',
      message: 'As contribuições são calculadas e o mês fica imutável.',
      confirmLabel: 'Fechar despesas',
    );
    if (!confirmed) {
      return;
    }
    final ok = await viewModel.closeExpenses();
    if (ok) {
      onNext();
    }
  }
}

class _GoalsStep extends StatelessWidget {
  const _GoalsStep({required this.viewModel, required this.onNext});

  final CloseMonthWizardViewModel viewModel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel.goals;
    final plan = vm.plan;
    if (vm.isLoading) {
      return const _StepLoading();
    }
    final error = vm.errorMessage;
    if (error != null) {
      return _StepError(message: error, onRetry: viewModel.retryGoals);
    }
    if (plan == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepTitle(
            title: 'Objetivos',
            subtitle: 'Cria o mês de objetivos para continuar.',
          ),
          const SizedBox(height: AppSpacing.md),
          CreateMonthCard(
            description:
                'Ao criar, copia-se a distribuição aplicável a '
                '${AppFormatters.monthName(viewModel.month)}.',
            isBusy: vm.isBusy,
            errorMessage: vm.actionError,
            onCreate: viewModel.createGoals,
          ),
        ],
      );
    }
    final actionError = vm.actionError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle(
          title: 'Objetivos',
          subtitle: plan.closed
              ? 'Este mês já está fechado.'
              : 'Confirma o reservado e as transferências antes de fechar.',
        ),
        if (actionError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppErrorBanner(message: actionError),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!plan.closed) ...[
          AppButton(
            label: 'Editar objetivos',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => _edit(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _GoalReview(viewModel: viewModel),
        const SizedBox(height: AppSpacing.lg),
        _GoalTransfersSection(
          transfers: viewModel.goalTransfers,
          iconKeyByGoal: vm.iconKeyByGoal,
          reserved: vm.reserved,
          hasIncome:
              (vm.funding?.incomeNormal ?? 0) + (vm.funding?.bonus ?? 0) >
              0.005,
          isLoading: vm.isPreviewLoading,
          error: vm.previewError,
          closed: plan.closed,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (plan.closed)
          AppButton(
            label: 'Continuar',
            icon: Icons.arrow_forward,
            isFullWidth: true,
            onPressed: onNext,
          )
        else
          AppButton(
            label: 'Fechar objetivos',
            icon: Icons.lock_outlined,
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
            isLoading: vm.isBusy,
            onPressed: vm.isBusy || vm.isPreviewLoading
                ? null
                : () => _close(context),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalMonthDetailView(month: viewModel.month),
      ),
    );
    if (context.mounted) {
      await viewModel.retryGoals();
    }
  }

  Future<void> _close(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Guardar e fechar ${AppFormatters.monthName(viewModel.month)}?',
      message: 'O planeado e o reservado ficam imutáveis.',
      confirmLabel: 'Guardar e fechar',
    );
    if (!confirmed) {
      return;
    }
    final ok = await viewModel.closeGoals();
    if (ok) {
      onNext();
    }
  }
}

class _FinalStep extends StatelessWidget {
  const _FinalStep({required this.viewModel, required this.onDone});

  final CloseMonthWizardViewModel viewModel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final transfers = MonthTransfers.fromMonths(
      month: viewModel.month,
      expenses: viewModel.expenses.plan,
      goals: viewModel.goals.view,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle(
          title: 'Transferências finais',
          subtitle: transfers.closed
              ? 'Os dois meses ficaram fechados.'
              : 'Ainda há um mês por fechar.',
        ),
        const SizedBox(height: AppSpacing.md),
        MonthTransfersSummary(
          transfers: transfers,
          iconKeyByGoal: viewModel.goals.iconKeyByGoal,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Concluir',
          icon: Icons.check,
          isFullWidth: true,
          onPressed: onDone,
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.bodyMuted(context.colors)),
      ],
    );
  }
}

class _StepLoading extends StatelessWidget {
  const _StepLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StepError extends StatelessWidget {
  const _StepError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppErrorBanner(message: message),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Tentar de novo',
            variant: AppButtonVariant.ghost,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}

class _ExpenseReview extends StatelessWidget {
  const _ExpenseReview({required this.plan});

  static const int _topCount = 3;
  static const double _epsilon = 0.005;

  final MonthlyPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final diff = plan.actual - plan.planned;
    final deviations =
        plan.entries
            .where((entry) => (entry.actual - entry.planned).abs() > _epsilon)
            .toList(growable: false)
          ..sort(
            (a, b) => (b.actual - b.planned).abs().compareTo(
              (a.actual - a.planned).abs(),
            ),
          );
    final top = deviations.take(_topCount).toList(growable: false);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumo', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.md),
          _WizardSummaryRow(
            label: 'Planeado',
            value: AppFormatters.currency(plan.planned),
            color: colors.ink,
          ),
          _WizardSummaryRow(
            label: 'Real',
            value: AppFormatters.currency(plan.actual),
            color: colors.ink,
          ),
          _WizardSummaryRow(
            label: 'Desvio',
            value: AppFormatters.signedCurrency(diff),
            color: plan.isOver ? colors.over : colors.primary,
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Maiores desvios', style: AppTextStyles.label(colors)),
            const SizedBox(height: AppSpacing.xs),
            for (final entry in top) _WizardDeviationRow(entry: entry),
          ],
        ],
      ),
    );
  }
}

class _WizardSummaryRow extends StatelessWidget {
  const _WizardSummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMuted(colors))),
          Text(
            value,
            style: AppTextStyles.label(colors).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _WizardDeviationRow extends StatelessWidget {
  const _WizardDeviationRow({required this.entry});

  final MonthlyPlanEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final diff = entry.actual - entry.planned;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(colors).copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.signedCurrency(diff),
            style: AppTextStyles.label(
              colors,
            ).copyWith(color: diff > 0 ? colors.over : colors.primary),
          ),
        ],
      ),
    );
  }
}

class _SettlementSection extends StatelessWidget {
  const _SettlementSection({
    required this.settlement,
    required this.isLoading,
    required this.error,
    required this.closed,
  });

  final MonthSettlement? settlement;
  final bool isLoading;
  final String? error;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            closed ? 'Transferências registadas' : 'Transferências previstas',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null) ...[
            AppErrorBanner(
              message:
                  'Não foi possível pré-visualizar as contribuições. '
                  '$error',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Podes fechar mesmo assim; os números são os atuais.',
              style: AppTextStyles.helper(colors),
            ),
          ] else
            _SettlementBody(settlement: settlement),
        ],
      ),
    );
  }
}

class _SettlementBody extends StatelessWidget {
  const _SettlementBody({required this.settlement});

  final MonthSettlement? settlement;

  @override
  Widget build(BuildContext context) {
    final settlement = this.settlement;
    if (settlement == null) {
      return Text(
        'Sem pré-visualização.',
        style: AppTextStyles.bodyMuted(context.colors),
      );
    }
    if (settlement.status != SettlementStatus.ok) {
      return Text(
        settlement.message ?? 'Sem rendimento registado.',
        style: AppTextStyles.bodyMuted(context.colors),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < settlement.people.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _SettlementRow(person: settlement.people[index]),
        ],
      ],
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.person});

  final MonthSettlementPerson person;

  @override
  Widget build(BuildContext context) {
    final toJoint = person.transfersToJoint;
    final toPerson = person.transfersToPerson;
    final amount = toJoint
        ? person.transferToJoint
        : toPerson
        ? person.transferToPerson
        : null;
    return AppTransferFlow(
      name: person.personName,
      amount: amount,
      direction: toPerson
          ? AppTransferDirection.toPerson
          : AppTransferDirection.toJoint,
    );
  }
}

class _GoalReview extends StatelessWidget {
  const _GoalReview({required this.viewModel});

  final CloseMonthWizardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final goals = viewModel.goals;
    final preview = goals.closePreview;
    final available = preview?.availableAmount ?? goals.available;
    final planned = preview?.plannedTotal ?? goals.planned;
    final reserved = preview?.reservedTotal ?? goals.reserved;
    final unallocated = preview?.unallocated ?? goals.unallocated;
    final adjusted = preview?.adjustedFromTemplate ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Resumo', style: AppTextStyles.sectionHeading),
              const SizedBox(height: AppSpacing.md),
              _WizardSummaryRow(
                label: 'Disponível',
                value: AppFormatters.currency(available),
                color: colors.ink,
              ),
              _WizardSummaryRow(
                label: adjusted ? 'Planeado final' : 'Planeado',
                value: AppFormatters.currency(planned),
                color: colors.ink,
              ),
              _WizardSummaryRow(
                label: 'Reservado',
                value: AppFormatters.currency(reserved),
                color: colors.ink,
              ),
              _WizardSummaryRow(
                label: unallocated < -0.005 ? 'A mais' : 'Por alocar',
                value: AppFormatters.currency(unallocated.abs()),
                color: unallocated.abs() > 0.005 ? colors.over : colors.primary,
              ),
              if (preview != null &&
                  (preview.availableAmount - goals.available).abs() >
                      0.005) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'O disponível atual difere do valor fixado na criação '
                  '(${AppFormatters.currency(goals.available)}).',
                  style: AppTextStyles.helper(colors),
                ),
              ],
              if (preview != null && preview.adjustedFromTemplate) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'O servidor vai redistribuir o planeado pela tabela.',
                  style: AppTextStyles.helper(colors),
                ),
                if (preview.affectedFutureMonths.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Também recalcula: '
                    '${preview.affectedFutureMonths.map(AppFormatters.monthShort).join(', ')}.',
                    style: AppTextStyles.helper(colors),
                  ),
                ],
              ],
              if (preview != null && preview.defaulted.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Assumem o planeado', style: AppTextStyles.label(colors)),
                const SizedBox(height: AppSpacing.xs),
                for (final item in preview.defaulted)
                  _DefaultedGoalRow(item: item),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultedGoalRow extends StatelessWidget {
  const _DefaultedGoalRow({required this.item});

  final GoalClosePreviewDefaulted item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.goalName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small(colors).copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.currency(item.amount),
            style: AppTextStyles.label(colors).copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

class _GoalTransfersSection extends StatelessWidget {
  const _GoalTransfersSection({
    required this.transfers,
    required this.iconKeyByGoal,
    required this.reserved,
    required this.hasIncome,
    required this.isLoading,
    required this.error,
    required this.closed,
  });

  final List<GoalMonthQuota> transfers;
  final Map<String, String?> iconKeyByGoal;
  final double reserved;
  final bool hasIncome;
  final bool isLoading;
  final String? error;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            closed ? 'Transferências registadas' : 'Transferências previstas',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null) ...[
            AppErrorBanner(
              message: 'Não foi possível pré-visualizar o fecho. $error',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Podes fechar mesmo assim; os números são os atuais.',
              style: AppTextStyles.helper(colors),
            ),
          ] else
            _GoalTransferBody(
              transfers: transfers,
              iconKeyByGoal: iconKeyByGoal,
              reserved: reserved,
              hasIncome: hasIncome,
            ),
        ],
      ),
    );
  }
}

class _GoalTransferBody extends StatelessWidget {
  const _GoalTransferBody({
    required this.transfers,
    required this.iconKeyByGoal,
    required this.reserved,
    required this.hasIncome,
  });

  final List<GoalMonthQuota> transfers;
  final Map<String, String?> iconKeyByGoal;
  final double reserved;
  final bool hasIncome;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      final message = reserved <= 0.005
          ? 'Sem valores reservados neste mês: nada a transferir.'
          : !hasIncome
          ? 'Sem rendimento configurado neste mês: não há quotas a transferir.'
          : 'Sem transferências neste mês.';
      return Text(message, style: AppTextStyles.bodyMuted(context.colors));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < transfers.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _GoalTransferRow(
            transfer: transfers[index],
            iconKeyByGoal: iconKeyByGoal,
          ),
        ],
      ],
    );
  }
}

class _GoalTransferRow extends StatelessWidget {
  const _GoalTransferRow({required this.transfer, required this.iconKeyByGoal});

  final GoalMonthQuota transfer;
  final Map<String, String?> iconKeyByGoal;

  @override
  Widget build(BuildContext context) {
    final parts = transfer.parts;
    if (parts.isEmpty) {
      return AppTransferFlow(
        name: transfer.name,
        amount: transfer.amount,
        targetLabel: 'Objetivos',
        targetIcon: Icons.flag_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < parts.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          AppTransferFlow(
            name: transfer.name,
            amount: parts[index].amount,
            targetLabel: parts[index].name,
            targetIcon: GoalIcons.forKey(iconKeyByGoal[parts[index].goalId]),
          ),
        ],
      ],
    );
  }
}
