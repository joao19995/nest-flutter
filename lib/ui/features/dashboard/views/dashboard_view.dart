import 'package:flutter/material.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/dashboard/view_models/dashboard_view_model.dart';

/// A to-do list's completion on the dashboard.
class DashboardTaskList {
  const DashboardTaskList({
    required this.name,
    required this.done,
    required this.total,
  });

  /// The list's name.
  final String name;

  /// How many of the list's tasks are done.
  final int done;

  /// The list's total task count.
  final int total;
}

/// The dashboard (Início): the household's at-a-glance landing screen.
///
/// Recent events, pending tasks, the year's goals and this month's spending.
/// Sections open their destination when tapped.
class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    this.pendingTaskCount = 0,
    this.pendingTaskLists = const [],
    this.onOpenTodos,
    this.onOpenCalendar,
    this.onOpenGoals,
    this.onOpenMonth,
  });

  /// How many tasks are pending, across every to-do list.
  final int pendingTaskCount;

  /// The to-do lists with pending tasks.
  final List<DashboardTaskList> pendingTaskLists;

  /// Opens the Tarefas destination.
  final VoidCallback? onOpenTodos;

  /// Opens the Calendário destination.
  final VoidCallback? onOpenCalendar;

  /// Opens the Objetivos section of Finanças.
  final VoidCallback? onOpenGoals;

  /// Opens the given month's expenses in Finanças.
  final ValueChanged<String>? onOpenMonth;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with ViewModelState<DashboardView, DashboardViewModel> {
  @override
  DashboardViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return DashboardViewModel(
      expensesRepository: dependencies.expensesRepository,
      goalsRepository: dependencies.goalsRepository,
      eventsRepository: dependencies.eventsRepository,
    );
  }

  @override
  void onViewModelCreated(DashboardViewModel viewModel) => viewModel.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
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
                isEmpty: false,
                onRetry: viewModel.load,
                child: RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  color: context.colors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _DashboardContent(
                      viewModel: viewModel,
                      pendingTaskCount: widget.pendingTaskCount,
                      pendingTaskLists: widget.pendingTaskLists,
                      onOpenTodos: widget.onOpenTodos,
                      onOpenCalendar: widget.onOpenCalendar,
                      onOpenGoals: widget.onOpenGoals,
                      onOpenMonth: widget.onOpenMonth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.viewModel,
    required this.pendingTaskCount,
    required this.pendingTaskLists,
    required this.onOpenTodos,
    required this.onOpenCalendar,
    required this.onOpenGoals,
    required this.onOpenMonth,
  });

  final DashboardViewModel viewModel;
  final int pendingTaskCount;
  final List<DashboardTaskList> pendingTaskLists;
  final VoidCallback? onOpenTodos;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenGoals;
  final ValueChanged<String>? onOpenMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GreetingHeader(greeting: viewModel.greeting, date: viewModel.today),
        const SizedBox(height: AppSpacing.lg),
        if (viewModel.alerts.isNotEmpty) ...[
          _AttentionCard(alerts: viewModel.alerts),
          const SizedBox(height: AppSpacing.lg),
        ],
        _DashboardSection(
          title: 'Hoje e próximos',
          onTap: onOpenCalendar,
          child: _UpcomingList(
            events: viewModel.upcomingEvents,
            today: viewModel.today,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DashboardSection(
          title: 'Tarefas pendentes ($pendingTaskCount)',
          onTap: onOpenTodos,
          child: _TaskLists(lists: pendingTaskLists),
        ),
        const SizedBox(height: AppSpacing.lg),
        PeriodSwipeDetector(
          onPrevious: viewModel.showPreviousMonth,
          onNext: viewModel.showNextMonth,
          child: AnimatedPeriodSwitcher(
            period: viewModel.month,
            child: _MonthPanel(
              month: viewModel.month,
              summary: viewModel.monthSummary,
              canGoToPrevious: viewModel.canGoToPreviousMonth,
              canGoToNext: viewModel.canGoToNextMonth,
              onPrevious: viewModel.showPreviousMonth,
              onNext: viewModel.showNextMonth,
              onOpenMonth: onOpenMonth,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PeriodSwipeDetector(
          onPrevious: viewModel.canGoToPreviousGoalsYear
              ? viewModel.showPreviousGoalsYear
              : null,
          onNext: viewModel.canGoToNextGoalsYear
              ? viewModel.showNextGoalsYear
              : null,
          child: AnimatedPeriodSwitcher(
            period: '${viewModel.goalsYear}',
            child: _DashboardSection(
              title: 'Objetivos do ano',
              onTap: onOpenGoals,
              trailing: _PeriodStepper(
                label: '${viewModel.goalsYear}',
                onPrevious: viewModel.canGoToPreviousGoalsYear
                    ? viewModel.showPreviousGoalsYear
                    : null,
                onNext: viewModel.canGoToNextGoalsYear
                    ? viewModel.showNextGoalsYear
                    : null,
                previousTooltip: 'Ano anterior',
                nextTooltip: 'Ano seguinte',
              ),
              child: _GoalsList(goals: viewModel.goals),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// "Boa tarde" on the left, the date on the right.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting, required this.date});

  final String greeting;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(greeting, style: AppTextStyles.pageTitle)),
        Text(
          AppFormatters.weekdayDayMonth(date),
          style: AppTextStyles.small(context.colors),
        ),
      ],
    );
  }
}

/// The warning strip listing the months that need attention.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: AppSizes.iconLarge,
                color: context.colors.over,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Atenção', style: AppTextStyles.sectionHeading),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final alert in alerts)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('• $alert', style: AppTextStyles.body),
            ),
        ],
      ),
    );
  }
}

/// A card with a section heading and an optional trailing control. When
/// [onTap] is set the whole card navigates.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.child,
    this.onTap,
    this.trailing,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.sectionHeading)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.events, required this.today});

  final List<CalendarEvent> events;
  final DateTime today;

  static const int _max = 5;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyHint('Nada agendado.');
    }
    final visible = events.take(_max).toList();
    return Column(
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _EventRow(event: visible[index], today: today),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.today});

  final CalendarEvent event;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final later = !event.occursOn(today);
    return Row(
      children: [
        Text(
          AppFormatters.time(event.startsAt),
          style: AppTextStyles.label(context.colors),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            event.title,
            style: AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (later) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.weekdayShort(event.startsAt.weekday),
            style: AppTextStyles.small(context.colors),
          ),
        ],
      ],
    );
  }
}

class _TaskLists extends StatelessWidget {
  const _TaskLists({required this.lists});

  final List<DashboardTaskList> lists;

  @override
  Widget build(BuildContext context) {
    if (lists.isEmpty) {
      return const _EmptyHint('Sem tarefas pendentes.');
    }
    return Column(
      children: [
        for (var index = 0; index < lists.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _TaskListRow(list: lists[index]),
        ],
      ],
    );
  }
}

/// One list, summarised like a collapsed list in Tarefas: name and progress.
class _TaskListRow extends StatelessWidget {
  const _TaskListRow({required this.list});

  final DashboardTaskList list;

  @override
  Widget build(BuildContext context) {
    final progress = list.total == 0
        ? 'Sem tarefas'
        : '${list.done}/${list.total} concluídas';
    return Row(
      children: [
        Expanded(
          child: Text(
            list.name,
            style: AppTextStyles.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(progress, style: AppTextStyles.small(context.colors)),
      ],
    );
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({required this.goals});

  final List<DashboardGoal> goals;

  static const int _max = 3;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const _EmptyHint('Ainda sem objetivos poupados.');
    }
    final visible = goals.take(_max).toList();
    return Column(
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _GoalRow(goal: visible[index]),
        ],
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final DashboardGoal goal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: AppTextStyles.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              goal.hasTarget
                  ? 'Falta ${AppFormatters.currency(goal.missing)}'
                  : AppFormatters.currency(goal.reserved),
              style: AppTextStyles.small(context.colors),
            ),
          ],
        ),
        if (goal.hasTarget) ...[
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: context.colors.lineSoft,
              color: context.colors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

/// This month's spending against the plan, as a regular card with a month
/// stepper.
class _MonthPanel extends StatelessWidget {
  const _MonthPanel({
    required this.month,
    required this.summary,
    required this.canGoToPrevious,
    required this.canGoToNext,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenMonth,
  });

  final String month;
  final ExpenseMonthSummary? summary;
  final bool canGoToPrevious;
  final bool canGoToNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String>? onOpenMonth;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final onOpenMonth = this.onOpenMonth;
    final hasPlan =
        summary != null && summary.status != ExpenseMonthStatus.missing;
    final diff = summary == null ? 0.0 : summary.actual - summary.planned;
    final diffPct = summary == null || summary.planned <= 0
        ? 0.0
        : diff / summary.planned * 100;
    return _DashboardSection(
      title: 'Despesa do mês',
      onTap: onOpenMonth == null ? null : () => onOpenMonth(month),
      trailing: _PeriodStepper(
        label: AppFormatters.monthShort(month),
        onPrevious: canGoToPrevious ? onPrevious : null,
        onNext: canGoToNext ? onNext : null,
        previousTooltip: 'Mês anterior',
        nextTooltip: 'Mês seguinte',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedAmount(
                value: summary?.actual ?? 0,
                style: AppTextStyles.statDisplay.copyWith(
                  color: context.colors.ink,
                ),
              ),
              if (hasPlan) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  '(${AppFormatters.percentage(summary.progressPct)})',
                  style: AppTextStyles.small(context.colors),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasPlan)
            Row(
              children: [
                Text(
                  'Planeado ${AppFormatters.currency(summary.planned)}',
                  style: AppTextStyles.small(context.colors),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: _DeviationLabel(
                    diff: diff,
                    diffPct: diffPct,
                    over: summary.over,
                  ),
                ),
              ],
            )
          else
            const _EmptyHint('Sem plano para este mês.'),
        ],
      ),
    );
  }
}

/// A theme-aware period stepper for the light cards.
class _PeriodStepper extends StatelessWidget {
  const _PeriodStepper({
    required this.label,
    this.onPrevious,
    this.onNext,
    this.previousTooltip = 'Anterior',
    this.nextTooltip = 'Seguinte',
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperArrow(
          icon: Icons.chevron_left,
          onTap: onPrevious,
          tooltip: previousTooltip,
        ),
        Text(
          label,
          style: AppTextStyles.label(
            context.colors,
          ).copyWith(color: context.colors.primaryDark),
        ),
        _StepperArrow(
          icon: Icons.chevron_right,
          onTap: onNext,
          tooltip: nextTooltip,
        ),
      ],
    );
  }
}

class _StepperArrow extends StatelessWidget {
  const _StepperArrow({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: AppSizes.iconMedium,
            color: onTap == null
                ? context.colors.faint
                : context.colors.primary,
          ),
        ),
      ),
    );
  }
}

/// The deviation against the plan, as a small coloured label.
class _DeviationLabel extends StatelessWidget {
  const _DeviationLabel({
    required this.diff,
    required this.diffPct,
    required this.over,
  });

  final double diff;
  final double diffPct;
  final bool over;

  @override
  Widget build(BuildContext context) {
    if (diff.abs() < 0.005) {
      return Text('Sem desvio', style: AppTextStyles.small(context.colors));
    }
    final sign = diff > 0 ? '+' : '';
    final direction = over ? 'acima' : 'abaixo';
    return Text(
      'Desvio $sign${AppFormatters.currency(diff)} · '
      '${AppFormatters.percentage(diffPct.abs().round())} $direction',
      style: AppTextStyles.small(context.colors).copyWith(
        color: over ? context.colors.over : context.colors.primaryDark,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.bodyMuted(context.colors));
}
