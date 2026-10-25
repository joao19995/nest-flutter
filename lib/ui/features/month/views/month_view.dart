import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/views/expenses_view.dart';
import 'package:nest/ui/features/goals/views/goals_view.dart';
import 'package:nest/ui/features/month/views/month_ritual_view.dart';

/// The three faces of the Mês tab.
enum MonthSection { ritual, expenses, goals }

/// Mês merges the month's closing ritual, Despesas and Objetivos — the same
/// year view through different lenses — behind a segmented selector, so all
/// three live under a single primary destination.
class MonthView extends StatefulWidget {
  const MonthView({
    super.key,
    this.sectionSignal,
    this.initialSection = MonthSection.ritual,
    this.refreshSignal,
  });

  /// The shared section, owned by the shell. When null the view owns one
  /// seeded with [initialSection] (tests, standalone use).
  final ValueNotifier<MonthSection>? sectionSignal;

  /// The section used when this view creates its own signal.
  final MonthSection initialSection;

  /// Bumps the reload token when the caller wants fresh month data.
  final Listenable? refreshSignal;

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  static const List<AppSectionOption<MonthSection>> _options = [
    AppSectionOption(
      value: MonthSection.ritual,
      label: 'Balanço',
      icon: Icons.fact_check_outlined,
    ),
    AppSectionOption(
      value: MonthSection.expenses,
      label: 'Despesas',
      icon: Icons.receipt_long_outlined,
    ),
    AppSectionOption(
      value: MonthSection.goals,
      label: 'Objetivos',
      icon: Icons.flag_outlined,
    ),
  ];

  /// Only created when the parent injects no signal; the injected one is never
  /// disposed here.
  ValueNotifier<MonthSection>? _ownedSignal;

  int _reloadToken = 0;

  /// The single source of truth for the selected section: the shell's notifier
  /// when injected, otherwise the one owned here.
  ValueNotifier<MonthSection> get _signal =>
      widget.sectionSignal ??
      (_ownedSignal ??= ValueNotifier<MonthSection>(widget.initialSection));

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onRefreshRequested);
  }

  @override
  void didUpdateWidget(covariant MonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshRequested);
      widget.refreshSignal?.addListener(_onRefreshRequested);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshRequested);
    _ownedSignal?.dispose();
    super.dispose();
  }

  void _onRefreshRequested() {
    if (mounted) {
      setState(() => _reloadToken++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mês')),
      body: ValueListenableBuilder<MonthSection>(
        valueListenable: _signal,
        builder: (context, section, _) => Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.md,
                    ),
                    child: AppSectionSwitcher<MonthSection>(
                      options: _options,
                      selected: section,
                      onChanged: (value) => _signal.value = value,
                    ),
                  ),
                  Expanded(
                    child: LazyIndexedStack(
                      key: ValueKey(_reloadToken),
                      index: section.index,
                      children: const [
                        MonthRitualView(),
                        ExpensesView(embedded: true),
                        GoalsView(embedded: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
