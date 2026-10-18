import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/features/expenses/views/expenses_view.dart';
import 'package:nest/ui/features/goals/views/goals_view.dart';

/// The two faces of the month hosted under the Finanças tab.
enum FinancesSection { expenses, goals }

/// Finanças merges Despesas and Objectivos — the two are the same year view
/// with a different lens — behind a segmented selector, so both live under a
/// single primary destination.
class FinancesView extends StatefulWidget {
  const FinancesView({
    super.key,
    this.initialSection = FinancesSection.expenses,
  });

  /// The section shown first. Lets callers deep-link straight to Objectivos.
  final FinancesSection initialSection;

  @override
  State<FinancesView> createState() => _FinancesViewState();
}

class _FinancesViewState extends State<FinancesView> {
  late FinancesSection _section = widget.initialSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finanças')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppBreakpoints.pagePadding(context),
                  AppSpacing.md,
                  AppBreakpoints.pagePadding(context),
                  AppSpacing.xs,
                ),
                child: Align(
                  child: SegmentedButton<FinancesSection>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: FinancesSection.expenses,
                        label: Text('Despesas'),
                        icon: Icon(Icons.receipt_long_outlined),
                      ),
                      ButtonSegment(
                        value: FinancesSection.goals,
                        label: Text('Objectivos'),
                        icon: Icon(Icons.flag_outlined),
                      ),
                    ],
                    selected: {_section},
                    onSelectionChanged: (selection) =>
                        setState(() => _section = selection.first),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _section.index,
                  children: const [
                    ExpensesView(embedded: true),
                    GoalsView(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
