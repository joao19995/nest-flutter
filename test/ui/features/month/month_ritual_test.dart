import 'package:flutter_test/flutter_test.dart';
import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/theme/app_formatters.dart';
import 'package:nest/ui/features/month/month_ritual.dart';

MonthRitual _ritual({
  String month = '2026-10',
  ExpenseMonthStatus expensesStatus = ExpenseMonthStatus.missing,
  int filledEntries = 0,
  int totalEntries = 0,
  ExpenseMonthStatus goalsStatus = ExpenseMonthStatus.missing,
  double goalsReserved = 0,
  double goalsPlanned = 0,
}) => MonthRitual(
  month: month,
  expensesStatus: expensesStatus,
  filledEntries: filledEntries,
  totalEntries: totalEntries,
  goalsStatus: goalsStatus,
  goalsReserved: goalsReserved,
  goalsPlanned: goalsPlanned,
);

void main() {
  test('nothing created invites the user to start', () {
    final ritual = _ritual();

    expect(ritual.statusLabel, 'Por criar');
    expect(ritual.actionLabel, 'Começar');
    expect(ritual.currentStep?.label, 'Criar o mês');
    expect(ritual.wizardStartStep, 0);
    expect(ritual.nextAction, MonthRitualAction.closeMonth);
    expect(ritual.isClosed, isFalse);
    expect(ritual.doneCount, 0);
    expect(ritual.progress, 0);
  });

  test('open expenses with unfilled lines ask for the real amounts', () {
    final ritual = _ritual(
      expensesStatus: ExpenseMonthStatus.open,
      filledEntries: 2,
      totalEntries: 5,
    );

    expect(ritual.currentStep?.label, 'Preencher despesas reais');
    expect(ritual.currentStep?.detail, '2 de 5 preenchidas');
    expect(ritual.steps[0].isDone, isTrue);
    expect(ritual.steps[1].isCurrent, isTrue);
    for (var index = 2; index < ritual.steps.length; index++) {
      expect(ritual.steps[index].state, MonthRitualStepState.pending);
    }
    expect(ritual.statusLabel, 'Por fechar');
    expect(ritual.actionLabel, 'Continuar');
  });

  test('open expenses with every line filled ask to close them', () {
    final ritual = _ritual(
      expensesStatus: ExpenseMonthStatus.open,
      filledEntries: 5,
      totalEntries: 5,
    );

    expect(ritual.currentStep?.label, 'Fechar despesas');
  });

  test('closed expenses move the ritual on to the goals', () {
    final ritual = _ritual(
      expensesStatus: ExpenseMonthStatus.closed,
      filledEntries: 5,
      totalEntries: 5,
    );

    expect(ritual.currentStep?.label, 'Definir objetivos');
    expect(ritual.wizardStartStep, 1);
    expect(ritual.nextAction, MonthRitualAction.closeMonth);
  });

  test('open goals ask to close them and show reserved versus planned', () {
    final ritual = _ritual(
      expensesStatus: ExpenseMonthStatus.closed,
      filledEntries: 5,
      totalEntries: 5,
      goalsStatus: ExpenseMonthStatus.open,
      goalsReserved: 250,
      goalsPlanned: 300,
    );

    expect(ritual.currentStep?.label, 'Fechar objetivos');
    expect(ritual.steps[3].isDone, isTrue);
    expect(ritual.steps[3].detail, contains(AppFormatters.currency(250)));
    expect(ritual.steps[3].detail, contains(AppFormatters.currency(300)));
    expect(
      ritual.steps[3].detail,
      '${AppFormatters.currency(250)} de ${AppFormatters.currency(300)}',
    );
  });

  test('both months closed complete the ritual and invite the summary', () {
    final ritual = _ritual(
      expensesStatus: ExpenseMonthStatus.closed,
      filledEntries: 5,
      totalEntries: 5,
      goalsStatus: ExpenseMonthStatus.closed,
    );

    expect(ritual.currentStep, isNull);
    expect(ritual.isComplete, isTrue);
    expect(ritual.isClosed, isTrue);
    expect(ritual.statusLabel, 'Fechado');
    expect(ritual.actionLabel, 'Ver resumo');
    expect(ritual.nextAction, MonthRitualAction.transfers);
    expect(ritual.progress, 1);
  });

  test('done count and progress cover only the six steps', () {
    final ritual = _ritual(
      expensesStatus: ExpenseMonthStatus.closed,
      filledEntries: 5,
      totalEntries: 5,
    );

    expect(ritual.steps.length, 6);
    expect(ritual.doneCount, 3);
    expect(ritual.progress, 3 / 6);
  });

  test('missing expenses keep the ritual at the first step', () {
    final ritual = _ritual(goalsStatus: ExpenseMonthStatus.closed);

    expect(ritual.currentStep?.label, 'Criar o mês');
    expect(ritual.wizardStartStep, 0);
    expect(ritual.isClosed, isFalse);
  });
}
