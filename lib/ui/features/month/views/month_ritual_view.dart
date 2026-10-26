import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';
import 'package:nest/ui/features/finances/views/close_month_wizard_view.dart';
import 'package:nest/ui/features/finances/views/month_transfers_view.dart';
import 'package:nest/ui/features/goals/views/goal_month_detail_view.dart';
import 'package:nest/ui/features/month/month_ritual.dart';
import 'package:nest/ui/features/month/view_models/month_ritual_view_model.dart';

/// Mês's closing ritual: the month's state, its six steps and the months
/// already closed this year.
///
/// Embedded under Mês, so it renders no [Scaffold] or [AppBar]. Every value
/// comes from the API; the view only lays it out.
class MonthRitualView extends StatefulWidget {
  const MonthRitualView({super.key, this.refreshSignal});

  /// Reloads the ritual when it changes.
  final Listenable? refreshSignal;

  @override
  State<MonthRitualView> createState() => _MonthRitualViewState();
}

class _MonthRitualViewState extends State<MonthRitualView>
    with ViewModelState<MonthRitualView, MonthRitualViewModel> {
  @override
  MonthRitualViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return MonthRitualViewModel(
      expensesRepository: dependencies.expensesRepository,
      goalsRepository: dependencies.goalsRepository,
    );
  }

  @override
  void onViewModelCreated(MonthRitualViewModel viewModel) => viewModel.load();

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onRefreshRequested);
  }

  @override
  void didUpdateWidget(covariant MonthRitualView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshRequested);
      widget.refreshSignal?.addListener(_onRefreshRequested);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshRequested);
    super.dispose();
  }

  void _onRefreshRequested() {
    if (mounted && hasViewModel) {
      viewModel.refresh();
    }
  }

  Future<void> _push(Widget destination) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => destination));
    if (mounted) {
      await viewModel.refresh();
    }
  }

  Future<void> _onPrimary() async {
    final ritual = viewModel.ritual;
    final month = viewModel.month;
    switch (ritual.nextAction) {
      case MonthRitualAction.closeMonth:
        await _push(
          CloseMonthWizardView(month: month, startStep: ritual.wizardStartStep),
        );
      case MonthRitualAction.transfers:
        await _push(MonthTransfersView(month: month));
    }
  }

  Future<void> _onOpenStep(int index) async {
    final month = viewModel.month;
    final Widget? destination = switch (index) {
      0 => CloseMonthWizardView(month: month),
      1 => MonthDetailView(month: month),
      2 => CloseMonthWizardView(month: month),
      3 => GoalMonthDetailView(month: month),
      4 => CloseMonthWizardView(month: month, startStep: 1),
      5 => MonthTransfersView(month: month),
      _ => null,
    };
    if (destination == null) {
      return;
    }
    await _push(destination);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: false,
            onRetry: viewModel.load,
            child: _RitualContent(
              viewModel: viewModel,
              onPrimary: _onPrimary,
              onOpenStep: _onOpenStep,
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualContent extends StatelessWidget {
  const _RitualContent({
    required this.viewModel,
    required this.onPrimary,
    required this.onOpenStep,
  });

  final MonthRitualViewModel viewModel;
  final VoidCallback onPrimary;
  final ValueChanged<int> onOpenStep;

  @override
  Widget build(BuildContext context) {
    final ritual = viewModel.ritual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RitualHero(
          ritual: ritual,
          month: viewModel.month,
          balanceFocus: viewModel.isBalanceFocus,
          canGoToPrevious: viewModel.canGoToPreviousMonth,
          canGoToNext: viewModel.canGoToNextMonth,
          onPrevious: viewModel.showPreviousMonth,
          onNext: viewModel.showNextMonth,
          onPrimary: onPrimary,
        ),
        const SizedBox(height: AppSpacing.lg),
        _RitualChecklist(steps: ritual.steps, onOpenStep: onOpenStep),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _RitualHero extends StatelessWidget {
  const _RitualHero({
    required this.ritual,
    required this.month,
    required this.balanceFocus,
    required this.canGoToPrevious,
    required this.canGoToNext,
    required this.onPrevious,
    required this.onNext,
    required this.onPrimary,
  });

  final MonthRitual ritual;
  final String month;
  final bool balanceFocus;
  final bool canGoToPrevious;
  final bool canGoToNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BALANÇO DE '
                  '${AppFormatters.monthName(ritual.month).toUpperCase()}',
                  style: AppTextStyles.navSection(
                    colors,
                  ).copyWith(color: AppColors.onHeroMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppPeriodStepper(
                label: AppFormatters.monthShort(month),
                onPrevious: canGoToPrevious ? onPrevious : null,
                onNext: canGoToNext ? onNext : null,
                previousTooltip: 'Mês anterior',
                nextTooltip: 'Mês seguinte',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  ritual.statusLabel,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: AppColors.onHero,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppProgressRing(
                progress: ritual.progress,
                label: AppFormatters.percentage(
                  (ritual.progress * 100).round(),
                ),
              ),
            ],
          ),
          if (balanceFocus) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'O mês anterior ainda não está fechado.',
              style: AppTextStyles.small(
                colors,
              ).copyWith(color: AppColors.onHeroMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: ritual.actionLabel,
            icon: ritual.isClosed
                ? Icons.receipt_long_outlined
                : Icons.lock_outline,
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            onPressed: onPrimary,
          ),
        ],
      ),
    );
  }
}

class _RitualChecklist extends StatelessWidget {
  const _RitualChecklist({required this.steps, required this.onOpenStep});

  final List<MonthRitualStep> steps;
  final ValueChanged<int> onOpenStep;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            _RitualStepRow(step: steps[index], onTap: () => onOpenStep(index)),
          ],
        ],
      ),
    );
  }
}

class _RitualStepRow extends StatelessWidget {
  const _RitualStepRow({required this.step, this.onTap});

  final MonthRitualStep step;
  final VoidCallback? onTap;

  static String _stateLabel(MonthRitualStepState state) => switch (state) {
    MonthRitualStepState.done => 'Concluído',
    MonthRitualStepState.current => 'Passo atual',
    MonthRitualStepState.pending => 'Pendente',
  };

  static String _semanticsLabel(MonthRitualStep step) {
    final detail = step.detail;
    final state = _stateLabel(step.state);
    return detail == null
        ? '${step.label}. $state'
        : '${step.label}. $state. $detail';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = step.isDone
        ? Icons.check_circle
        : step.isCurrent
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
    final iconColor = step.isDone || step.isCurrent
        ? colors.primary
        : colors.faint;
    final detail = step.detail;
    final onTap = this.onTap;
    return Semantics(
      container: true,
      button: onTap != null,
      label: _semanticsLabel(step),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Row(
                children: [
                  Icon(icon, size: AppSizes.iconLarge, color: iconColor),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.label,
                          style: AppTextStyles.body.copyWith(
                            color: step.isDone ? colors.muted : colors.ink,
                          ),
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(detail, style: AppTextStyles.small(colors)),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: AppSizes.iconSmall,
                      color: colors.faint,
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
