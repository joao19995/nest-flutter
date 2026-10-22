import 'package:flutter/material.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/categories/views/categories_view.dart';
import 'package:nest/ui/features/category_templates/views/category_templates_view.dart';
import 'package:nest/ui/features/expenses/view_models/expenses_view_model.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';

/// A read-only panorama of the year's expenses: the total spent and a
/// month-by-month breakdown of what was spent against what was planned.
class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key, this.embedded = false});

  /// When true the view renders only its content — no [Scaffold] or [AppBar] —
  /// so a parent (e.g. Finanças) can host it under a shared app bar.
  final bool embedded;

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView>
    with ViewModelState<ExpensesView, ExpensesViewModel> {
  @override
  ExpensesViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return ExpensesViewModel(
      expensesRepository: dependencies.expensesRepository,
    );
  }

  @override
  void onViewModelCreated(ExpensesViewModel viewModel) => viewModel.load();

  @override
  Widget build(BuildContext context) {
    final content = PeriodSwipeDetector(
      onPrevious: viewModel.showPreviousYear,
      onNext: viewModel.showNextYear,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => AnimatedPeriodSwitcher(
          period: '${viewModel.selectedYear}',
          child: _ExpensesContent(viewModel: viewModel),
        ),
      ),
    );
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: Padding(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ExpensesContent extends StatelessWidget {
  const _ExpensesContent({required this.viewModel});

  final ExpensesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final months = viewModel.months;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExpenseYearHero(
            year: viewModel.selectedYear,
            summary: viewModel.summary,
            highlightMonth: viewModel.currentMonth,
            canGoToPreviousYear: viewModel.canGoToPreviousYear,
            canGoToNextYear: viewModel.canGoToNextYear,
            onPreviousYear: viewModel.showPreviousYear,
            onNextYear: viewModel.showNextYear,
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppSectionHeader(title: 'Por mês'),
          const SizedBox(height: AppSpacing.md),
          AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há despesas neste ano.',
            child: AppCard(
              padding: EdgeInsets.symmetric(
                horizontal: AppBreakpoints.cardPadding(context),
                vertical: AppSpacing.sm,
              ),
              child: AppStagger(
                children: [
                  for (var index = 0; index < months.length; index++)
                    _MonthRow(
                      month: months[index],
                      onTap: () => _openMonth(context, months[index].month),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ExpensesTools(
            onOpenCategories: () => _open(context, const CategoriesView()),
            onOpenTemplates: () =>
                _open(context, const CategoryTemplatesView()),
          ),
        ],
      ),
    );
  }

  void _openMonth(BuildContext context, String month) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MonthDetailView(month: month)),
    );
  }

  /// Opens [view] and reloads the year afterwards, so category and template
  /// edits are reflected when the user comes back.
  Future<void> _open(BuildContext context, Widget view) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => view));
    await viewModel.load();
  }
}

/// The expense configuration entry points: the categories and the monthly
/// templates.
class _ExpensesTools extends StatelessWidget {
  const _ExpensesTools({
    required this.onOpenCategories,
    required this.onOpenTemplates,
  });

  final VoidCallback onOpenCategories;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) {
    return NavTileGroup(
      tiles: [
        NavTile(
          icon: Icons.list_alt_outlined,
          label: 'Catálogo',
          onTap: onOpenCategories,
        ),
        NavTile(
          icon: Icons.pie_chart_outline,
          label: 'Distribuições',
          onTap: onOpenTemplates,
        ),
      ],
    );
  }
}

/// The year's total spent, shown above the monthly breakdown.
///
/// A dark, gradient panel that also hosts the year selector, the twelve-month
/// bar chart and a couple of status pills (year deviation and rebalancing).
class _ExpenseYearHero extends StatelessWidget {
  const _ExpenseYearHero({
    required this.year,
    required this.summary,
    required this.highlightMonth,
    required this.canGoToPreviousYear,
    required this.canGoToNextYear,
    required this.onPreviousYear,
    required this.onNextYear,
  });

  final int year;
  final ExpenseYearSummary? summary;

  /// The month (`YYYY-MM`) to emphasise in the chart, or null for none.
  final String? highlightMonth;

  final bool canGoToPreviousYear;
  final bool canGoToNextYear;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Despesa do ano',
                  style: AppTextStyles.navSection(
                    context.colors,
                  ).copyWith(color: AppColors.onHeroMuted),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppPeriodStepper(
                label: '$year',
                onPrevious: canGoToPreviousYear ? onPreviousYear : null,
                onNext: canGoToNextYear ? onNextYear : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedAmount(
            value: summary?.actual ?? 0,
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.onHero),
          ),
          if (summary != null && summary.hasData) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                HeroDeviationPill(
                  diff: summary.diff,
                  diffPct: summary.diffPct,
                  over: summary.over,
                  zeroLabel: 'Sem desvio do plano',
                ),
                if (summary.over && summary.remainingMonths > 0)
                  _RebalancePill(
                    perRemainingMonth: summary.perRemainingMonth,
                    remainingMonths: summary.remainingMonths,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppBarChart(
              bars: [
                for (final month in summary.months)
                  (
                    label: AppFormatters.monthShort(month.month),
                    value: month.actual,
                    over: month.over,
                    highlighted: month.month == highlightMonth,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A translucent pill: what to set aside each remaining month to balance.
class _RebalancePill extends StatelessWidget {
  const _RebalancePill({
    required this.perRemainingMonth,
    required this.remainingMonths,
  });

  final double perRemainingMonth;
  final int remainingMonths;

  @override
  Widget build(BuildContext context) {
    final monthLabel = remainingMonths == 1
        ? '1 mês'
        : '$remainingMonths meses';
    return HeroDeltaPill(
      label:
          'Para equilibrar ${AppFormatters.currency(perRemainingMonth)}/mês '
          'a poupar em $monthLabel',
      color: AppColors.onHeroMuted,
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.onTap});

  final ExpenseMonthSummary month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPlan = month.status != ExpenseMonthStatus.missing;
    final delta = month.actual - month.planned;
    final deltaLabel = delta >= 0
        ? '+${AppFormatters.currency(delta)}'
        : AppFormatters.currency(delta);
    return Hero(
      tag: 'expense-month-${month.month}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppFormatters.monthShort(month.month),
                        style: AppTextStyles.sectionHeading,
                      ),
                    ),
                    Text(
                      hasPlan ? AppFormatters.currency(month.actual) : '—',
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: month.over
                            ? context.colors.over
                            : context.colors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MonthBar(month: month, hasPlan: hasPlan),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasPlan
                            ? 'Planeado ${AppFormatters.currency(month.planned)}'
                            : 'Sem plano',
                        style: AppTextStyles.small(context.colors),
                      ),
                    ),
                    if (hasPlan)
                      Text(
                        deltaLabel,
                        style: AppTextStyles.small(context.colors).copyWith(
                          color: month.over
                              ? context.colors.over
                              : context.colors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right,
                      size: AppSizes.iconSmall,
                      color: context.colors.faint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, required this.hasPlan});

  final ExpenseMonthSummary month;
  final bool hasPlan;

  @override
  Widget build(BuildContext context) {
    final factor = hasPlan
        ? (month.progressPct / 100).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return LinearProgressIndicator(
      value: factor,
      minHeight: AppSizes.progressBarHeight,
      backgroundColor: context.colors.lineSoft,
      color: month.over ? context.colors.over : context.colors.primary,
      borderRadius: AppRadius.fullAll,
    );
  }
}
