import 'package:flutter/material.dart';
import 'package:nest/domain/models/calendar_event.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/calendar/view_models/calendar_view_model.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';

/// The event calendar: a month grid with a day agenda beside (or below) it.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key, this.viewModel});

  /// An externally owned view model. When null the view creates and owns one.
  final CalendarViewModel? viewModel;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarViewModel? _viewModel;
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
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = CalendarViewModel(
      eventsRepository: dependencies.eventsRepository,
      expensesRepository: dependencies.expensesRepository,
    )..load();
    _ownsViewModel = true;
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel?.dispose();
    }
    super.dispose();
  }

  Future<void> _openForm(CalendarEvent? event) async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }
    final day = viewModel.selectedDay;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _EventFormSheet(
        initialTitle: event?.title ?? '',
        initialStartsAt:
            event?.startsAt ??
            DateTime(day.year, day.month, day.day, _defaultHour),
        isEditing: event != null,
        onSave: (title, startsAt) => event == null
            ? viewModel.createEvent(title: title, startsAt: startsAt)
            : viewModel.updateEvent(event, title: title, startsAt: startsAt),
        onDelete: event == null ? null : () => _deleteWithUndo(event),
      ),
    );
  }

  /// Opens the visible month's balance in the existing close wizard and
  /// refreshes the marker afterwards.
  Future<void> _openBalance(String month) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CloseMonthWizardView(month: month),
      ),
    );
    if (mounted) {
      await _viewModel?.load();
    }
  }

  Future<void> _deleteWithUndo(CalendarEvent event) async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }
    final deleted = await viewModel.deleteEvent(event);
    if (!deleted || !mounted) {
      return;
    }
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      message: '"${event.title}" apagado.',
      onAction: () => viewModel.restoreEvent(event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          AppButton(
            label: 'Hoje',
            variant: AppButtonVariant.ghost,
            onPressed: viewModel.goToToday,
          ),
          AppButton.icon(
            icon: Icons.add,
            tooltip: 'Novo evento',
            onPressed: () => _openForm(null),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: PeriodSwipeDetector(
            onPrevious: viewModel.showPreviousMonth,
            onNext: viewModel.showNextMonth,
            child: AnimatedPeriodSwitcher(
              period: MonthKey.of(
                viewModel.visibleMonth.year,
                viewModel.visibleMonth.month,
              ),
              child: _CalendarContent(
                viewModel: viewModel,
                onCreate: () => _openForm(null),
                onEdit: _openForm,
                onDelete: _deleteWithUndo,
                onOpenBalance: _openBalance,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const int _defaultHour = 9;

class _CalendarContent extends StatelessWidget {
  const _CalendarContent({
    required this.viewModel,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenBalance,
  });

  final CalendarViewModel viewModel;
  final VoidCallback onCreate;
  final ValueChanged<CalendarEvent> onEdit;
  final ValueChanged<CalendarEvent> onDelete;
  final ValueChanged<String> onOpenBalance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CalendarHero(viewModel: viewModel, onOpenBalance: onOpenBalance),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final grid = _GridCard(viewModel: viewModel);
                  final agenda = _AgendaCard(
                    viewModel: viewModel,
                    onCreate: onCreate,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  );
                  if (constraints.maxWidth >= AppBreakpoints.md) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: grid),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(flex: 2, child: agenda),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      grid,
                      const SizedBox(height: AppSpacing.lg),
                      agenda,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month headline: event count, the month selector and the balance marker.
class _CalendarHero extends StatelessWidget {
  const _CalendarHero({required this.viewModel, required this.onOpenBalance});

  final CalendarViewModel viewModel;
  final ValueChanged<String> onOpenBalance;

  @override
  Widget build(BuildContext context) {
    final count = viewModel.monthEventCount;
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVENTOS DO MÊS',
                      style: AppTextStyles.navSection(
                        context.colors,
                      ).copyWith(color: AppColors.onHeroMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      viewModel.isLoading ? '—' : '$count',
                      style: AppTextStyles.statDisplay.copyWith(
                        color: AppColors.onHero,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      count == 1 ? 'evento neste mês' : 'eventos neste mês',
                      style: AppTextStyles.small(
                        context.colors,
                      ).copyWith(color: AppColors.onHeroMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppPeriodStepper(
                label: AppFormatters.monthTitle(viewModel.visibleMonth),
                onPrevious: viewModel.showPreviousMonth,
                onNext: viewModel.showNextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MonthBalanceMarker(
            viewModel: viewModel,
            onOpen: () => onOpenBalance(viewModel.visibleMonthKey),
          ),
        ],
      ),
    );
  }
}

/// A non-persisted marker for the visible month's expenses balance.
///
/// It is not a [CalendarEvent]: its state comes from the existing month plan
/// endpoint and tapping it opens the month in the close wizard.
class _MonthBalanceMarker extends StatelessWidget {
  const _MonthBalanceMarker({required this.viewModel, required this.onOpen});

  final CalendarViewModel viewModel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isBalanceLoading) {
      return const _BalanceShell(
        leading: SizedBox(
          width: AppSizes.iconSmall,
          height: AppSizes.iconSmall,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.spinnerStroke,
            color: AppColors.onHero,
          ),
        ),
        label: 'A carregar o balanço…',
      );
    }

    final error = viewModel.balanceError;
    if (error != null) {
      return _BalanceShell(
        leading: _leadingIcon(Icons.error_outline),
        label: 'Indisponível · tentar de novo',
        color: AppColors.overOnDark,
        trailingIcon: Icons.refresh,
        onTap: viewModel.load,
      );
    }

    final plan = viewModel.monthPlan;
    if (plan == null) {
      return _BalanceShell(
        leading: _leadingIcon(Icons.add_circle_outline),
        label: 'Sem plano · criar o mês',
        trailingIcon: Icons.chevron_right,
        onTap: onOpen,
      );
    }

    final closed = plan.closed;
    return _BalanceShell(
      leading: _leadingIcon(
        closed ? Icons.lock_outline : Icons.account_balance_wallet_outlined,
      ),
      label: closed
          ? 'Fechado · ${AppFormatters.currency(plan.actual)}'
          : 'Por fechar · ${AppFormatters.currency(plan.actual)} '
                'de ${AppFormatters.currency(plan.planned)}',
      color: plan.isOver ? AppColors.overOnDark : AppColors.onHero,
      trailingIcon: Icons.chevron_right,
      onTap: onOpen,
    );
  }

  Widget _leadingIcon(IconData icon) =>
      Icon(icon, size: AppSizes.iconMedium, color: AppColors.onHeroMuted);
}

/// The shared surface of the balance marker states.
class _BalanceShell extends StatelessWidget {
  const _BalanceShell({
    required this.leading,
    required this.label,
    this.color = AppColors.onHero,
    this.trailingIcon,
    this.onTap,
  });

  final Widget leading;
  final String label;
  final Color color;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailingIcon = this.trailingIcon;
    return Semantics(
      button: onTap != null,
      label: 'Balanço do mês. $label',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Container(
            key: const ValueKey('calendar-month-balance'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.heroPill,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balanço do mês',
                        style: AppTextStyles.label(
                          context.colors,
                        ).copyWith(color: AppColors.onHeroMuted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    trailingIcon,
                    size: AppSizes.iconMedium,
                    color: AppColors.onHeroMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.viewModel});

  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppBreakpoints.cardPadding(context),
      ),
      child: Column(
        children: [
          const _WeekdayHeader(),
          const SizedBox(height: AppSpacing.sm),
          for (final week in _weeks(viewModel.gridDays))
            _WeekRow(week: week, viewModel: viewModel),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.label(
      context.colors,
    ).copyWith(color: context.colors.faint);
    return Row(
      children: [
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++
        )
          Expanded(
            child: Center(
              child: Text(AppFormatters.weekdayShort(weekday), style: style),
            ),
          ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.viewModel});

  final List<DateTime> week;
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.calendarCell,
      child: Row(
        children: [
          for (final day in week)
            Expanded(
              child: _DayCell(day: day, viewModel: viewModel),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.viewModel});

  final DateTime day;
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final month = viewModel.visibleMonth;
    final inMonth = day.year == month.year && day.month == month.month;
    final isSelected = _sameDay(day, viewModel.selectedDay);
    final isToday = _sameDay(day, viewModel.today);
    final count = viewModel.eventsFor(day).length;
    final dots = count > 3 ? 3 : count;

    final Color? circleColor;
    final Color numberColor;
    if (isSelected) {
      circleColor = colors.primary;
      numberColor = colors.surface;
    } else if (isToday) {
      circleColor = colors.mintSoft;
      numberColor = colors.primaryDark;
    } else {
      circleColor = null;
      numberColor = inMonth ? colors.ink : colors.faint;
    }
    final past = day.isBefore(viewModel.today);
    final dotColor = isSelected
        ? colors.surface
        : (inMonth && !past ? colors.primary : colors.faint);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => viewModel.selectDay(day),
        borderRadius: AppRadius.smAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppSizes.calendarDayCircle,
              height: AppSizes.calendarDayCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: AppTextStyles.label(colors).copyWith(color: numberColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: AppSizes.calendarDot,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < dots; index++) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.xs),
                    Container(
                      width: AppSizes.calendarDot,
                      height: AppSizes.calendarDot,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.viewModel,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarViewModel viewModel;
  final VoidCallback onCreate;
  final ValueChanged<CalendarEvent> onEdit;
  final ValueChanged<CalendarEvent> onDelete;

  @override
  Widget build(BuildContext context) {
    final events = viewModel.selectedEvents;
    final actionError = viewModel.actionError;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppFormatters.dayLong(viewModel.selectedDay),
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _countLabel(events),
            style: AppTextStyles.bodyMuted(context.colors),
          ),
          if (actionError != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(
              message: actionError,
              onDismiss: viewModel.clearActionError,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: events.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Nada agendado para este dia.',
            emptyIcon: Icons.event_busy_outlined,
            emptyActionLabel: 'Adicionar evento',
            onEmptyAction: onCreate,
            child: Column(
              children: [
                for (final event in events)
                  _EventRow(
                    event: event,
                    onEdit: () => onEdit(event),
                    onDelete: () => onDelete(event),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Adicionar evento',
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }

  static String _countLabel(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return 'Sem eventos';
    }
    final count = events.length;
    final label = count == 1 ? '1 evento' : '$count eventos';
    final next = AppFormatters.time(events.first.startsAt);
    return '$label · próximo às $next';
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: const DismissBackground(alignment: Alignment.centerLeft),
      secondaryBackground: const DismissBackground(
        alignment: Alignment.centerRight,
      ),
      child: Material(
        color: context.colors.surface,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                AppBadge(
                  label: AppFormatters.time(event.startsAt),
                  style: AppBadgeStyles.open(context.colors),
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
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right,
                  size: AppSizes.iconSmall,
                  color: context.colors.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The create / edit form, shown as a bottom sheet.
class _EventFormSheet extends StatefulWidget {
  const _EventFormSheet({
    required this.initialTitle,
    required this.initialStartsAt,
    required this.isEditing,
    required this.onSave,
    this.onDelete,
  });

  final String initialTitle;
  final DateTime initialStartsAt;
  final bool isEditing;
  final Future<bool> Function(String title, DateTime startsAt) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initialTitle,
  );
  DateTime? _picked;
  bool _isSaving = false;
  String? _error;

  DateTime get _startsAt => _picked ?? widget.initialStartsAt;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = _startsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 5),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(
      () => _picked = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final current = _startsAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(
      () => _picked = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final saved = await widget.onSave(title, _startsAt);
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = 'Não foi possível guardar o evento.';
      });
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar evento?',
      message: 'O evento deixa de aparecer no calendário.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    Navigator.of(context).pop();
    await onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return BottomSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? 'Editar evento' : 'Novo evento',
            style: AppTextStyles.pageTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _title,
            autofocus: !widget.isEditing,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Ex.: Consulta na dentista',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PickerField(
            icon: Icons.event_outlined,
            label: 'Data',
            value: AppFormatters.shortDate(_startsAt),
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.md),
          _PickerField(
            icon: Icons.schedule_outlined,
            label: 'Hora',
            value: AppFormatters.time(_startsAt),
            onTap: _pickTime,
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBanner(message: error),
          ],
          const SizedBox(height: AppSpacing.xl),
          ListenableBuilder(
            listenable: _title,
            builder: (context, _) {
              final enabled = _title.text.trim().isNotEmpty;
              return AppButton(
                label: widget.isEditing ? 'Guardar' : 'Criar evento',
                isFullWidth: true,
                isLoading: _isSaving,
                onPressed: enabled ? _save : null,
              );
            },
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Eliminar evento',
              icon: Icons.delete_outline,
              variant: AppButtonVariant.ghost,
              isFullWidth: true,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

/// A tappable, read-only input that opens a picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: AppSizes.iconMedium),
        ),
        child: Text(value, style: AppTextStyles.body),
      ),
    );
  }
}

List<List<DateTime>> _weeks(List<DateTime> days) => [
  for (var index = 0; index < days.length; index += 7)
    days.sublist(index, index + 7),
];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
