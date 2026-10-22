import 'package:flutter/material.dart';
import 'package:nest/domain/models/todo_list.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/accounts/views/accounts_view.dart';
import 'package:nest/ui/features/calendar/views/calendar_view.dart';
import 'package:nest/ui/features/dashboard/views/dashboard_view.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';
import 'package:nest/ui/features/finances/views/finances_view.dart';
import 'package:nest/ui/features/more/views/more_view.dart';
import 'package:nest/ui/features/people/views/people_view.dart';
import 'package:nest/ui/features/settings/views/settings_view.dart';
import 'package:nest/ui/features/todos/view_models/todos_view_model.dart';
import 'package:nest/ui/features/todos/views/todos_view.dart';

/// The application shell: hosts the primary destinations and the navigation
/// that switches between them.
///
/// Small viewports get four primary tabs plus a "Mais" hub; tablet and wider
/// get a flat side rail that surfaces every destination directly. Pages live
/// in an [IndexedStack] so their state survives tab changes. The shell owns the
/// to-do view model so the pending count can badge the Tarefas destination.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<_NavDestination> _mobileDestinations = [
    _NavDestination.inicio,
    _NavDestination.tarefas,
    _NavDestination.calendario,
    _NavDestination.financas,
    _NavDestination.mais,
  ];

  static const List<_NavDestination> _tabletDestinations = [
    _NavDestination.inicio,
    _NavDestination.tarefas,
    _NavDestination.calendario,
    _NavDestination.financas,
    _NavDestination.contas,
    _NavDestination.pessoas,
    _NavDestination.definicoes,
  ];

  TodosViewModel? _todosViewModel;

  _NavDestination _selected = _NavDestination.inicio;

  /// The section Finanças opens on, so the dashboard's goals card can deep-link
  /// straight to Objectivos.
  FinancesSection _financesSection = FinancesSection.expenses;

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
  void dispose() {
    _todosViewModel?.dispose();
    super.dispose();
  }

  void _select(_NavDestination destination) {
    setState(() => _selected = destination);
  }

  /// Opens Finanças on the Objectivos section.
  void _openGoals() {
    setState(() {
      _financesSection = FinancesSection.goals;
      _selected = _NavDestination.financas;
    });
  }

  /// Opens Finanças on Despesas and the given month's detail.
  void _openMonth(String month) {
    setState(() {
      _financesSection = FinancesSection.expenses;
      _selected = _NavDestination.financas;
    });
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MonthDetailView(month: month)),
    );
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
      _NavDestination.inicio => DashboardView(
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
        onOpenCalendar: () => _select(_NavDestination.calendario),
        onOpenTodos: () => _select(_NavDestination.tarefas),
        onOpenGoals: _openGoals,
        onOpenMonth: _openMonth,
      ),
      _NavDestination.tarefas => TodosView(viewModel: _todosViewModel),
      _NavDestination.calendario => const CalendarView(),
      _NavDestination.financas => FinancesView(
        key: ValueKey(_financesSection),
        initialSection: _financesSection,
      ),
      _NavDestination.contas => const AccountsView(),
      _NavDestination.pessoas => const PeopleView(),
      _NavDestination.definicoes => const SettingsView(),
      _NavDestination.mais => const MoreView(),
    };
  }

  /// The destination icon, badged with the pending task count on Tarefas.
  Widget _destinationIcon(
    _NavDestination destination, {
    required bool selected,
    required int pending,
  }) {
    final icon = Icon(selected ? destination.selectedIcon : destination.icon);
    if (destination != _NavDestination.tarefas || pending <= 0) {
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
/// Mobile shows the first four plus [mais]; tablet and wider also surface
/// [pessoas] and [definicoes] directly and drop the [mais] hub.
enum _NavDestination {
  inicio(label: 'Início', icon: Icons.home_outlined, selectedIcon: Icons.home),
  tarefas(
    label: 'Tarefas',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
  ),
  calendario(
    label: 'Calendário',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  financas(
    label: 'Finanças',
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
