import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/dashboard/views/dashboard_view.dart';
import 'package:nest/ui/features/expenses/views/expenses_view.dart';
import 'package:nest/ui/features/goals/views/goals_view.dart';
import 'package:nest/ui/features/people/views/people_view.dart';

/// The application shell: hosts the primary destinations and the navigation
/// that switches between them.
///
/// Small viewports get a bottom navigation bar; tablet and wider get a side
/// rail. Pages live in an [IndexedStack] so their state survives tab changes.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<Widget> _pages = <Widget>[
    DashboardView(),
    ExpensesView(),
    GoalsView(),
    PeopleView(),
  ];

  int _selectedIndex = 0;

  void _select(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _selectedIndex, children: _pages);
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
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
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
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

/// The primary destinations, in the order they appear in the shell.
enum _NavigationItem {
  dashboard(
    label: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard,
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
