import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/month_transfers.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';
import 'package:nest/ui/features/goals/goal_icons.dart';

/// Builds the plain-text summary shared over messaging apps.
///
/// This only formats values already present in [transfers]; it derives no new
/// financial value.
String _summaryText(MonthTransfers transfers) {
  final lines = <String>[
    'Transferências de ${AppFormatters.monthName(transfers.month)}',
  ];
  for (final person in transfers.people) {
    if (person.toJoint > 0.005) {
      lines.add(
        '${person.personName} → Conjunta: '
        '${AppFormatters.currency(person.toJoint)}',
      );
    }
    if (person.fromJoint > 0.005) {
      lines.add(
        'Conjunta → ${person.personName}: '
        '${AppFormatters.currency(person.fromJoint)}',
      );
    }
    if (person.toGoals > 0.005) {
      if (person.goals.isEmpty) {
        lines.add(
          '${person.personName} → Objetivos: '
          '${AppFormatters.currency(person.toGoals)}',
        );
      } else {
        for (final part in person.goals) {
          lines.add(
            '${person.personName} → ${part.name}: '
            '${AppFormatters.currency(part.amount)}',
          );
        }
      }
    }
  }
  if (lines.length == 1) {
    lines.add('Sem transferências neste mês.');
  }
  return lines.join('\n');
}

/// The read-only, definitive transfers of a closed month: combined totals, a
/// per-person summary and the detailed expenses/goals sections.
class MonthTransfersSummary extends StatelessWidget {
  const MonthTransfersSummary({
    super.key,
    required this.transfers,
    required this.iconKeyByGoal,
  });

  final MonthTransfers transfers;
  final Map<String, String?> iconKeyByGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalsCard(transfers: transfers),
        if (transfers.people.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _PeopleCard(people: transfers.people),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ExpensesCard(settlement: transfers.expenses),
        const SizedBox(height: AppSpacing.lg),
        _GoalsCard(transfers: transfers, iconKeyByGoal: iconKeyByGoal),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Copiar resumo',
          icon: Icons.copy_outlined,
          variant: AppButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: _summaryText(transfers)),
            );
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Resumo copiado.')));
          },
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.transfers});

  final MonthTransfers transfers;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumo final', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            label: 'Para a conta conjunta',
            value: AppFormatters.currency(transfers.totals.toJoint),
            color: colors.ink,
          ),
          _SummaryRow(
            label: 'Da conta conjunta',
            value: AppFormatters.currency(transfers.totals.fromJoint),
            color: colors.ink,
          ),
          _SummaryRow(
            label: 'Para os objetivos',
            value: AppFormatters.currency(transfers.totals.toGoals),
            color: colors.ink,
          ),
          if (transfers.goalsReserved > 0.005 && transfers.goals.isEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Há ${AppFormatters.currency(transfers.goalsReserved)} reservados '
              'sem rendimento configurado para calcular quotas.',
              style: AppTextStyles.helper(colors),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.people});

  final List<MonthTransfersPerson> people;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumo por pessoa', style: AppTextStyles.sectionHeading),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < people.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            _PersonRow(person: people[index]),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

  final MonthTransfersPerson person;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lines = <Widget>[
      if (person.toJoint > 0.005)
        _MoneyLine(
          label: 'Para a conjunta',
          value: person.toJoint,
          color: colors.ink,
        ),
      if (person.fromJoint > 0.005)
        _MoneyLine(
          label: 'A receber da conjunta',
          value: person.fromJoint,
          color: colors.ink,
        ),
      if (person.toGoals > 0.005)
        _MoneyLine(
          label: 'Para objetivos',
          value: person.toGoals,
          color: colors.ink,
        ),
    ];
    if (lines.isEmpty) {
      lines.add(Text('Está certo', style: AppTextStyles.small(colors)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.personName,
          style: AppTextStyles.label(colors).copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final line in lines) line,
      ],
    );
  }
}

class _ExpensesCard extends StatelessWidget {
  const _ExpensesCard({required this.settlement});

  final MonthSettlement? settlement;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settlement = this.settlement;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Transferências registadas',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.md),
          if (settlement == null)
            Text(
              'Sem liquidação de despesas registada.',
              style: AppTextStyles.bodyMuted(colors),
            )
          else if (settlement.status != SettlementStatus.ok)
            Text(
              settlement.message ?? 'Sem rendimento registado.',
              style: AppTextStyles.bodyMuted(colors),
            )
          else
            for (var index = 0; index < settlement.people.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              _SettlementRow(person: settlement.people[index]),
            ],
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.person});

  final MonthSettlementPerson person;

  @override
  Widget build(BuildContext context) {
    final toJoint = person.transfersToJoint;
    final toPerson = person.transfersToPerson;
    final amount = toJoint
        ? person.transferToJoint
        : toPerson
        ? person.transferToPerson
        : null;
    return AppTransferFlow(
      name: person.personName,
      amount: amount,
      direction: toPerson
          ? AppTransferDirection.toPerson
          : AppTransferDirection.toJoint,
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.transfers, required this.iconKeyByGoal});

  final MonthTransfers transfers;
  final Map<String, String?> iconKeyByGoal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final transfersList = transfers.goals;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Transferências registadas',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: AppSpacing.md),
          if (transfersList.isEmpty)
            Text(
              _emptyMessage(transfers),
              style: AppTextStyles.bodyMuted(colors),
            )
          else
            for (var index = 0; index < transfersList.length; index++) ...[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              _GoalTransferRow(
                transfer: transfersList[index],
                iconKeyByGoal: iconKeyByGoal,
              ),
            ],
        ],
      ),
    );
  }

  static String _emptyMessage(MonthTransfers transfers) {
    if (transfers.goalsReserved <= 0.005) {
      return 'Sem valores reservados neste mês: nada a transferir.';
    }
    if (!transfers.goalsHasIncome) {
      return 'Sem rendimento configurado neste mês: não há quotas a transferir.';
    }
    return 'Sem transferências neste mês.';
  }
}

class _GoalTransferRow extends StatelessWidget {
  const _GoalTransferRow({required this.transfer, required this.iconKeyByGoal});

  final GoalMonthQuota transfer;
  final Map<String, String?> iconKeyByGoal;

  @override
  Widget build(BuildContext context) {
    final parts = transfer.parts;
    if (parts.isEmpty) {
      return AppTransferFlow(
        name: transfer.name,
        amount: transfer.amount,
        targetLabel: 'Objetivos',
        targetIcon: Icons.flag_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < parts.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          AppTransferFlow(
            name: transfer.name,
            amount: parts[index].amount,
            targetLabel: parts[index].name,
            targetIcon: GoalIcons.forKey(iconKeyByGoal[parts[index].goalId]),
          ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMuted(colors))),
          Text(
            value,
            style: AppTextStyles.label(colors).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.small(colors))),
          Text(
            AppFormatters.currency(value),
            style: AppTextStyles.label(colors).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
