import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nest/config/app_constants.dart';
import 'package:nest/config/dependencies.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/shell/views/app_shell.dart';

/// Root widget: installs the dependency scope, preferences and the app theme.
class App extends StatefulWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.dependencies.settingsController.load());
  }

  @override
  void dispose() {
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.dependencies.settingsController;
    return DependenciesScope(
      dependencies: widget.dependencies,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt', 'PT'),
          supportedLocales: const [Locale('pt', 'PT')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const AppShell(),
        ),
      ),
    );
  }
}
