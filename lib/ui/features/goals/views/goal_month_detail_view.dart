import 'package:flutter/material.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
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
      builder: (context, _) => SingleChildScrollView(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'goal-month-${viewModel.month}',
              flightShuttleBuilder: heroSurfaceShuttle,
              child: MonthSummaryHero(
                title: 'Objetivos do mês',
                month: viewModel.month,
                actual: viewModel.reserved,
                planned: viewModel.planned,
                closed: viewModel.plan?.closed ?? false,
                hasPlan: viewModel.plan != null,
                onPreviousMonth: widget.onPreviousMonth,
                onNextMonth: widget.onNextMonth,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MonthBody(viewModel: viewModel),
          ],
        ),
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
          plan: plan,
          isBusy: viewModel.isBusy,
          onSaveActual: viewModel.updateAllocationActual,
          onClose: viewModel.closeMonth,
        ),
        const SizedBox(height: AppSpacing.lg),
        _TransfersCard(
          transfers: viewModel.transfers,
          reserved: viewModel.reserved,
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.plan,
    required this.isBusy,
    required this.onSaveActual,
    required this.onClose,
  });

  final GoalPlan plan;
  final bool isBusy;
  final void Function(String goalId, double actual) onSaveActual;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final allocations = plan.allocations;
    final editable = !plan.closed;
    final plannedTotal = allocations.fold<double>(
      0,
      (sum, item) => sum + item.planned,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Objetivos', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (allocations.isEmpty)
            Text(
              'Este mês não tem objetivos.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < allocations.length; index++)
                  _GoalRow(
                    allocation: allocations[index],
                    onSaveActual: editable ? onSaveActual : null,
                  ),
              ],
            ),
          if (editable) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _summaryLabel(plan, plannedTotal),
                    style: AppTextStyles.small(context.colors),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: 'Fechar mês',
                  icon: Icons.lock_outlined,
                  isLoading: isBusy,
                  onPressed: () => _confirmClose(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _summaryLabel(GoalPlan plan, double plannedTotal) {
    final missing = plan.availableAmount - plannedTotal;
    final status = missing > 0.005
        ? ' · falta ${AppFormatters.currency(missing)}'
        : missing < -0.005
        ? ' · a mais ${AppFormatters.currency(-missing)}'
        : ' · certo';
    return 'Planeado ${AppFormatters.currency(plannedTotal)} '
        'de ${AppFormatters.currency(plan.availableAmount)}$status · '
        'Reservado ${AppFormatters.currency(plan.reserved)}';
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Guardar e fechar ${AppFormatters.monthName(plan.month)}?',
      message: 'O planeado e o reservado ficam imutáveis.',
      confirmLabel: 'Guardar e fechar',
    );
    if (confirmed) {
      onClose();
    }
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.allocation, required this.onSaveActual});

  final GoalAllocation allocation;

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
  const _TransfersCard({required this.transfers, required this.reserved});

  final List<GoalMonthQuota> transfers;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Transferências', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (transfers.isEmpty)
            Text(
              'Sem valores reservados neste mês: nada a transferir.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < transfers.length; index++)
                  _TransferRow(transfer: transfers[index], reserved: reserved),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer, required this.reserved});

  final GoalMonthQuota transfer;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    final quota = (transfer.share * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(name: transfer.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.name,
                      style: AppTextStyles.label(
                        context.colors,
                      ).copyWith(color: context.colors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ganho ${AppFormatters.currency(transfer.earning)} · '
                      'quota $quota% de ${AppFormatters.currency(reserved)}',
                      style: AppTextStyles.small(context.colors),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Transfere ${AppFormatters.currency(transfer.amount)} '
            'para os objetivos',
            style: AppTextStyles.small(context.colors).copyWith(
              color: context.colors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final part in transfer.parts) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${AppFormatters.currency(part.amount)} para ${part.name}',
              style: AppTextStyles.small(context.colors),
            ),
          ],
        ],
      ),
    );
  }
}
