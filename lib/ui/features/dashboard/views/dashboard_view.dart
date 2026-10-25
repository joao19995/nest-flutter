import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/finances/views/month_transfers_view.dart';

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

/// The dashboard (Hoje): the household's at-a-glance landing screen.
///
/// Recent events, pending tasks and this month's spending. Sections open their
/// destination when tapped.
class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    this.pendingTaskCount = 0,
    this.pendingTaskLists = const [],
    this.onOpenTodos,
    this.onOpenCalendar,
    this.onOpenGoals,
    this.onOpenMonth,
    this.onOpenMonthTab,
    this.refreshSignal,
    this.viewModel,
  });

  /// An externally owned view model. When null the view creates and owns one.
  final DashboardViewModel? viewModel;

  /// How many tasks are pending, across every to-do list.
  final int pendingTaskCount;

  /// The to-do lists with pending tasks.
  final List<DashboardTaskList> pendingTaskLists;

  /// Opens Agenda on Tarefas.
  final VoidCallback? onOpenTodos;

  /// Opens Agenda on Calendário.
  final VoidCallback? onOpenCalendar;

  /// Opens Mês on Objetivos.
  final VoidCallback? onOpenGoals;

  /// Opens Mês on Despesas and the given month's detail.
  final ValueChanged<String>? onOpenMonth;

  /// Opens Mês on the Balanço section.
  final VoidCallback? onOpenMonthTab;

  /// Notifies the dashboard to reload when it becomes visible again.
  final Listenable? refreshSignal;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DashboardViewModel? _viewModel;
  bool _ownsViewModel = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final injected = widget.viewModel;
    if (injected != null) {
      _viewModel = injected;
      widget.refreshSignal?.addListener(_onRefreshRequested);
      return;
    }
    final dependencies = DependenciesScope.of(context);
    final viewModel = DashboardViewModel(
      expensesRepository: dependencies.expensesRepository,
      goalsRepository: dependencies.goalsRepository,
      eventsRepository: dependencies.eventsRepository,
    );
    _viewModel = viewModel;
    _ownsViewModel = true;
    widget.refreshSignal?.addListener(_onRefreshRequested);
    viewModel.load();
  }

  void _onRefreshRequested() => _viewModel?.refresh();

  Future<void> _openCloseWizard(String month) async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CloseMonthWizardView(month: month),
      ),
    );
    if (mounted) {
      await viewModel.refresh();
    }
  }

  void _openSummary(String month) {
    if (_viewModel == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MonthTransfersView(month: month)),
    );
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
    if (_ownsViewModel) {
      _viewModel?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hoje')),
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
                    onOpenMonth: widget.onOpenMonth,
                    onOpenMonthTab: widget.onOpenMonthTab,
                    onCloseMonth: _openCloseWizard,
                    onOpenSummary: _openSummary,
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
    required this.onOpenMonth,
    required this.onOpenMonthTab,
    required this.onCloseMonth,
    required this.onOpenSummary,
  });

  final DashboardViewModel viewModel;
  final int pendingTaskCount;
  final List<DashboardTaskList> pendingTaskLists;
  final VoidCallback? onOpenTodos;
  final VoidCallback? onOpenCalendar;
  final ValueChanged<String>? onOpenMonth;
  final VoidCallback? onOpenMonthTab;
  final ValueChanged<String> onCloseMonth;
  final ValueChanged<String> onOpenSummary;

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
    // The month card owns the displayed month; the attention card only carries
    // the other months (e.g. the next one still to create) plus reminders that
    // deliberately stay visible for the month already on screen.
    final alerts = viewModel.alerts
        .where(
          (alert) =>
              alert.month != viewModel.month || alert.showInAttentionCard,
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GreetingHeader(greeting: viewModel.greeting, date: viewModel.today),
        const SizedBox(height: AppSpacing.lg),
        if (alertsError != null) ...[
          _InlineError(message: alertsError, onRetry: viewModel.retryAlerts),
          const SizedBox(height: AppSpacing.lg),
        ] else if (alerts.isNotEmpty) ...[
          _AttentionCard(
            alerts: alerts,
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
        _MonthCard(
          viewModel: viewModel,
          onPrevious: _showPreviousMonth,
          onNext: _showNextMonth,
          onOpenSummary: onOpenSummary,
          onCloseMonth: onCloseMonth,
          onOpenMonthTab: onOpenMonthTab,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// The month card: the full hero while the month needs attention, a compact
/// one-line summary once it is settled and nothing is due.
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.viewModel,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenSummary,
    required this.onCloseMonth,
    required this.onOpenMonthTab,
  });

  final DashboardViewModel viewModel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onCloseMonth;
  final VoidCallback? onOpenMonthTab;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.highlightMonth) {
      final error = viewModel.monthSection.errorMessage;
      if (error != null) {
        return _InlineError(message: error, onRetry: viewModel.retryMonth);
      }
      final ritual = viewModel.ritual;
      if (ritual == null) {
        return const SizedBox.shrink();
      }
      return _MonthCompactCard(
        month: viewModel.month,
        ritual: ritual,
        onTap: onOpenMonthTab,
      );
    }
    return PeriodSwipeDetector(
      onPrevious: viewModel.canGoToPreviousMonth ? onPrevious : null,
      onNext: viewModel.canGoToNextMonth ? onNext : null,
      child: AnimatedPeriodSwitcher(
        period: viewModel.month,
        child: _DashboardMonthHero(
          month: viewModel.month,
          summary: viewModel.monthSummary,
          ritual: viewModel.ritual,
          state: viewModel.monthSection,
          balanceFocus: viewModel.isBalanceFocus,
          canGoToPrevious: viewModel.canGoToPreviousMonth,
          canGoToNext: viewModel.canGoToNextMonth,
          onPrevious: onPrevious,
          onNext: onNext,
          onRetry: viewModel.retryMonth,
          onOpenSummary: onOpenSummary,
          onCloseMonth: onCloseMonth,
        ),
      ),
    );
  }
}

/// The settled month at a glance: month, expenses and goals on one line.
class _MonthCompactCard extends StatelessWidget {
  const _MonthCompactCard({
    required this.month,
    required this.ritual,
    this.onTap,
  });

  final String month;
  final DashboardRitual ritual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppFormatters.monthName(month)} · '
              '${_expensesLabel(ritual)} · ${_goalsLabel(ritual)}',
              style: AppTextStyles.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: AppSizes.iconSmall,
              color: context.colors.faint,
            ),
          ],
        ],
      ),
    );
  }

  static String _expensesLabel(DashboardRitual ritual) {
    switch (ritual.expensesStatus) {
      case ExpenseMonthStatus.missing:
        return 'Despesas por criar';
      case ExpenseMonthStatus.closed:
        return 'Despesas fechadas';
      case ExpenseMonthStatus.open:
        if (ritual.totalEntries > 0) {
          return 'Despesas ${ritual.filledEntries}/${ritual.totalEntries}';
        }
        return 'Despesas';
    }
  }

  static String _goalsLabel(DashboardRitual ritual) {
    final status = ritual.goalsStatus;
    if (status == null || status == ExpenseMonthStatus.missing) {
      return 'Objetivos por definir';
    }
    if (status == ExpenseMonthStatus.closed) {
      return 'Objetivos fechados';
    }
    return 'Objetivos por fechar';
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

/// A card with a section heading. When [onTap] is set the whole card navigates.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.child,
    this.onTap,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.sectionHeading),
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

/// The month's close at a glance, as the dashboard's dark hero.
class _DashboardMonthHero extends StatelessWidget {
  const _DashboardMonthHero({
    required this.month,
    required this.summary,
    required this.ritual,
    required this.state,
    required this.balanceFocus,
    required this.canGoToPrevious,
    required this.canGoToNext,
    required this.onPrevious,
    required this.onNext,
    required this.onRetry,
    required this.onOpenSummary,
    required this.onCloseMonth,
  });

  final String month;
  final ExpenseMonthSummary? summary;
  final DashboardRitual? ritual;
  final DashboardSectionState state;
  final bool balanceFocus;
  final bool canGoToPrevious;
  final bool canGoToNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onCloseMonth;

  @override
  Widget build(BuildContext context) {
    final error = state.errorMessage;
    return Hero(
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
                    balanceFocus
                        ? 'FECHAR '
                              '${AppFormatters.monthName(month).toUpperCase()}'
                        : 'Balanço do mês',
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
              _HeroBalanceBody(
                month: month,
                summary: summary,
                ritual: ritual,
                balanceFocus: balanceFocus,
                onOpenSummary: onOpenSummary,
                onCloseMonth: onCloseMonth,
              ),
          ],
        ),
      ),
    );
  }
}

/// The hero's two categories, their totals and the close action.
class _HeroBalanceBody extends StatelessWidget {
  const _HeroBalanceBody({
    required this.month,
    required this.summary,
    required this.ritual,
    required this.balanceFocus,
    required this.onOpenSummary,
    required this.onCloseMonth,
  });

  final String month;
  final ExpenseMonthSummary? summary;
  final DashboardRitual? ritual;
  final bool balanceFocus;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onCloseMonth;

  @override
  Widget build(BuildContext context) {
    final status = summary?.status ?? ExpenseMonthStatus.missing;
    final closed = ritual?.isClosed ?? status == ExpenseMonthStatus.closed;
    final missing = ritual?.isMissing ?? status == ExpenseMonthStatus.missing;
    final monthName = AppFormatters.monthName(month);
    final filled = summary?.filledEntries ?? 0;
    final total = summary?.totalEntries ?? 0;
    final progress = status == ExpenseMonthStatus.closed
        ? (summary?.progressPct ?? 0) / 100
        : total > 0
        ? filled / total
        : 0.0;
    final ringLabel = status == ExpenseMonthStatus.closed
        ? AppFormatters.percentage((summary?.progressPct ?? 0).round())
        : status == ExpenseMonthStatus.open && total > 0
        ? AppFormatters.percentage((filled / total * 100).round())
        : null;
    final goalsStatus = ritual?.goalsStatus;
    final goalsReserved = ritual?.goalsReserved ?? 0;
    final goalsPlanned = ritual?.goalsPlanned ?? 0;
    final onPressed = closed
        ? () => onOpenSummary(month)
        : () => onCloseMonth(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                closed
                    ? '$monthName fechado'
                    : missing
                    ? '$monthName por criar'
                    : '$monthName por fechar',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.onHero,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppProgressRing(
              progress: progress.clamp(0.0, 1.0),
              label: ringLabel,
            ),
          ],
        ),
        if (balanceFocus) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'O mês anterior ainda não está fechado.',
            style: AppTextStyles.small(
              context.colors,
            ).copyWith(color: AppColors.onHeroMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _HeroLine(
          label: 'Despesas',
          value: status == ExpenseMonthStatus.missing
              ? '—'
              : AppFormatters.currency(summary?.actual ?? 0),
          percent: _percent(summary?.actual ?? 0, summary?.planned ?? 0),
          percentColor: (summary?.over ?? false)
              ? AppColors.overOnDark
              : AppColors.mint,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HeroLine(
          label: 'Objetivos',
          value:
              goalsStatus == null || goalsStatus == ExpenseMonthStatus.missing
              ? '—'
              : AppFormatters.currency(goalsReserved),
          percent: _percent(goalsReserved, goalsPlanned),
          percentColor: goalsReserved < goalsPlanned
              ? AppColors.overOnDark
              : AppColors.mint,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: closed
              ? 'Ver resumo'
              : missing
              ? 'Começar'
              : 'Continuar',
          icon: closed ? Icons.receipt_long_outlined : Icons.lock_outline,
          variant: AppButtonVariant.secondary,
          isFullWidth: true,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

double? _percent(double actual, double planned) {
  if (planned <= 0.005) {
    return null;
  }
  return (actual - planned) / planned * 100;
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({
    required this.label,
    required this.value,
    required this.percent,
    required this.percentColor,
  });

  final String label;
  final String value;
  final double? percent;
  final Color percentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = this.percent;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.navSection(
              colors,
            ).copyWith(color: AppColors.onHeroMuted),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTextStyles.sectionHeading.copyWith(color: AppColors.onHero),
        ),
        if (percent != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            percent > 0
                ? '+${AppFormatters.percentage(percent.round())}'
                : AppFormatters.percentage(percent.round()),
            style: AppTextStyles.small(colors).copyWith(color: percentColor),
          ),
        ],
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
