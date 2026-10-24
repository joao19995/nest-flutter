import 'dart:async';

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
        _EntriesCard(viewModel: viewModel, plan: plan),
        if (plan.closed && settlement != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ContributionsCard(settlement: settlement),
        ],
      ],
    );
  }
}

class _EntriesCard extends StatelessWidget {
  const _EntriesCard({required this.viewModel, required this.plan});

  final MonthDetailViewModel viewModel;
  final MonthlyPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = plan.entries;
    final editable = !plan.closed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EntriesHeader(
            total: entries.length,
            filled: viewModel.filledEntries,
            showCount: editable && entries.isNotEmpty,
          ),
          if (editable && viewModel.hasFixedToFill) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Preencher fixas',
                icon: Icons.done_all,
                variant: AppButtonVariant.ghost,
                onPressed: viewModel.isBusy
                    ? null
                    : viewModel.fillPlannedForFixed,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            Text(
              'Este mês não tem categorias.',
              style: AppTextStyles.bodyMuted(colors),
            )
          else
            _EntriesList(
              entries: entries,
              onSaveActual: editable ? viewModel.updateEntryActual : null,
              onFillPlanned: editable ? viewModel.fillPlanned : null,
            ),
          if (editable) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Fechar mês',
                icon: Icons.lock_outlined,
                isLoading: viewModel.isBusy,
                onPressed: () => _confirmClose(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    unawaited(viewModel.loadSettlementPreview());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CloseMonthDialog(viewModel: viewModel, plan: plan),
    );
    if (confirmed ?? false) {
      await viewModel.closeMonth();
    }
  }
}

class _EntriesHeader extends StatelessWidget {
  const _EntriesHeader({
    required this.total,
    required this.filled,
    required this.showCount,
  });

  final int total;
  final int filled;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        const Expanded(
          child: Text('Despesas', style: AppTextStyles.sectionHeading),
        ),
        if (showCount)
          Text(
            '$filled de $total preenchidas',
            key: const ValueKey('entries-filled-count'),
            style: AppTextStyles.label(colors),
          ),
      ],
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({
    required this.entries,
    required this.onSaveActual,
    required this.onFillPlanned,
  });

  final List<MonthlyPlanEntry> entries;
  final void Function(String entryId, double actual)? onSaveActual;
  final void Function(String entryId)? onFillPlanned;

  @override
  Widget build(BuildContext context) {
    final fixed = entries
        .where((entry) => entry.type == CategoryType.fixed)
        .toList(growable: false);
    final variable = entries
        .where((entry) => entry.type == CategoryType.variable)
        .toList(growable: false);
    final ordered = [...fixed, ...variable];
    final lastId = ordered.isEmpty ? null : ordered.last.id;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fixed.isNotEmpty)
            _EntryGroup(
              title: 'Fixas',
              entries: fixed,
              orderOffset: 0,
              lastEntryId: lastId,
              onSaveActual: onSaveActual,
              onFillPlanned: onFillPlanned,
            ),
          if (fixed.isNotEmpty && variable.isNotEmpty)
            const SizedBox(height: AppSpacing.lg),
          if (variable.isNotEmpty)
            _EntryGroup(
              title: 'Variáveis',
              entries: variable,
              orderOffset: fixed.length,
              lastEntryId: lastId,
              onSaveActual: onSaveActual,
              onFillPlanned: onFillPlanned,
            ),
        ],
      ),
    );
  }
}

/// One category type group, with its actual subtotal.
class _EntryGroup extends StatelessWidget {
  const _EntryGroup({
    required this.title,
    required this.entries,
    required this.orderOffset,
    required this.lastEntryId,
    required this.onSaveActual,
    required this.onFillPlanned,
  });

  final String title;
  final List<MonthlyPlanEntry> entries;

  /// The focus order of the first entry, so both groups share one sequence.
  final int orderOffset;

  /// The visual last entry, which closes the keyboard instead of advancing.
  final String? lastEntryId;

  final void Function(String entryId, double actual)? onSaveActual;
  final void Function(String entryId)? onFillPlanned;

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
            for (var index = 0; index < entries.length; index++)
              _EntryRow(
                entry: entries[index],
                order: orderOffset + index,
                isLast: entries[index].id == lastEntryId,
                onSaveActual: onSaveActual,
                onFillPlanned: onFillPlanned,
              ),
          ],
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.order,
    required this.isLast,
    required this.onSaveActual,
    required this.onFillPlanned,
  });

  final MonthlyPlanEntry entry;

  /// The position of this row's amount in the keyboard traversal.
  final int order;

  /// Whether this is the last editable field in the month.
  final bool isLast;

  /// When provided, the real amount is editable and saved on focus loss.
  final void Function(String entryId, double actual)? onSaveActual;

  /// When provided, the planned amount can be copied into this line.
  final void Function(String entryId)? onFillPlanned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EntryInfo(entry: entry, showMissing: onSaveActual != null),
          const SizedBox(width: AppSpacing.md),
          _EntryAmount(
            entry: entry,
            order: order,
            isLast: isLast,
            onSaveActual: onSaveActual,
            onFillPlanned: onFillPlanned,
          ),
        ],
      ),
    );
  }
}

class _EntryInfo extends StatelessWidget {
  const _EntryInfo({required this.entry, required this.showMissing});

  final MonthlyPlanEntry entry;
  final bool showMissing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(
            category: entry.categoryName,
            iconKey: entry.categoryIconKey,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.categoryName, style: AppTextStyles.sectionHeading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Planeado ${AppFormatters.currency(entry.planned)}',
                  style: AppTextStyles.small(colors),
                ),
                if (showMissing && !entry.actualSet) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppBadge(
                    label: 'Em falta',
                    style: AppBadgeStyles.muted(colors),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: entry.planned > 0
                      ? (entry.actual / entry.planned).clamp(0.0, 1.0)
                      : 0,
                  minHeight: AppSizes.progressBarHeight,
                  backgroundColor: colors.lineSoft,
                  color: entry.actual > entry.planned
                      ? colors.over
                      : colors.primary,
                  borderRadius: AppRadius.fullAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryAmount extends StatelessWidget {
  const _EntryAmount({
    required this.entry,
    required this.order,
    required this.isLast,
    required this.onSaveActual,
    required this.onFillPlanned,
  });

  /// Places the fill buttons after every amount in the focus traversal.
  static const int _fillOrderBase = 1000;

  final MonthlyPlanEntry entry;
  final int order;
  final bool isLast;
  final void Function(String entryId, double actual)? onSaveActual;
  final void Function(String entryId)? onFillPlanned;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onSave = onSaveActual;
    final onFill = onFillPlanned;
    if (onSave == null) {
      return Text(
        AppFormatters.currency(entry.actual),
        style: AppTextStyles.sectionHeading.copyWith(color: colors.ink),
      );
    }
    final needsPlanned = !entry.actualSet || entry.actual != entry.planned;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FocusTraversalOrder(
          order: NumericFocusOrder(order.toDouble()),
          child: MoneyField(
            value: entry.actual,
            originalValue: entry.actual,
            isLast: isLast,
            onSave: (actual) => onSave(entry.id, actual),
          ),
        ),
        if (onFill != null && needsPlanned) ...[
          const SizedBox(height: AppSpacing.xs),
          FocusTraversalOrder(
            order: NumericFocusOrder((_fillOrderBase + order).toDouble()),
            child: AppButton.icon(
              icon: Icons.done_all,
              tooltip: 'Igual ao planeado',
              onPressed: () => onFill(entry.id),
            ),
          ),
        ],
      ],
    );
  }
}

/// The review shown before the irreversible close: totals, biggest deviations
/// and the transfers the server would record, all without committing anything.
class _CloseMonthDialog extends StatelessWidget {
  const _CloseMonthDialog({required this.viewModel, required this.plan});

  final MonthDetailViewModel viewModel;
  final MonthlyPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final loading = viewModel.isPreviewLoading;
        final error = viewModel.previewError;
        return AlertDialog(
          title: Text('Fechar ${AppFormatters.monthName(plan.month)}?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Depois de fechado não pode ser alterado.',
                  style: AppTextStyles.bodyMuted(colors),
                ),
                const SizedBox(height: AppSpacing.lg),
                _CloseSummary(plan: plan),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Contribuições',
                  style: AppTextStyles.sectionHeading,
                ),
                const SizedBox(height: AppSpacing.md),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (error != null)
                  AppErrorBanner(
                    message:
                        'Não foi possível pré-visualizar as contribuições. '
                        '$error',
                  )
                else
                  _PreviewContributions(
                    settlement: viewModel.settlementPreview,
                  ),
              ],
            ),
          ),
          actions: [
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            AppButton(
              label: 'Fechar mês',
              variant: AppButtonVariant.destructive,
              isLoading: loading,
              onPressed: loading ? null : () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}

/// Planned vs. real totals and the lines that moved the most.
class _CloseSummary extends StatelessWidget {
  const _CloseSummary({required this.plan});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(
          label: 'Planeado',
          value: AppFormatters.currency(plan.planned),
          color: colors.ink,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SummaryRow(
          label: 'Real',
          value: AppFormatters.currency(plan.actual),
          color: colors.ink,
        ),
        const SizedBox(height: AppSpacing.xs),
        _SummaryRow(
          label: 'Desvio',
          value: AppFormatters.signedCurrency(diff),
          color: plan.isOver ? colors.over : colors.primary,
        ),
        if (top.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Maiores desvios', style: AppTextStyles.label(colors)),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in top) _DeviationRow(entry: entry),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMuted(colors))),
        Text(value, style: AppTextStyles.label(colors).copyWith(color: color)),
      ],
    );
  }
}

class _DeviationRow extends StatelessWidget {
  const _DeviationRow({required this.entry});

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

class _PreviewContributions extends StatelessWidget {
  const _PreviewContributions({required this.settlement});

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
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _ContributionRow(person: settlement.people[index]),
        ],
      ],
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
