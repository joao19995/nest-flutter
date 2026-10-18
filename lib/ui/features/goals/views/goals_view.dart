import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';

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
    final body = ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Padding(
        padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
        child: _GoalsContent(viewModel: viewModel),
      ),
    );
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Objectivos')),
      body: body,
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
                Text(
                  'Por mês',
                  style: AppTextStyles.navSection(context.colors),
                ),
                const SizedBox(height: AppSpacing.md),
                _MonthsCard(months: viewModel.months),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Por objetivo',
                  style: AppTextStyles.navSection(context.colors),
                ),
                const SizedBox(height: AppSpacing.md),
                _GoalsCard(goals: viewModel.goals),
              ],
            ),
          ),
        ],
      ),
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

class _MonthsCard extends StatelessWidget {
  const _MonthsCard({required this.months});

  final List<GoalMonthSummary> months;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.onTap});

  final GoalMonthSummary month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'goal-month-${month.month}',
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
                      month.hasPlan
                          ? AppFormatters.currency(month.reserved)
                          : '—',
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: month.hasPlan
                            ? context.colors.primary
                            : context.colors.faint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _subtitle(month),
                        style: AppTextStyles.small(context.colors),
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

  static String _subtitle(GoalMonthSummary month) {
    if (!month.hasPlan) {
      return 'Sem plano';
    }
    if (month.fundedCount == 0) {
      return 'Sem alocações';
    }
    return month.fundedCount == 1
        ? '1 objetivo'
        : '${month.fundedCount} objetivos';
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});

  final List<GoalSummary> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return AppCard(
        child: Text(
          'Ainda não há objetivos.',
          style: AppTextStyles.bodyMuted(context.colors),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppBreakpoints.cardPadding(context),
        vertical: AppSpacing.sm,
      ),
      child: AppStagger(
        children: [
          for (var index = 0; index < goals.length; index++)
            _GoalRow(goal: goals[index]),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                AppFormatters.currency(goal.reserved),
                style: AppTextStyles.sectionHeading.copyWith(
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: context.colors.lineSoft,
              color: goal.hasTarget && goal.progress >= 1
                  ? context.colors.primaryDark
                  : context.colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _TargetLine(goal: goal),
        ],
      ),
    );
  }
}

/// A subtle line: the goal's progress against its annual target.
class _TargetLine extends StatelessWidget {
  const _TargetLine({required this.goal});

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    if (!goal.hasTarget) {
      return Text('Sem orçamento', style: AppTextStyles.small(context.colors));
    }
    if (goal.missing <= 0.005) {
      return Text(
        'Completo · ${AppFormatters.currency(goal.target)}',
        style: AppTextStyles.small(context.colors).copyWith(
          color: context.colors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      'Falta ${AppFormatters.currency(goal.missing)} '
      'de ${AppFormatters.currency(goal.target)}',
      style: AppTextStyles.small(context.colors),
    );
  }
}
