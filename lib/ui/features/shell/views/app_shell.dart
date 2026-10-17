import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/expenses/views/expenses_view.dart';
import 'package:nest/ui/features/goals/views/goals_view.dart';
import 'package:nest/ui/features/people/views/people_view.dart';
import 'package:nest/ui/features/todos/view_models/todos_view_model.dart';
import 'package:nest/ui/features/todos/views/todos_view.dart';

/// The application shell: hosts the primary destinations and the navigation
/// that switches between them.
///
/// Small viewports get a bottom navigation bar; tablet and wider get a side
/// rail. Pages live in an [IndexedStack] so their state survives tab changes.
/// The shell owns the to-do view model so the pending count can badge the
/// Tarefas destination.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  TodosViewModel? _todosViewModel;

  int _selectedIndex = 0;

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

  void _select(int index) {
    setState(() => _selectedIndex = index);
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
    final pages = <Widget>[
      TodosView(viewModel: _todosViewModel),
      const ExpensesView(),
      const GoalsView(),
      const PeopleView(),
    ];
    final body = IndexedStack(index: _selectedIndex, children: pages);
    if (AppBreakpoints.isTabletOrWider(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final item in _NavigationItem.values)
                  NavigationRailDestination(
                    icon: _destinationIcon(
                      item,
                      selected: false,
                      pending: pending,
                    ),
                    selectedIcon: _destinationIcon(
                      item,
                      selected: true,
                      pending: pending,
                    ),
                    label: Text(item.label),
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
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final item in _NavigationItem.values)
            NavigationDestination(
              icon: _destinationIcon(item, selected: false, pending: pending),
              selectedIcon: _destinationIcon(
                item,
                selected: true,
                pending: pending,
              ),
              label: item.label,
            ),
        ],
      ),
    );
  }

  /// The destination icon, badged with the pending task count on Tarefas.
  Widget _destinationIcon(
    _NavigationItem item, {
    required bool selected,
    required int pending,
  }) {
    final icon = Icon(selected ? item.selectedIcon : item.icon);
    if (item != _NavigationItem.todos || pending <= 0) {
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

/// The primary destinations, in the order they appear in the shell.
enum _NavigationItem {
  todos(
    label: 'Tarefas',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
  ),
  expenses(
    label: 'Despesas',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  goals(
    label: 'Objectivos',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag,
  ),
  people(
    label: 'Pessoas',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  );

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
