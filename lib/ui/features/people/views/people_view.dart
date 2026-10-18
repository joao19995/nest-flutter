import 'package:flutter/material.dart';
import 'package:nest/ui/core/dependencies_scope.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/view_model_state.dart';
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

class _PeopleViewState extends State<PeopleView>
    with ViewModelState<PeopleView, PeopleViewModel> {
  @override
  PeopleViewModel createViewModel() {
    final dependencies = DependenciesScope.of(context);
    return PeopleViewModel(peopleRepository: dependencies.peopleRepository);
  }

  @override
  void onViewModelCreated(PeopleViewModel viewModel) => viewModel.load();

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Por pessoa',
                style: AppTextStyles.navSection(context.colors),
              ),
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
/// A dark, gradient panel so it reads as a summary banner rather than
/// another entry in the list below.
class _HouseholdIncomeHero extends StatelessWidget {
  const _HouseholdIncomeHero({required this.income});

  final double income;

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Renda do agregado',
            style: AppTextStyles.navSection(
              context.colors,
            ).copyWith(color: AppColors.onHeroMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedAmount(
            value: income,
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.onHero),
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
    return AppCard(
      onTap: () => _openHistory(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(name: person.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  person.name,
                  style: AppTextStyles.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppSizes.iconMedium,
                color: context.colors.faint,
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
                  accent: context.colors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Figure(
                  label:
                      'Gasto diário '
                      '(${AppFormatters.percentage(person.dailySpendingPercentage)})',
                  value: AppFormatters.currency(summary.dailySpending),
                  accent: context.colors.ink,
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
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => _SalaryHistorySheet(summary: summary),
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
        Text(label, style: AppTextStyles.small(context.colors)),
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
    return BottomSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.person.name, style: AppTextStyles.pageTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Histórico de vencimento',
            style: AppTextStyles.bodyMuted(context.colors),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (records.isEmpty)
            Text(
              'Sem vencimento registado.',
              style: AppTextStyles.bodyMuted(context.colors),
            )
          else
            for (var index = 0; index < records.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              _HistoryRow(
                label: AppFormatters.monthYear(records[index].validFrom),
                amount: AppFormatters.currency(records[index].amount),
                isCurrent:
                    records[index].id == summary.person.applicableIncomeId,
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
          AppBadge(label: 'ATUAL', style: AppBadgeStyles.open(context.colors)),
          const SizedBox(width: AppSpacing.md),
        ],
        Text(
          amount,
          style: AppTextStyles.body.copyWith(
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? context.colors.ink : context.colors.muted,
          ),
        ),
      ],
    );
  }
}
