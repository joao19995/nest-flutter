import 'package:flutter/material.dart';
import 'package:nest/domain/models/category.dart';
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
  const MonthDetailView({
    super.key,
    required this.month,
    this.heroTagPrefix = 'expense-month',
  });

  /// The month to open, formatted `YYYY-MM`.
  final String month;

  /// The prefix of the hero tag shared with the screen that opened this one.
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return MonthPager(
      title: 'Despesas mensais',
      month: month,
      pageBuilder: (context, month, onPreviousMonth, onNextMonth) => _MonthPage(
        month: month,
        heroTagPrefix: heroTagPrefix,
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
    required this.heroTagPrefix,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String month;
  final String heroTagPrefix;
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
      builder: (context, _) => MonthDetailPage(
        heroTag: '${widget.heroTagPrefix}-${viewModel.month}',
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
        child: _MonthBody(viewModel: viewModel),
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
    final fixed = entries
        .where((entry) => entry.type == CategoryType.fixed)
        .toList(growable: false);
    final variable = entries
        .where((entry) => entry.type == CategoryType.variable)
        .toList(growable: false);
    final editable = !plan.closed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Despesas', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            Text(
              'Este mês não tem categorias.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fixed.isNotEmpty)
                  _EntryGroup(
                    title: 'Fixas',
                    entries: fixed,
                    onSaveActual: editable ? onSaveActual : null,
                  ),
                if (fixed.isNotEmpty && variable.isNotEmpty)
                  const SizedBox(height: AppSpacing.lg),
                if (variable.isNotEmpty)
                  _EntryGroup(
                    title: 'Variáveis',
                    entries: variable,
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

/// One category type group, with its actual subtotal.
class _EntryGroup extends StatelessWidget {
  const _EntryGroup({
    required this.title,
    required this.entries,
    required this.onSaveActual,
  });

  final String title;
  final List<MonthlyPlanEntry> entries;
  final void Function(String entryId, double actual)? onSaveActual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtotal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.actual,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: title,
          trailing: Text(
            AppFormatters.currency(subtotal),
            key: ValueKey('entry-group-total-$title'),
            style: AppTextStyles.label(colors).copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppStagger(
          children: [
            for (final entry in entries)
              _EntryRow(entry: entry, onSaveActual: onSaveActual),
          ],
        ),
      ],
    );
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
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: entry.planned > 0
                      ? (entry.actual / entry.planned).clamp(0.0, 1.0)
                      : 0,
                  minHeight: AppSizes.progressBarHeight,
                  backgroundColor: context.colors.lineSoft,
                  color: entry.actual > entry.planned
                      ? context.colors.over
                      : context.colors.primary,
                  borderRadius: AppRadius.fullAll,
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
          const Text('Contribuições', style: AppTextStyles.sectionHeading),
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
    final toJoint = person.transfersToJoint;
    final toPerson = person.transfersToPerson;
    final amount = toJoint
        ? person.transferToJoint
        : toPerson
        ? person.transferToPerson
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: AppTransferFlow(
        name: person.personName,
        amount: amount,
        direction: toPerson
            ? AppTransferDirection.toPerson
            : AppTransferDirection.toJoint,
      ),
    );
  }
}
