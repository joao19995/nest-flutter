import 'package:flutter/material.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/monthly_plan.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/view_models/month_detail_view_model.dart';

/// The detail of a single month: its planned vs. actual spend and, once the
/// month is closed, the contributions snapshot.
class MonthDetailView extends StatelessWidget {
  const MonthDetailView({super.key, required this.month});

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  @override
  Widget build(BuildContext context) {
    return MonthPager(
      title: 'Despesas mensais',
      month: month,
      pageBuilder: (context, month, onPreviousMonth, onNextMonth) => _MonthPage(
        month: month,
        onPreviousMonth: onPreviousMonth,
        onNextMonth: onNextMonth,
      ),
    );
  }
}

/// One month in the pager, owning its own presentation state.
class _MonthPage extends StatefulWidget {
  const _MonthPage({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  State<_MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<_MonthPage>
    with ViewModelState<_MonthPage, MonthDetailViewModel> {
  @override
  MonthDetailViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return MonthDetailViewModel(
      expensesRepository: dependencies.expensesRepository,
      month: widget.month,
    );
  }

  @override
  void onViewModelCreated(MonthDetailViewModel viewModel) => viewModel.load();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'expense-month-${viewModel.month}',
              flightShuttleBuilder: heroSurfaceShuttle,
              child: MonthSummaryHero(
                title: 'Despesa do mês',
                month: viewModel.month,
                actual: viewModel.plan?.actual ?? 0,
                planned: viewModel.plan?.planned ?? 0,
                closed: viewModel.plan?.closed ?? false,
                hasPlan: viewModel.plan != null,
                over: viewModel.plan?.summary.over,
                progressPct: viewModel.plan?.summary.progressPct,
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

  final MonthDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final plan = viewModel.plan;
    if (plan != null) {
      return _PlanContent(viewModel: viewModel, plan: plan);
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
          'Ao criar, copia-se o template aplicável a '
          '${AppFormatters.monthName(viewModel.month)}. '
          'O planeado fica logo fixo.',
      isBusy: viewModel.isBusy,
      errorMessage: viewModel.actionError,
      onCreate: viewModel.createMonth,
    );
  }
}

class _PlanContent extends StatelessWidget {
  const _PlanContent({required this.viewModel, required this.plan});

  final MonthDetailViewModel viewModel;
  final MonthlyPlan plan;

  @override
  Widget build(BuildContext context) {
    final settlement = plan.settlement;
    final actionError = viewModel.actionError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionError != null) ...[
          AppErrorBanner(message: actionError),
          const SizedBox(height: AppSpacing.lg),
        ],
        _EntriesCard(
          plan: plan,
          isBusy: viewModel.isBusy,
          onClose: viewModel.closeMonth,
          onSaveActual: viewModel.updateEntryActual,
        ),
        if (plan.closed && settlement != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ContributionsCard(settlement: settlement),
        ],
      ],
    );
  }
}

class _EntriesCard extends StatelessWidget {
  const _EntriesCard({
    required this.plan,
    required this.isBusy,
    required this.onClose,
    required this.onSaveActual,
  });

  final MonthlyPlan plan;
  final bool isBusy;
  final VoidCallback onClose;
  final void Function(String entryId, double actual) onSaveActual;

  @override
  Widget build(BuildContext context) {
    final entries = plan.entries;
    final editable = !plan.closed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Despesas', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            Text(
              'Este mês não tem categorias.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < entries.length; index++)
                  _EntryRow(
                    entry: entries[index],
                    onSaveActual: editable ? onSaveActual : null,
                  ),
              ],
            ),
          if (editable) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Fechar mês',
                icon: Icons.lock_outlined,
                isLoading: isBusy,
                onPressed: () => _confirmClose(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Fechar ${AppFormatters.monthName(plan.month)}?',
      message: 'Depois de fechado não pode ser alterado.',
      confirmLabel: 'Fechar mês',
    );
    if (confirmed) {
      onClose();
    }
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onSaveActual});

  final MonthlyPlanEntry entry;

  /// When provided, the real amount is editable and saved on focus loss.
  final void Function(String entryId, double actual)? onSaveActual;

  @override
  Widget build(BuildContext context) {
    final onSave = onSaveActual;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(category: entry.categoryName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.categoryName, style: AppTextStyles.sectionHeading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Planeado ${AppFormatters.currency(entry.planned)}',
                  style: AppTextStyles.small(context.colors),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (onSave != null)
            MoneyField(
              value: entry.actual,
              originalValue: entry.actual,
              onSave: (actual) => onSave(entry.id, actual),
            )
          else
            Text(
              AppFormatters.currency(entry.actual),
              style: AppTextStyles.sectionHeading.copyWith(
                color: context.colors.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributionsCard extends StatelessWidget {
  const _ContributionsCard({required this.settlement});

  final MonthSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final isOk = settlement.status == SettlementStatus.ok;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contribuições', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (!isOk)
            Text(
              settlement.message ?? 'Sem rendimento registado.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            AppStagger(
              children: [
                for (var index = 0; index < settlement.people.length; index++)
                  _ContributionRow(person: settlement.people[index]),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.person});

  final MonthSettlementPerson person;

  @override
  Widget build(BuildContext context) {
    final transfer = _transfer(context.colors);
    final amount = transfer.amount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          InitialAvatar(name: person.personName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.personName, style: AppTextStyles.sectionHeading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  transfer.direction,
                  style: AppTextStyles.small(
                    context.colors,
                  ).copyWith(color: transfer.color),
                ),
              ],
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              AppFormatters.currency(amount),
              style: AppTextStyles.sectionHeading.copyWith(
                color: transfer.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({double? amount, String direction, Color color}) _transfer(
    NestColors colors,
  ) {
    if (person.transfersToJoint) {
      return (
        amount: person.transferToJoint,
        direction: 'para a conta conjunta',
        color: colors.primaryDark,
      );
    }
    if (person.transfersToPerson) {
      return (
        amount: person.transferToPerson,
        direction: 'da conta conjunta',
        color: colors.primaryDark,
      );
    }
    return (amount: null, direction: 'Está certo', color: colors.muted);
  }
}
