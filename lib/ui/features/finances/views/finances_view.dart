import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
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
  FinancesSection _section = FinancesSection.expenses;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finanças')),
      body: Padding(
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Icons make the segments too tight on phones and the
                      // longest label wraps mid-word; drop them when narrow.
                      final showIcons =
                          constraints.maxWidth >= AppBreakpoints.sm;
                      return Align(
                        child: SegmentedButton<FinancesSection>(
                          showSelectedIcon: false,
                          expandedInsets: showIcons
                              ? null
                              : const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                ),
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                horizontal: showIcons
                                    ? AppSpacing.lg
                                    : AppSpacing.md,
                              ),
                            ),
                          ),
                          segments: [
                            ButtonSegment(
                              value: FinancesSection.expenses,
                              label: const Text(
                                'Despesas',
                                maxLines: 1,
                                softWrap: false,
                              ),
                              icon: showIcons
                                  ? const Icon(Icons.receipt_long_outlined)
                                  : null,
                            ),
                            ButtonSegment(
                              value: FinancesSection.goals,
                              label: const Text(
                                'Objectivos',
                                maxLines: 1,
                                softWrap: false,
                              ),
                              icon: showIcons
                                  ? const Icon(Icons.flag_outlined)
                                  : null,
                            ),
                          ],
                          selected: {_section},
                          onSelectionChanged: (selection) =>
                              setState(() => _section = selection.first),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: LazyIndexedStack(
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
      ),
    );
  }
}
