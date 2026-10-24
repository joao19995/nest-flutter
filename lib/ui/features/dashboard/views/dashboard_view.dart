import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/goals/view_models/goals_view_model.dart';

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
    this.refreshSignal,
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

  /// Notifies the dashboard to reload when it becomes visible again.
  final Listenable? refreshSignal;

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
  void onViewModelCreated(DashboardViewModel viewModel) {
    widget.refreshSignal?.addListener(_onRefreshRequested);
    viewModel.load();
  }

  void _onRefreshRequested() => viewModel.refresh();

  Future<void> _openCloseWizard(String month) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CloseMonthWizardView(month: month),
      ),
    );
    if (mounted) {
      await viewModel.refresh();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshRequested);
      widget.refreshSignal?.addListener(_onRefreshRequested);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshRequested);
    super.dispose();
  }

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
                    onCloseMonth: _openCloseWizard,
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
    required this.onCloseMonth,
  });

  final DashboardViewModel viewModel;
  final int pendingTaskCount;
  final List<DashboardTaskList> pendingTaskLists;
  final VoidCallback? onOpenTodos;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenGoals;
  final ValueChanged<String>? onOpenMonth;
  final ValueChanged<String> onCloseMonth;

  void _showPreviousMonth() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(viewModel.showPreviousMonth());
  }

  void _showNextMonth() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(viewModel.showNextMonth());
  }

  @override
  Widget build(BuildContext context) {
    final alertsError = viewModel.alertsSection.errorMessage;
    final stripError = viewModel.stripSection.errorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GreetingHeader(greeting: viewModel.greeting, date: viewModel.today),
        const SizedBox(height: AppSpacing.lg),
        PeriodSwipeDetector(
          onPrevious: viewModel.canGoToPreviousMonth
              ? _showPreviousMonth
              : null,
          onNext: viewModel.canGoToNextMonth ? _showNextMonth : null,
          child: AnimatedPeriodSwitcher(
            period: viewModel.month,
            child: _DashboardMonthHero(
              month: viewModel.month,
              summary: viewModel.monthSummary,
              state: viewModel.monthSection,
              canGoToPrevious: viewModel.canGoToPreviousMonth,
              canGoToNext: viewModel.canGoToNextMonth,
              onPrevious: _showPreviousMonth,
              onNext: _showNextMonth,
              onRetry: viewModel.retryMonth,
              onOpenMonth: onOpenMonth,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (stripError != null && stripError != alertsError)
          _InlineError(message: stripError, onRetry: viewModel.retryStrip)
        else if (viewModel.stripSection.isLoading)
          const _StripSkeleton()
        else if (viewModel.yearMonths.isNotEmpty)
          AppYearStrip(
            months: viewModel.yearMonths,
            currentMonth: viewModel.month,
            onTap: (month) {
              onOpenMonth?.call(month);
            },
          ),
        if (alertsError != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _InlineError(message: alertsError, onRetry: viewModel.retryAlerts),
          const SizedBox(height: AppSpacing.lg),
        ] else if (viewModel.alerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _AttentionCard(
            alerts: viewModel.alerts,
            onOpenMonth: onOpenMonth,
            onCloseMonth: onCloseMonth,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _DashboardSection(
          title: 'Hoje e próximos',
          onTap: onOpenCalendar,
          child: _SectionBody(
            state: viewModel.eventsSection,
            onRetry: viewModel.retryEvents,
            skeleton: const _ListSkeleton(rows: 3),
            child: _UpcomingList(
              events: viewModel.upcomingEvents,
              today: viewModel.today,
            ),
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
              trailing: AppPeriodStepper(
                variant: AppPeriodStepperVariant.inline,
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
              child: _SectionBody(
                state: viewModel.goalsSection,
                onRetry: viewModel.retryGoals,
                skeleton: const _ListSkeleton(),
                child: _GoalsList(goals: viewModel.goals),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Renders a section's skeleton, inline error or content.
class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.state,
    required this.onRetry,
    required this.skeleton,
    required this.child,
  });

  final DashboardSectionState state;
  final VoidCallback onRetry;
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return skeleton;
    }
    final error = state.errorMessage;
    if (error != null) {
      return _InlineError(message: error, onRetry: onRetry);
    }
    return child;
  }
}

/// A compact failure message with its retry action.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppErrorBanner(message: message),
        const SizedBox(height: AppSpacing.xs),
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

/// A few pulsing lines standing in for a list while it loads.
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({this.rows = 2});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          const AppSkeleton(height: AppSizes.skeletonHeadingHeight),
        ],
      ],
    );
  }
}

/// A pulsing bar standing in for the year strip while it loads.
class _StripSkeleton extends StatelessWidget {
  const _StripSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeleton(height: AppSizes.minTouchTarget);
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

/// The actionable warnings listing the months that need attention.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.alerts,
    required this.onOpenMonth,
    required this.onCloseMonth,
  });

  final List<DashboardAlert> alerts;
  final ValueChanged<String>? onOpenMonth;
  final ValueChanged<String> onCloseMonth;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < alerts.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            _AlertRow(
              alert: alerts[index],
              onOpenMonth: onOpenMonth,
              onCloseMonth: onCloseMonth,
            ),
          ],
        ],
      ),
    );
  }
}

/// One actionable alert: warning icon, message and a chip that opens the month.
///
/// The whole row is the touch target; the chip is only a visual affordance.
class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.onOpenMonth,
    required this.onCloseMonth,
  });

  final DashboardAlert alert;
  final ValueChanged<String>? onOpenMonth;
  final ValueChanged<String> onCloseMonth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final openMonth = onOpenMonth;
    final toClose = alert.kind == DashboardAlertKind.toClose;
    final row = Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: AppSizes.iconLarge,
          color: toClose ? colors.over : colors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(alert.message, style: AppTextStyles.body)),
        const SizedBox(width: AppSpacing.sm),
        AppChip(
          label: toClose ? 'Fechar' : 'Criar',
          style: toClose
              ? AppBadgeStyles.destructive(colors)
              : AppBadgeStyles.open(colors),
        ),
      ],
    );
    final onTap = toClose
        ? () => onCloseMonth(alert.month)
        : openMonth == null
        ? null
        : () => openMonth(alert.month);
    if (onTap == null) {
      return row;
    }
    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '${alert.message}. ${toClose ? 'Fechar' : 'Criar'} '
          '${AppFormatters.monthName(alert.month)}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: row,
          ),
        ),
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
    final groups = <DateTime, List<CalendarEvent>>{};
    for (final event in visible) {
      final day = DateUtils.dateOnly(event.startsAt);
      groups.putIfAbsent(day, () => []).add(event);
    }
    final entries = groups.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var groupIndex = 0; groupIndex < entries.length; groupIndex++) ...[
          if (groupIndex > 0) const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              _dayLabel(entries[groupIndex].key),
              style: AppTextStyles.label(context.colors),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (
            var eventIndex = 0;
            eventIndex < entries[groupIndex].value.length;
            eventIndex++
          ) ...[
            if (eventIndex > 0) const SizedBox(height: AppSpacing.sm),
            _EventRow(event: entries[groupIndex].value[eventIndex]),
          ],
        ],
      ],
    );
  }

  String _dayLabel(DateTime day) {
    final days = day.difference(today).inDays;
    if (days == 0) {
      return 'Hoje';
    }
    if (days == 1) {
      return 'Amanhã';
    }
    return AppFormatters.weekdayDayMonth(day);
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}

class _TaskLists extends StatelessWidget {
  const _TaskLists({required this.lists});

  final List<DashboardTaskList> lists;

  static const int _max = 3;

  @override
  Widget build(BuildContext context) {
    if (lists.isEmpty) {
      return const _EmptyHint('Sem tarefas pendentes.');
    }
    final visible = lists.take(_max).toList();
    final hidden = lists.length - visible.length;
    return Column(
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _TaskListRow(list: visible[index]),
        ],
        if (hidden > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mais $hidden ${hidden == 1 ? 'lista' : 'listas'} em Tarefas',
            style: AppTextStyles.small(context.colors),
          ),
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

  final List<GoalSummary> goals;

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

  final GoalSummary goal;

  @override
  Widget build(BuildContext context) {
    final label = goal.hasTarget
        ? '${goal.name}, ${AppFormatters.percentage((goal.progress * 100).round())} '
              'do objetivo, faltam ${AppFormatters.currency(goal.missing)}'
        : '${goal.name}, ${AppFormatters.currency(goal.reserved)} reservados';
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Column(
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
        ),
      ),
    );
  }
}

/// This month's spending against the plan, as the dashboard's dark hero.
class _DashboardMonthHero extends StatelessWidget {
  const _DashboardMonthHero({
    required this.month,
    required this.summary,
    required this.state,
    required this.canGoToPrevious,
    required this.canGoToNext,
    required this.onPrevious,
    required this.onNext,
    required this.onRetry,
    required this.onOpenMonth,
  });

  final String month;
  final ExpenseMonthSummary? summary;
  final DashboardSectionState state;
  final bool canGoToPrevious;
  final bool canGoToNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final ValueChanged<String>? onOpenMonth;

  @override
  Widget build(BuildContext context) {
    final onOpenMonth = this.onOpenMonth;
    final error = state.errorMessage;
    final hero = Hero(
      tag: 'dashboard-month-$month',
      flightShuttleBuilder: heroSurfaceShuttle,
      child: HeroPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Despesa do mês',
                    style: AppTextStyles.navSection(
                      context.colors,
                    ).copyWith(color: AppColors.onHeroMuted),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppPeriodStepper(
                  label: AppFormatters.monthShort(month),
                  onPrevious: canGoToPrevious ? onPrevious : null,
                  onNext: canGoToNext ? onNext : null,
                  previousTooltip: 'Mês anterior',
                  nextTooltip: 'Mês seguinte',
                ),
              ],
            ),
            if (state.isLoading)
              const _HeroBodySkeleton()
            else if (error != null)
              _HeroError(message: error, onRetry: onRetry)
            else
              _HeroSummaryBody(summary: summary),
          ],
        ),
      ),
    );
    if (onOpenMonth == null) {
      return hero;
    }
    return Semantics(
      button: true,
      label: 'Abrir despesas de ${AppFormatters.monthName(month)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onOpenMonth(month),
        child: hero,
      ),
    );
  }
}

/// The hero's amount, ring and deviation, once its summary has loaded.
class _HeroSummaryBody extends StatelessWidget {
  const _HeroSummaryBody({required this.summary});

  final ExpenseMonthSummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final hasPlan =
        summary != null && summary.status != ExpenseMonthStatus.missing;
    final diff = summary == null ? 0.0 : summary.actual - summary.planned;
    final diffPct = summary == null || summary.planned <= 0
        ? 0.0
        : diff / summary.planned * 100;
    final progress = hasPlan
        ? (summary.progressPct / 100).clamp(0.0, 1.0)
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedAmount(
                  value: summary?.actual ?? 0,
                  style: AppTextStyles.statDisplay.copyWith(
                    color: AppColors.onHero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppProgressRing(
              progress: progress,
              color: summary?.over == true
                  ? AppColors.overOnDark
                  : AppColors.mint,
              label: hasPlan
                  ? AppFormatters.percentage(summary.progressPct.round())
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasPlan)
          HeroDeviationPill(diff: diff, diffPct: diffPct, over: summary.over)
        else
          const HeroDeltaPill(label: 'Sem plano', color: AppColors.onHeroMuted),
      ],
    );
  }
}

/// The hero's placeholder while its month summary loads.
class _HeroBodySkeleton extends StatelessWidget {
  const _HeroBodySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: AppSkeleton(height: AppSizes.progressRing)),
            SizedBox(width: AppSpacing.md),
            AppSkeleton(
              height: AppSizes.progressRing,
              width: AppSizes.progressRing,
              radius: AppSizes.progressRing,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        AppSkeleton(width: AppSizes.skeletonHeadingWidth),
      ],
    );
  }
}

/// The hero's failure message, readable on the dark surface.
class _HeroError extends StatelessWidget {
  const _HeroError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.onHeroMuted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.onHero),
            child: const Text('Tentar de novo'),
          ),
        ),
      ],
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
