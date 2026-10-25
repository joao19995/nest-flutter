import 'package:flutter/material.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/calendar/views/calendar_view.dart';
import 'package:nest/ui/features/todos/view_models/todos_view_model.dart';
import 'package:nest/ui/features/todos/views/todos_view.dart';

/// The two faces of the Agenda hosted under a single primary destination.
enum AgendaSection { tasks, calendar }

/// Agenda merges Tarefas and Calendário behind a compact selector that sits in
/// each child's AppBar, so both keep their own actions.
class AgendaView extends StatefulWidget {
  const AgendaView({
    super.key,
    this.todosViewModel,
    this.sectionSignal,
    this.initialSection = AgendaSection.tasks,
  });

  /// The shell-owned to-do view model (so the shell can badge pending tasks).
  final TodosViewModel? todosViewModel;

  /// The shared section, owned by the shell. When null the view owns one
  /// seeded with [initialSection] (tests, standalone use).
  final ValueNotifier<AgendaSection>? sectionSignal;

  /// The section used when this view creates its own signal.
  final AgendaSection initialSection;

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  static const List<AppSectionOption<AgendaSection>> _options = [
    AppSectionOption(
      value: AgendaSection.tasks,
      label: 'Tarefas',
      icon: Icons.checklist_outlined,
    ),
    AppSectionOption(
      value: AgendaSection.calendar,
      label: 'Calendário',
      icon: Icons.calendar_month_outlined,
    ),
  ];

  /// Only created when the parent injects no signal; the injected one is never
  /// disposed here.
  ValueNotifier<AgendaSection>? _ownedSignal;

  /// The single source of truth for the selected section: the shell's notifier
  /// when injected, otherwise the one owned here.
  ValueNotifier<AgendaSection> get _signal =>
      widget.sectionSignal ??
      (_ownedSignal ??= ValueNotifier<AgendaSection>(widget.initialSection));

  @override
  void dispose() {
    _ownedSignal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AgendaSection>(
      valueListenable: _signal,
      builder: (context, section, _) {
        final switcher = AppSectionSwitcher<AgendaSection>(
          compact: true,
          options: _options,
          selected: section,
          onChanged: (value) => _signal.value = value,
        );
        return LazyIndexedStack(
          index: section.index,
          children: [
            TodosView(
              viewModel: widget.todosViewModel,
              titleOverride: switcher,
            ),
            CalendarView(titleOverride: switcher),
          ],
        );
      },
    );
  }
}
