import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/domain/models/goal_month_view.dart';
import 'package:nest/domain/models/goal_year.dart';
import 'package:nest/domain/models/month_settlement.dart';
import 'package:nest/domain/models/month_transfers.dart';
import 'package:nest/domain/models/monthly_plan.dart';

MonthlyPlan _expensePlan({MonthSettlement? settlement}) => MonthlyPlan(
  id: 'm1',
  month: '2026-01',
  closed: true,
  entries: const [],
  summary: const ExpenseMonthSummary(
    month: '2026-01',
    status: ExpenseMonthStatus.closed,
    planned: 1000,
    actual: 1000,
    progressPct: 100,
    over: false,
    filledEntries: 0,
    totalEntries: 0,
  ),
  settlement: settlement,
);

MonthSettlement _settlement({bool noIncome = false}) => noIncome
    ? const MonthSettlement(
        status: SettlementStatus.noIncome,
        contributionRequired: 0,
        jointSurplus: 0,
        people: [],
        message: 'Sem rendimento.',
      )
    : const MonthSettlement(
        status: SettlementStatus.ok,
        contributionRequired: 600,
        jointSurplus: 0,
        people: [
          MonthSettlementPerson(
            personId: 'p1',
            personName: 'João',
            income: 2500,
            quota: 300,
            personalActual: 620,
            transferToJoint: 0,
            transferToPerson: 320,
          ),
          MonthSettlementPerson(
            personId: 'p2',
            personName: 'Nathalia',
            income: 2000,
            quota: 300,
            personalActual: 0,
            transferToJoint: 300,
            transferToPerson: 0,
          ),
        ],
      );

List<GoalMonthQuota> _quotas({String personId = 'p1'}) => [
  GoalMonthQuota(
    personId: personId,
    name: 'João',
    earning: 2500,
    share: 0.625,
    amount: 625,
    parts: const [
      GoalMonthQuotaPart(goalId: 'g1', name: 'Viagem', amount: 600),
      GoalMonthQuotaPart(goalId: 'g2', name: 'Carro', amount: 25),
    ],
  ),
  const GoalMonthQuota(
    personId: 'p2',
    name: 'Nathalia',
    earning: 1500,
    share: 0.375,
    amount: 375,
    parts: [GoalMonthQuotaPart(goalId: 'g2', name: 'Carro', amount: 375)],
  ),
];

GoalMonthView _goalView({bool closed = true, List<GoalMonthQuota>? quotas}) =>
    GoalMonthView(
      plan: GoalPlan(
        id: 'p1',
        month: '2026-01',
        availableAmount: 1000,
        closed: closed,
        allocations: const [],
      ),
      availableAmount: 1000,
      funding: const MonthFunding(
        month: '2026-01',
        incomeNormal: 2500,
        bonus: 0,
        dailyAllowance: 500,
        contributionRequired: 1000,
        available: 1000,
      ),
      totals: const GoalMonthTotals(
        planned: 1000,
        actual: 1000,
        reserved: 1000,
      ),
      quotas: quotas ?? _quotas(),
    );

void main() {
  test('merges the expenses settlement and the goals quotas by person', () {
    final transfers = MonthTransfers.fromMonths(
      month: '2026-01',
      expenses: _expensePlan(settlement: _settlement()),
      goals: _goalView(),
    );

    expect(transfers.closed, isTrue);
    expect(transfers.people, hasLength(2));
    final joao = transfers.people.firstWhere((p) => p.personName == 'João');
    expect(joao.personId, 'p1');
    expect(joao.fromJoint, 320);
    expect(joao.toGoals, 625);
    expect(joao.goals, hasLength(2));
    final nathalia = transfers.people.firstWhere(
      (p) => p.personName == 'Nathalia',
    );
    expect(nathalia.toJoint, 300);
    expect(nathalia.toGoals, 375);

    expect(transfers.totals.toJoint, 300);
    expect(transfers.totals.fromJoint, 320);
    expect(transfers.totals.toGoals, 1000);
    expect(transfers.goalsReserved, 1000);
    expect(transfers.goalsHasIncome, isTrue);
  });

  test('keeps the goal transfers when the settlement has no income', () {
    final transfers = MonthTransfers.fromMonths(
      month: '2026-01',
      expenses: _expensePlan(settlement: _settlement(noIncome: true)),
      goals: _goalView(),
    );

    expect(transfers.closed, isTrue);
    expect(transfers.expenses?.status, SettlementStatus.noIncome);
    expect(transfers.people, hasLength(2));
    expect(transfers.totals.toGoals, 1000);
  });

  test('is partial when a month is missing or open', () {
    final noGoals = MonthTransfers.fromMonths(
      month: '2026-01',
      expenses: _expensePlan(settlement: _settlement()),
      goals: null,
    );
    expect(noGoals.closed, isFalse);
    expect(noGoals.people, hasLength(2));
    expect(noGoals.totals.toGoals, 0);

    final openGoals = MonthTransfers.fromMonths(
      month: '2026-01',
      expenses: _expensePlan(settlement: _settlement()),
      goals: _goalView(closed: false),
    );
    expect(openGoals.closed, isFalse);
  });

  test('falls back to the name when the ids are missing', () {
    final transfers = MonthTransfers.fromMonths(
      month: '2026-01',
      expenses: _expensePlan(
        settlement: const MonthSettlement(
          status: SettlementStatus.ok,
          contributionRequired: 300,
          jointSurplus: 0,
          people: [
            MonthSettlementPerson(
              personId: '',
              personName: 'João',
              income: 2500,
              quota: 300,
              personalActual: 100,
              transferToJoint: 200,
              transferToPerson: 0,
            ),
          ],
        ),
      ),
      goals: _goalView(
        quotas: const [
          GoalMonthQuota(
            personId: '',
            name: 'João',
            earning: 2500,
            share: 1,
            amount: 1000,
            parts: [
              GoalMonthQuotaPart(goalId: 'g1', name: 'Viagem', amount: 1000),
            ],
          ),
        ],
      ),
    );

    expect(transfers.people, hasLength(1));
    expect(transfers.people.first.toJoint, 200);
    expect(transfers.people.first.toGoals, 1000);
  });
}
