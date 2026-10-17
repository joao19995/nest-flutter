import 'package:flutter/material.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/expenses/view_models/expenses_view_model.dart';
import 'package:nest/ui/features/expenses/views/month_detail_view.dart';

/// A read-only panorama of the year's expenses: the total spent and a
/// month-by-month breakdown of what was spent against what was planned.
class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  ExpensesViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = ExpensesViewModel(
      expensesRepository: dependencies.expensesRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: _ExpensesContent(viewModel: viewModel),
        ),
      ),
    );
  }
}

class _ExpensesContent extends StatelessWidget {
  const _ExpensesContent({required this.viewModel});

  final ExpensesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final months = viewModel.months;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExpenseYearHero(
            year: viewModel.selectedYear,
            summary: viewModel.summary,
            canGoToPreviousYear: viewModel.canGoToPreviousYear,
            canGoToNextYear: viewModel.canGoToNextYear,
            onPreviousYear: viewModel.showPreviousYear,
            onNextYear: viewModel.showNextYear,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('POR MÊS', style: AppTextStyles.navSection),
          const SizedBox(height: AppSpacing.md),
          AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há despesas neste ano.',
            child: AppCard(
              padding: EdgeInsets.symmetric(
                horizontal: AppBreakpoints.cardPadding(context),
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < months.length; index++) ...[
                    if (index > 0) const Divider(),
                    _MonthRow(
                      month: months[index],
                      onTap: () => _openMonth(context, months[index].month),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMonth(BuildContext context, String month) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MonthDetailView(month: month)),
    );
  }
}

/// The year's total spent, shown above the monthly breakdown.
///
/// A tinted, shadowless panel that also hosts the year selector and a couple
/// of subtle secondary figures (year deviation and monthly rebalancing).
class _ExpenseYearHero extends StatelessWidget {
  const _ExpenseYearHero({
    required this.year,
    required this.summary,
    required this.canGoToPreviousYear,
    required this.canGoToNextYear,
    required this.onPreviousYear,
    required this.onNextYear,
  });

  final int year;
  final ExpenseYearSummary? summary;
  final bool canGoToPreviousYear;
  final bool canGoToNextYear;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    return Container(
      padding: EdgeInsets.all(AppBreakpoints.cardPadding(context)),
      decoration: const BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DESPESA DO ANO',
                  style: AppTextStyles.navSection.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _YearStepper(
                year: year,
                canGoBack: canGoToPreviousYear,
                canGoForward: canGoToNextYear,
                onPrevious: onPreviousYear,
                onNext: onNextYear,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppFormatters.currency(summary?.actual ?? 0),
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.primary),
          ),
          if (summary != null && summary.hasData) ...[
            const SizedBox(height: AppSpacing.sm),
            _DeviationLine(
              diff: summary.diff,
              diffPct: summary.diffPct,
              over: summary.over,
            ),
            if (summary.over && summary.remainingMonths > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              _RebalanceLine(
                perRemainingMonth: summary.perRemainingMonth,
                remainingMonths: summary.remainingMonths,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// A subtle line: how far the year deviates from the plan.
class _DeviationLine extends StatelessWidget {
  const _DeviationLine({
    required this.diff,
    required this.diffPct,
    required this.over,
  });

  final double diff;
  final double diffPct;
  final bool over;

  @override
  Widget build(BuildContext context) {
    if (diff == 0) {
      return Text(
        'Sem desvio do plano',
        style: AppTextStyles.small.copyWith(color: AppColors.primaryDark),
      );
    }
    final sign = diff > 0 ? '+' : '';
    final direction = over ? 'acima' : 'abaixo';
    return Text(
      'Desvio $sign${AppFormatters.currency(diff)}  ·  '
      '${AppFormatters.percentage(diffPct.round())} $direction',
      style: AppTextStyles.small.copyWith(
        color: over ? AppColors.over : AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A subtle line: what to set aside each remaining month to balance the year.
class _RebalanceLine extends StatelessWidget {
  const _RebalanceLine({
    required this.perRemainingMonth,
    required this.remainingMonths,
  });

  final double perRemainingMonth;
  final int remainingMonths;

  @override
  Widget build(BuildContext context) {
    final monthLabel = remainingMonths == 1
        ? '1 mês'
        : '$remainingMonths meses';
    return Text(
      'Para equilibrar ${AppFormatters.currency(perRemainingMonth)}/mês '
      'a poupar em $monthLabel',
      style: AppTextStyles.small.copyWith(color: AppColors.primaryDark),
    );
  }
}

/// A compact year selector: previous arrow, year, next arrow.
class _YearStepper extends StatelessWidget {
  const _YearStepper({
    required this.year,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.chevron_left,
            enabled: canGoBack,
            onTap: onPrevious,
          ),
          Text(
            '$year',
            style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
          ),
          _StepperButton(
            icon: Icons.chevron_right,
            enabled: canGoForward,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: AppSizes.iconMedium,
          color: enabled ? AppColors.primaryDark : AppColors.faint,
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.onTap});

  final ExpenseMonthSummary month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPlan = month.status != ExpenseMonthStatus.missing;
    final delta = month.actual - month.planned;
    final deltaLabel = delta >= 0
        ? '+${AppFormatters.currency(delta)}'
        : AppFormatters.currency(delta);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppFormatters.monthShort(month.month),
                      style: AppTextStyles.sectionHeading,
                    ),
                  ),
                  Text(
                    hasPlan ? AppFormatters.currency(month.actual) : '—',
                    style: AppTextStyles.sectionHeading.copyWith(
                      color: month.over ? AppColors.over : AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _MonthBar(month: month, hasPlan: hasPlan),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasPlan
                          ? 'Planeado ${AppFormatters.currency(month.planned)}'
                          : 'Sem plano',
                      style: AppTextStyles.small,
                    ),
                  ),
                  if (hasPlan)
                    Text(
                      deltaLabel,
                      style: AppTextStyles.small.copyWith(
                        color: month.over
                            ? AppColors.over
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.chevron_right,
                    size: AppSizes.iconSmall,
                    color: AppColors.faint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, required this.hasPlan});

  final ExpenseMonthSummary month;
  final bool hasPlan;

  @override
  Widget build(BuildContext context) {
    final factor = hasPlan
        ? (month.progressPct / 100).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return LinearProgressIndicator(
      value: factor,
      minHeight: AppSizes.progressBarHeight,
      backgroundColor: AppColors.lineSoft,
      color: month.over ? AppColors.over : AppColors.primary,
      borderRadius: AppRadius.fullAll,
    );
  }
}
