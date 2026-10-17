import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/people/view_models/people_view_model.dart';

/// A read-only overview of the household members and their salaries.
///
/// Each card shows the current monthly income and the amount allocated to
/// daily spending. Tapping a card opens the salary history.
class PeopleView extends StatefulWidget {
  const PeopleView({super.key});

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  PeopleViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) {
      return;
    }
    final dependencies = DependenciesScope.of(context);
    _viewModel = PeopleViewModel(
      peopleRepository: dependencies.peopleRepository,
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
      appBar: AppBar(title: const Text('Contas')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Padding(
          padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
          child: AsyncView(
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            isEmpty: viewModel.isEmpty,
            onRetry: viewModel.load,
            emptyMessage: 'Ainda não há pessoas.',
            child: _PeopleContent(viewModel: viewModel),
          ),
        ),
      ),
    );
  }
}

class _PeopleContent extends StatelessWidget {
  const _PeopleContent({required this.viewModel});

  final PeopleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final summaries = viewModel.summaries;
    final cards = <Widget>[
      for (final summary in summaries) _SalaryCard(summary: summary),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.md;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HouseholdIncomeHero(income: viewModel.householdIncome),
              const SizedBox(height: AppSpacing.xl),
              Text('POR PESSOA', style: AppTextStyles.navSection),
              const SizedBox(height: AppSpacing.md),
              if (isWide)
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.lg) / 2,
                        child: card,
                      ),
                  ],
                )
              else
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  cards[index],
                ],
            ],
          ),
        );
      },
    );
  }
}

/// The household total shown above the per-person breakdown.
///
/// Uses a tinted, shadowless panel so it reads as a summary banner rather than
/// another entry in the list below.
class _HouseholdIncomeHero extends StatelessWidget {
  const _HouseholdIncomeHero({required this.income});

  final double income;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppBreakpoints.cardPadding(context)),
      decoration: const BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RENDA DO AGREGADO',
            style: AppTextStyles.navSection.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppFormatters.currency(income),
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.summary});

  final PersonSalarySummary summary;

  @override
  Widget build(BuildContext context) {
    final person = summary.person;
    final name = person.name.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return AppCard(
      onTap: () => _openHistory(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initial: initial),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  person.name,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: AppSizes.iconMedium,
                color: AppColors.faint,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  label: 'Vencimento',
                  value: AppFormatters.currency(summary.monthlyIncome),
                  accent: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Figure(
                  label:
                      'Gasto diário '
                      '(${AppFormatters.percentage(person.dailySpendingPercentage)})',
                  value: AppFormatters.currency(summary.dailySpending),
                  accent: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => _SalaryHistorySheet(summary: summary),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.buttonHeight,
      height: AppSizes.buttonHeight,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.terraSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.label.copyWith(color: AppColors.terraDark),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.sectionHeading.copyWith(color: accent),
        ),
      ],
    );
  }
}

class _SalaryHistorySheet extends StatelessWidget {
  const _SalaryHistorySheet({required this.summary});

  final PersonSalarySummary summary;

  @override
  Widget build(BuildContext context) {
    final records = summary.incomes.reversed.toList(growable: false);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppBreakpoints.pagePadding(context),
        right: AppBreakpoints.pagePadding(context),
        top: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.person.name, style: AppTextStyles.pageTitle),
          const SizedBox(height: AppSpacing.xs),
          Text('Histórico de vencimento', style: AppTextStyles.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          if (records.isEmpty)
            Text('Sem vencimento registado.', style: AppTextStyles.bodyMuted)
          else
            for (var index = 0; index < records.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              _HistoryRow(
                label: AppFormatters.monthYear(records[index].validFrom),
                amount: AppFormatters.currency(records[index].amount),
                isCurrent: records[index].id == summary.currentIncomeId,
              ),
            ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.label,
    required this.amount,
    required this.isCurrent,
  });

  final String label;
  final String amount;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        if (isCurrent) ...[
          const AppBadge(label: 'ATUAL', style: AppBadgeStyles.open),
          const SizedBox(width: AppSpacing.md),
        ],
        Text(
          amount,
          style: AppTextStyles.body.copyWith(
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
