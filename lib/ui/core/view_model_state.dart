import 'package:flutter/widgets.dart';

/// Mixin for a [State] that owns a single [ChangeNotifier] view model.
///
/// The view model is built once from [createViewModel] the first time the
/// dependencies are resolved (so `context` is safe to read) and disposed with
/// the state. Implementations kick off any initial load in [onViewModelCreated].
mixin ViewModelState<W extends StatefulWidget, VM extends ChangeNotifier>
    on State<W> {
  VM? _viewModel;

  /// The view model, ready by the time the first build runs.
  VM get viewModel => _viewModel as VM;

  /// Builds the view model. Runs once, with `context` resolvable.
  VM createViewModel();

  /// Runs right after the view model is created. Default: nothing.
  void onViewModelCreated(VM viewModel) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final created = createViewModel();
    _viewModel = created;
    onViewModelCreated(created);
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }
}
