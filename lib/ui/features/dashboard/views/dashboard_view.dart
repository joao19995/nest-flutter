import 'package:flutter/material.dart';
import 'package:nest/ui/core/widgets/widgets.dart';

/// Placeholder for the dashboard destination; content is not implemented yet.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const AppEmpty(
        icon: Icons.space_dashboard_outlined,
        message: 'Em breve.',
      ),
    );
  }
}
