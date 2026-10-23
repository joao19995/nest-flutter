import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';
import 'package:nest/ui/features/goals/views/goal_templates_view.dart';
import 'package:nest/ui/features/goals/views/goals_breakdown_view.dart';
import 'package:nest/ui/features/goals/views/goals_catalog_view.dart';

/// A read-only panorama of the year's savings goals: how much was reserved in
/// total and per month, and how much went to each goal.
class GoalsView extends StatefulWidget {
  const GoalsView({super.key, this.embedded = false});

  /// When true the view renders only its content — no [Scaffold] or [AppBar] —
  /// so a parent (e.g. Finanças) can host it under a shared app bar.
  final bool embedded;

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView>
    with ViewModelState<GoalsView, GoalsViewModel> {
  @override
  GoalsViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return GoalsViewModel(goalsRepository: dependencies.goalsRepository);
  }

  @override
  void onViewModelCreated(GoalsViewModel viewModel) => viewModel.load();

  @override
  Widget build(BuildContext context) {
    final content = PeriodSwipeDetector(
      onPrevious: viewModel.showPreviousYear,
      onNext: viewModel.showNextYear,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => AnimatedPeriodSwitcher(
          period: '${viewModel.selectedYear}',
          child: _GoalsContent(viewModel: viewModel),
        ),
      ),
    );
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Objectivos')),
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

class _GoalsContent extends StatelessWidget {
  const _GoalsContent({required this.viewModel});

  final GoalsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoalsYearHero(
            year: viewModel.selectedYear,
            reserved: viewModel.totalReserved,
            available: viewModel.annualAvailable,
            unallocated: viewModel.unallocated,
            canGoToPreviousYear: viewModel.canGoToPreviousYear,
            canGoToNextYear: viewModel.canGoToNextYear,
            onPreviousYear: viewModel.showPreviousYear,
            onNextYear: viewModel.showNextYear,
          ),
          const SizedBox(height: AppSpacing.xl),
          AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há objetivos poupados neste ano.',
            emptyIcon: Icons.flag_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(title: 'Por mês'),
                const SizedBox(height: AppSpacing.md),
                _MonthGrid(months: viewModel.months),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _GoalsTools(
            onOpenBreakdown: () => _openBreakdown(context),
            onOpenCatalog: () => _open(context, const GoalsCatalogView()),
            onOpenDistribution: () => _open(context, const GoalTemplatesView()),
          ),
        ],
      ),
    );
  }

  /// Opens the per-goal accumulation page with the already loaded data.
  void _openBreakdown(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalsBreakdownView(
          year: viewModel.selectedYear,
          goals: viewModel.goals,
        ),
      ),
    );
  }

  /// Opens [view] and reloads the year afterwards, so catalogue and
  /// distribution edits are reflected when the user comes back.
  Future<void> _open(BuildContext context, Widget view) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => view));
    await viewModel.load();
  }
}

/// The bottom action tiles: the per-goal accumulation, the goals catalogue and
/// the annual distribution.
class _GoalsTools extends StatelessWidget {
  const _GoalsTools({
    required this.onOpenBreakdown,
    required this.onOpenCatalog,
    required this.onOpenDistribution,
  });

  final VoidCallback onOpenBreakdown;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenDistribution;

  @override
  Widget build(BuildContext context) {
    return NavTileGroup(
      tiles: [
        NavTile(
          icon: Icons.savings_outlined,
          label: 'Acumulado',
          onTap: onOpenBreakdown,
        ),
        NavTile(
          icon: Icons.list_alt_outlined,
          label: 'Catálogo',
          onTap: onOpenCatalog,
        ),
        NavTile(
          icon: Icons.pie_chart_outline,
          label: 'Distribuição',
          onTap: onOpenDistribution,
        ),
      ],
    );
  }
}

/// The year's reserved total, shown above the breakdowns.
class _GoalsYearHero extends StatelessWidget {
  const _GoalsYearHero({
    required this.year,
    required this.reserved,
    required this.available,
    required this.unallocated,
    required this.canGoToPreviousYear,
    required this.canGoToNextYear,
    required this.onPreviousYear,
    required this.onNextYear,
  });

  final int year;
  final double reserved;
  final double available;
  final double unallocated;
  final bool canGoToPreviousYear;
  final bool canGoToNextYear;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Objetivos do ano',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: AnimatedAmount(
                  value: reserved,
                  style: AppTextStyles.statDisplay.copyWith(
                    color: AppColors.onHero,
                  ),
                ),
              ),
              Text(
                '  / ${AppFormatters.currency(available)}',
                style: AppTextStyles.small(
                  context.colors,
                ).copyWith(color: AppColors.onHeroMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _UnallocatedPill(unallocated: unallocated),
        ],
      ),
    );
  }
}

/// A translucent pill: how much of the year's money is still to allocate.
class _UnallocatedPill extends StatelessWidget {
  const _UnallocatedPill({required this.unallocated});

  final double unallocated;

  @override
  Widget build(BuildContext context) {
    if (unallocated < -0.005) {
      return HeroDeltaPill(
        label: '${AppFormatters.currency(-unallocated)} acima do disponível',
        color: AppColors.overOnDark,
      );
    }
    if (unallocated <= 0.005) {
      return const HeroDeltaPill(label: 'Tudo alocado');
    }
    return HeroDeltaPill(
      label: '${AppFormatters.currency(unallocated)} por alocar',
      color: AppColors.onHeroMuted,
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.months});

  final List<GoalMonthSummary> months;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppBreakpoints.columnsForWidth(constraints.maxWidth);
        final rowCount = (months.length / columns).ceil();
        return AppStagger(
          children: [
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: row * columns + column < months.length
                            ? _GoalMonthTile(
                                month: months[row * columns + column],
                                onTap: () => _openMonth(
                                  context,
                                  months[row * columns + column].month,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _openMonth(BuildContext context, String month) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalMonthDetailView(month: month),
      ),
    );
  }
}

class _GoalMonthTile extends StatelessWidget {
  const _GoalMonthTile({required this.month, required this.onTap});

  final GoalMonthSummary month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = month.available > 0
        ? month.reserved / month.available
        : 0.0;
    return Hero(
      tag: 'goal-month-${month.month}',
      child: AppMonthTile(
        month: month.month,
        status: month.hasPlan ? AppMonthStatus.open : AppMonthStatus.missing,
        amount: month.hasPlan ? month.reserved : null,
        progress: progress,
        caption: _caption(month),
        onTap: onTap,
      ),
    );
  }

  static String _caption(GoalMonthSummary month) {
    if (!month.hasPlan) {
      return 'Sem plano';
    }
    return month.fundedCount == 1
        ? '1 objetivo'
        : '${month.fundedCount} objetivos';
  }
}
