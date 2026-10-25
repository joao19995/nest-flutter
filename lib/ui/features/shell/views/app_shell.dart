import 'package:flutter/material.dart';
import 'package:nest/domain/models/todo_list.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/accounts/views/accounts_view.dart';
import 'package:nest/ui/features/agenda/views/agenda_view.dart';
import 'package:nest/ui/features/dashboard/views/dashboard_view.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';
import 'package:nest/ui/features/month/views/month_view.dart';
import 'package:nest/ui/features/more/views/more_view.dart';
import 'package:nest/ui/features/people/views/people_view.dart';
import 'package:nest/ui/features/settings/views/settings_view.dart';
import 'package:nest/ui/features/todos/view_models/todos_view_model.dart';

/// The application shell: hosts the primary destinations and the navigation
/// that switches between them.
///
/// Small viewports get four primary tabs — Hoje, Agenda, Mês and a "Mais" hub;
/// tablet and wider get a flat side rail that surfaces every destination
/// directly. Pages live in an [IndexedStack] so their state survives tab
/// changes. The shell owns the to-do view model so the pending count can badge
/// the Agenda destination, and it owns the section notifiers so deep links can
/// open a child on a given section without recreating it.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const List<_NavDestination> _mobileDestinations = [
    _NavDestination.hoje,
    _NavDestination.agenda,
    _NavDestination.mes,
    _NavDestination.mais,
  ];

  static const List<_NavDestination> _tabletDestinations = [
    _NavDestination.hoje,
    _NavDestination.agenda,
    _NavDestination.mes,
    _NavDestination.contas,
    _NavDestination.pessoas,
    _NavDestination.definicoes,
  ];

  TodosViewModel? _todosViewModel;

  /// Bumped when Hoje becomes visible again, so its view model can refresh.
  final ValueNotifier<int> _dashboardRefresh = ValueNotifier<int>(0);

  /// Bumped when Mês becomes visible again, so its month views reload.
  final ValueNotifier<int> _monthRefresh = ValueNotifier<int>(0);

  /// The section Agenda shows, shared with the view so deep links can set it.
  final ValueNotifier<AgendaSection> _agendaSection =
      ValueNotifier<AgendaSection>(AgendaSection.tasks);

  /// The section Mês shows, shared with the view so deep links can set it.
  /// Starts on the closing ritual; deep links set Despesas or Objetivos.
  final ValueNotifier<MonthSection> _monthSection = ValueNotifier<MonthSection>(
    MonthSection.ritual,
  );

  _NavDestination _selected = _NavDestination.hoje;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_todosViewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _todosViewModel = TodosViewModel(
      todoListsRepository: dependencies.todoListsRepository,
    )..load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final todos = _todosViewModel;
    if (todos != null && !todos.isLoading) {
      todos.refresh();
    }
    if (_selected == _NavDestination.hoje) {
      _dashboardRefresh.value++;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboardRefresh.dispose();
    _monthRefresh.dispose();
    _agendaSection.dispose();
    _monthSection.dispose();
    _todosViewModel?.dispose();
    super.dispose();
  }

  void _select(_NavDestination destination) {
    if (destination == _NavDestination.hoje) {
      _dashboardRefresh.value++;
    }
    if (destination == _NavDestination.mes) {
      _monthRefresh.value++;
    }
    setState(() => _selected = destination);
  }

  /// Opens Agenda on Tarefas.
  void _openTodos() {
    _agendaSection.value = AgendaSection.tasks;
    _select(_NavDestination.agenda);
  }

  /// Opens Agenda on Calendário.
  void _openCalendar() {
    _agendaSection.value = AgendaSection.calendar;
    _select(_NavDestination.agenda);
  }

  /// Opens Mês on Objetivos.
  void _openGoals() {
    _monthSection.value = MonthSection.goals;
    _select(_NavDestination.mes);
  }

  /// Opens Mês on Despesas and the given month's detail.
  void _openMonth(String month) {
    _monthSection.value = MonthSection.expenses;
    _select(_NavDestination.mes);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MonthDetailView(month: month, heroTagPrefix: 'dashboard-month'),
      ),
    );
  }

  /// Opens Mês on the closing ritual (Balanço).
  void _openMonthTab() {
    _monthSection.value = MonthSection.ritual;
    _select(_NavDestination.mes);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _todosViewModel;
    if (viewModel == null) {
      return _buildScaffold(0);
    }
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _buildScaffold(viewModel.pendingCount),
    );
  }

  Widget _buildScaffold(int pending) {
    final isTablet = AppBreakpoints.isTabletOrWider(context);
    final destinations = isTablet ? _tabletDestinations : _mobileDestinations;
    final selectedIndex = _indexOf(destinations);

    final body = LazyIndexedStack(
      index: selectedIndex,
      children: [for (final destination in destinations) _pageFor(destination)],
    );

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _select(destinations[index]),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: _destinationIcon(
                      destination,
                      selected: false,
                      pending: pending,
                    ),
                    selectedIcon: _destinationIcon(
                      destination,
                      selected: true,
                      pending: pending,
                    ),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _select(destinations[index]),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: _destinationIcon(
                destination,
                selected: false,
                pending: pending,
              ),
              selectedIcon: _destinationIcon(
                destination,
                selected: true,
                pending: pending,
              ),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  /// The index of the selected destination in [destinations], falling back to
  /// the first when the current selection is not available in this layout.
  int _indexOf(List<_NavDestination> destinations) {
    final index = destinations.indexOf(_selected);
    return index < 0 ? 0 : index;
  }

  Widget _pageFor(_NavDestination destination) {
    return switch (destination) {
      _NavDestination.hoje => DashboardView(
        pendingTaskCount: _todosViewModel?.pendingCount ?? 0,
        pendingTaskLists: [
          for (final list in _todosViewModel?.lists ?? const <TodoList>[])
            if (list.remaining > 0)
              DashboardTaskList(
                name: list.name,
                done: list.done,
                total: list.total,
              ),
        ],
        onOpenCalendar: _openCalendar,
        onOpenTodos: _openTodos,
        onOpenGoals: _openGoals,
        onOpenMonth: _openMonth,
        onOpenMonthTab: _openMonthTab,
        refreshSignal: _dashboardRefresh,
      ),
      _NavDestination.agenda => AgendaView(
        todosViewModel: _todosViewModel,
        sectionSignal: _agendaSection,
      ),
      _NavDestination.mes => MonthView(
        sectionSignal: _monthSection,
        refreshSignal: _monthRefresh,
      ),
      _NavDestination.contas => const AccountsView(),
      _NavDestination.pessoas => const PeopleView(),
      _NavDestination.definicoes => const SettingsView(),
      _NavDestination.mais => const MoreView(),
    };
  }

  /// The destination icon, badged with the pending task count on Agenda.
  Widget _destinationIcon(
    _NavDestination destination, {
    required bool selected,
    required int pending,
  }) {
    final icon = Icon(selected ? destination.selectedIcon : destination.icon);
    if (destination != _NavDestination.agenda || pending <= 0) {
      return icon;
    }
    return Badge(
      label: Text('$pending'),
      backgroundColor: context.colors.primary,
      textColor: context.colors.surface,
      child: icon,
    );
  }
}

/// The primary destinations.
///
/// Mobile shows the first three plus [mais]; tablet and wider also surface
/// [contas], [pessoas] and [definicoes] directly and drop the [mais] hub.
enum _NavDestination {
  hoje(label: 'Hoje', icon: Icons.today_outlined, selectedIcon: Icons.today),
  agenda(
    label: 'Agenda',
    icon: Icons.event_note_outlined,
    selectedIcon: Icons.event_note,
  ),
  mes(
    label: 'Mês',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
  ),
  mais(label: 'Mais', icon: Icons.more_horiz, selectedIcon: Icons.more_horiz),
  contas(
    label: 'Contas',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance,
  ),
  pessoas(
    label: 'Pessoas',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  definicoes(
    label: 'Definições',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
