import 'package:flutter/widgets.dart';
import 'package:nest/config/dependencies.dart';

/// Exposes the [AppDependencies] graph to the widget tree.
///
/// Screens read it once and construct their ViewModels from the repositories.
class DependenciesScope extends InheritedWidget {
  const DependenciesScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  /// Returns the nearest [AppDependencies].
  static AppDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DependenciesScope>();
    if (scope == null) {
      throw StateError(
        'DependenciesScope não encontrado na árvore de widgets.',
      );
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(DependenciesScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
