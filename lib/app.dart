import 'package:flutter/material.dart';
import 'package:nest/config/app_constants.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/dashboard/views/dashboard_view.dart';

/// Root widget: installs the dependency scope and the app theme.
class App extends StatefulWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DependenciesScope(
      dependencies: widget.dependencies,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const DashboardView(),
      ),
    );
  }
}
