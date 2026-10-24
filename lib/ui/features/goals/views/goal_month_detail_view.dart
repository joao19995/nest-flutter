import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/goals/goal_icons.dart';
import 'package:nest/ui/features/goals/view_models/goal_month_detail_view_model.dart';

/// The detail of a single goals month: what each goal is planned and reserved
/// for, and who transfers what to fund it.
class GoalMonthDetailView extends StatelessWidget {
  const GoalMonthDetailView({super.key, required this.month});

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  @override
  Widget build(BuildContext context) {
    return MonthPager(
      title: 'Objetivos mensais',
      month: month,
      pageBuilder: (context, month, onPreviousMonth, onNextMonth) =>
          _GoalMonthPage(
            month: month,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
    );
  }
}

/// One month in the pager, owning its own presentation state.
class _GoalMonthPage extends StatefulWidget {
  const _GoalMonthPage({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  State<_GoalMonthPage> createState() => _GoalMonthPageState();
}

class _GoalMonthPageState extends State<_GoalMonthPage>
    with ViewModelState<_GoalMonthPage, GoalMonthDetailViewModel> {
  @override
  GoalMonthDetailViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return GoalMonthDetailViewModel(
      goalsRepository: dependencies.goalsRepository,
      month: widget.month,
    );
  }

  @override
  void onViewModelCreated(GoalMonthDetailViewModel viewModel) =>
      viewModel.load();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => MonthDetailPage(
        heroTag: 'goal-month-${viewModel.month}',
        title: 'Objetivos do mês',
        month: viewModel.month,
        actual: viewModel.reserved,
        planned: viewModel.planned,
        closed: viewModel.plan?.closed ?? false,
        hasPlan: viewModel.plan != null,
        onPreviousMonth: widget.onPreviousMonth,
        onNextMonth: widget.onNextMonth,
        child: _MonthBody(viewModel: viewModel),
      ),
    );
  }
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({required this.viewModel});

  final GoalMonthDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final plan = viewModel.plan;
    if (plan != null) {
      return _Content(viewModel: viewModel, plan: plan);
    }
    if (viewModel.isLoading || viewModel.errorMessage != null) {
      return AsyncView(
        isLoading: viewModel.isLoading,
        errorMessage: viewModel.errorMessage,
        isEmpty: false,
        onRetry: viewModel.load,
        child: const SizedBox.shrink(),
      );
    }
    return CreateMonthCard(
      description:
          'Ao criar, copia-se o disponível calculado para '
          '${AppFormatters.monthName(viewModel.month)}.',
      isBusy: viewModel.isBusy,
      errorMessage: viewModel.actionError,
      onCreate: viewModel.createMonth,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.viewModel, required this.plan});

  final GoalMonthDetailViewModel viewModel;
  final GoalPlan plan;

  @override
  Widget build(BuildContext context) {
    final actionError = viewModel.actionError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionError != null) ...[
          AppErrorBanner(message: actionError),
          const SizedBox(height: AppSpacing.lg),
        ],
        _GoalsCard(
          viewModel: viewModel,
          plan: plan,
          iconKeyByGoal: viewModel.iconKeyByGoal,
        ),
        const SizedBox(height: AppSpacing.lg),
        _FundingCard(
          funding: viewModel.funding,
          snapshot: plan.availableAmount,
          closed: plan.closed,
        ),
        const SizedBox(height: AppSpacing.lg),
        _TransfersCard(
          transfers: viewModel.transfers,
          iconKeyByGoal: viewModel.iconKeyByGoal,
          reserved: viewModel.reserved,
          hasIncome:
              (viewModel.funding?.incomeNormal ?? 0) +
                  (viewModel.funding?.bonus ?? 0) >
              0.005,
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.viewModel,
    required this.plan,
    required this.iconKeyByGoal,
  });

  final GoalMonthDetailViewModel viewModel;
  final GoalPlan plan;
  final Map<String, String?> iconKeyByGoal;

  @override
  Widget build(BuildContext context) {
    final allocations = plan.allocations;
    final editable = !plan.closed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Objetivos', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (allocations.isEmpty)
            Text(
              'Este mês não tem objetivos.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (final allocation in allocations)
                  _GoalRow(
                    allocation: allocation,
                    iconKey: iconKeyByGoal[allocation.goalId],
                    onSaveActual: editable
                        ? viewModel.updateAllocationActual
                        : null,
                  ),
              ],
            ),
          if (editable) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _summaryLabel(viewModel),
                    style: AppTextStyles.small(context.colors),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: 'Fechar mês',
                  icon: Icons.lock_outlined,
                  isLoading: viewModel.isBusy,
                  onPressed: () => _confirmClose(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _summaryLabel(GoalMonthDetailViewModel viewModel) {
    final missing = viewModel.available - viewModel.planned;
    final status = missing > 0.005
        ? ' · falta ${AppFormatters.currency(missing)}'
        : missing < -0.005
        ? ' · a mais ${AppFormatters.currency(-missing)}'
        : ' · certo';
    return 'Planeado ${AppFormatters.currency(viewModel.planned)} '
        'de ${AppFormatters.currency(viewModel.available)}$status · '
        'Reservado ${AppFormatters.currency(viewModel.reserved)}';
  }

  Future<void> _confirmClose(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CloseMonthWizardView(month: plan.month, startStep: 1),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await viewModel.load();
  }
}

class _FundingCard extends StatelessWidget {
  const _FundingCard({
    required this.funding,
    required this.snapshot,
    required this.closed,
  });

  final MonthFunding? funding;
  final double snapshot;
  final bool closed;

  static double _negate(double value) => value == 0 ? 0 : -value;

  @override
  Widget build(BuildContext context) {
    final funding = this.funding;
    if (funding == null) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final projectionDiffers = (funding.available - snapshot).abs() > 0.005;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Disponível para objetivos',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppFormatters.currency(snapshot),
            key: const ValueKey('goal-funding-available'),
            style: AppTextStyles.pageTitle.copyWith(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            closed
                ? 'Valor fixado no fecho.'
                : 'Valor fixado na criação do mês.',
            style: AppTextStyles.bodyMuted(colors),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Como é calculado', style: AppTextStyles.label(colors)),
          const SizedBox(height: AppSpacing.xs),
          _FundingRow(label: 'Rendimento normal', value: funding.incomeNormal),
          _FundingRow(label: 'Bónus (jun/dez)', value: funding.bonus),
          _FundingRow(
            label: 'Contribuição para despesas',
            value: _negate(funding.contributionRequired),
          ),
          _FundingRow(
            label: 'Quota diária',
            value: _negate(funding.dailyAllowance),
          ),
          Divider(height: AppSpacing.lg, color: colors.lineSoft),
          _FundingRow(
            label: 'Projeção atual',
            value: funding.available,
            isTotal: true,
          ),
          if (projectionDiffers) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              closed
                  ? 'A projeção atual já difere do valor fixado.'
                  : 'A projeção atual difere do valor fixado; o fecho usa a '
                        'projeção.',
              style: AppTextStyles.helper(colors),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O disponível nunca fica negativo; o bónus é somado no fim.',
            style: AppTextStyles.helper(colors),
          ),
        ],
      ),
    );
  }
}

class _FundingRow extends StatelessWidget {
  const _FundingRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: isTotal
                  ? AppTextStyles.label(colors).copyWith(color: colors.ink)
                  : AppTextStyles.small(colors),
            ),
          ),
          Text(
            AppFormatters.currency(value),
            style: AppTextStyles.label(
              colors,
            ).copyWith(color: isTotal ? colors.primary : colors.ink),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.allocation,
    required this.iconKey,
    required this.onSaveActual,
  });

  final GoalAllocation allocation;
  final String? iconKey;

  /// When provided, the reserved amount is editable and saved on focus loss.
  final void Function(String goalId, double actual)? onSaveActual;

  /// Untouched reserved lines default to the planned amount.
  double get _displayValue {
    if (onSaveActual != null && allocation.actual == 0) {
      return allocation.planned;
    }
    return allocation.actual;
  }

  @override
  Widget build(BuildContext context) {
    final onSave = onSaveActual;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalIcon(
            name: allocation.goalName,
            iconKey: iconKey,
            size: AppSizes.goalIconSmall,
            iconSize: AppSizes.iconSmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allocation.goalName,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Planeado ${AppFormatters.currency(allocation.planned)}',
                  style: AppTextStyles.small(context.colors),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (onSave != null)
            MoneyField(
              value: _displayValue,
              originalValue: allocation.actual,
              onSave: (actual) => onSave(allocation.goalId, actual),
            )
          else
            Text(
              AppFormatters.currency(allocation.actual),
              style: AppTextStyles.sectionHeading.copyWith(
                color: context.colors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _TransfersCard extends StatelessWidget {
  const _TransfersCard({
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
    final emptyMessage = reserved <= 0.005
        ? 'Sem valores reservados neste mês: nada a transferir.'
        : !hasIncome
        ? 'Sem rendimento configurado neste mês: não há quotas a transferir.'
        : 'Sem transferências neste mês.';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Transferências', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (transfers.isEmpty)
            Text(emptyMessage, style: AppTextStyles.bodyMuted(context.colors))
          else
            AppStagger(
              children: [
                for (var index = 0; index < transfers.length; index++)
                  _TransferRow(
                    transfer: transfers[index],
                    iconKeyByGoal: iconKeyByGoal,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer, required this.iconKeyByGoal});

  final GoalMonthQuota transfer;
  final Map<String, String?> iconKeyByGoal;

  @override
  Widget build(BuildContext context) {
    final parts = transfer.parts;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.isEmpty)
            AppTransferFlow(
              name: transfer.name,
              amount: transfer.amount,
              targetLabel: 'Objetivos',
              targetIcon: Icons.flag_outlined,
            )
          else
            for (var index = 0; index < parts.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              AppTransferFlow(
                name: transfer.name,
                amount: parts[index].amount,
                targetLabel: parts[index].name,
                targetIcon: GoalIcons.forKey(
                  iconKeyByGoal[parts[index].goalId],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
