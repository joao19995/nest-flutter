import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/finances/view_models/month_transfers_view_model.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/finances/views/month_transfers_summary.dart';

/// The definitive transfers of a closed month: who owes what to the joint
/// account and to the goals.
class MonthTransfersView extends StatefulWidget {
  const MonthTransfersView({super.key, required this.month});

  /// The month to show, formatted `YYYY-MM`.
  final String month;

  @override
  State<MonthTransfersView> createState() => _MonthTransfersViewState();
}

class _MonthTransfersViewState extends State<MonthTransfersView>
    with ViewModelState<MonthTransfersView, MonthTransfersViewModel> {
  @override
  MonthTransfersViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return MonthTransfersViewModel(
      expensesRepository: dependencies.expensesRepository,
      goalsRepository: dependencies.goalsRepository,
      month: widget.month,
    );
  }

  @override
  void onViewModelCreated(MonthTransfersViewModel viewModel) =>
      viewModel.load();

  Future<void> _openWizard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CloseMonthWizardView(month: widget.month),
      ),
    );
    if (mounted) {
      await viewModel.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transferências de ${AppFormatters.monthName(widget.month)}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => AsyncView(
                  isLoading: viewModel.isLoading,
                  errorMessage: viewModel.errorMessage,
                  isEmpty: false,
                  onRetry: viewModel.load,
                  child: viewModel.transfers.closed
                      ? MonthTransfersSummary(
                          transfers: viewModel.transfers,
                          iconKeyByGoal: viewModel.iconKeyByGoal,
                        )
                      : _PendingTransfers(
                          expensesMissing: viewModel.expensesMissing,
                          expensesClosed: viewModel.expensesClosed,
                          goalsMissing: viewModel.goalsMissing,
                          goalsClosed: viewModel.goalsClosed,
                          onOpenWizard: _openWizard,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingTransfers extends StatelessWidget {
  const _PendingTransfers({
    required this.expensesMissing,
    required this.expensesClosed,
    required this.goalsMissing,
    required this.goalsClosed,
    required this.onOpenWizard,
  });

  final bool expensesMissing;
  final bool expensesClosed;
  final bool goalsMissing;
  final bool goalsClosed;
  final VoidCallback onOpenWizard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ainda não há transferências finais',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Fecha os dois meses no assistente para veres o resumo definitivo.',
            style: AppTextStyles.bodyMuted(colors),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusRow(
            label: 'Despesas',
            missing: expensesMissing,
            closed: expensesClosed,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusRow(
            label: 'Objetivos',
            missing: goalsMissing,
            closed: goalsClosed,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Abrir assistente',
            icon: Icons.lock_outlined,
            isFullWidth: true,
            onPressed: onOpenWizard,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.missing,
    required this.closed,
  });

  final String label;
  final bool missing;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = missing
        ? AppBadgeStyles.muted(colors)
        : closed
        ? AppBadgeStyles.closed(colors)
        : AppBadgeStyles.open(colors);
    final status = missing
        ? 'Por criar'
        : closed
        ? 'Fechado'
        : 'Aberto';
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMuted(colors))),
        AppBadge(label: status, style: style),
      ],
    );
  }
}
