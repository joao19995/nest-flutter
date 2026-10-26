import 'package:nest/domain/models/expense_year_summary.dart';
import 'package:nest/ui/core/theme/app_formatters.dart';

/// How one ritual step reads in the checklist.
enum MonthRitualStepState {
  /// The step has already been completed.
  done,

  /// The step the user should tackle next.
  current,

  /// The step is still ahead, after the current one.
  pending,
}

/// One step of the month's closing ritual.
class MonthRitualStep {
  const MonthRitualStep({
    required this.label,
    required this.state,
    this.detail,
  });

  /// The step's short, user-facing title.
  final String label;

  /// Optional supporting line shown under the label.
  final String? detail;

  /// Whether the step is done, current or pending.
  final MonthRitualStepState state;

  /// True when the step has already been completed.
  bool get isDone => state == MonthRitualStepState.done;

  /// True when this is the step the user should tackle next.
  bool get isCurrent => state == MonthRitualStepState.current;
}

/// What the ritual's main button opens.
enum MonthRitualAction {
  /// Open the month-closing wizard.
  closeMonth,

  /// Open the transfers view.
  transfers,
}

/// The month's closing ritual: six ordered steps plus the action they invite.
///
/// Pure presentation: every input comes from the API, and this model only maps
/// that state onto checklist steps. It fetches nothing and derives no financial
/// rule.
class MonthRitual {
  MonthRitual({
    required this.month,
    required this.expensesStatus,
    required this.filledEntries,
    required this.totalEntries,
    this.expensesPlanned = 0,
    this.expensesActual = 0,
    required this.goalsStatus,
    required this.goalsReserved,
    required this.goalsPlanned,
  }) : steps = _buildSteps(
         expensesStatus: expensesStatus,
         filledEntries: filledEntries,
         totalEntries: totalEntries,
         goalsStatus: goalsStatus,
         goalsReserved: goalsReserved,
         goalsPlanned: goalsPlanned,
       );

  /// The month this ritual belongs to, formatted `YYYY-MM`.
  final String month;

  /// The expense month's lifecycle status.
  final ExpenseMonthStatus expensesStatus;

  /// How many expense lines already have a real amount.
  final int filledEntries;

  /// How many expense lines the month has.
  final int totalEntries;

  /// The month's planned expense total, in euros, as returned by the API
  /// summary.
  final double expensesPlanned;

  /// The month's actual expense total, in euros, as returned by the API
  /// summary.
  final double expensesActual;

  /// The goals month's lifecycle status.
  final ExpenseMonthStatus goalsStatus;

  /// The amount already reserved towards the goals, in euros.
  final double goalsReserved;

  /// The amount planned for the goals, in euros.
  final double goalsPlanned;

  /// The six ordered ritual steps.
  final List<MonthRitualStep> steps;

  /// True when the expense month is settled.
  bool get expensesClosed => expensesStatus == ExpenseMonthStatus.closed;

  /// True when the goals month is settled.
  bool get goalsClosed => goalsStatus == ExpenseMonthStatus.closed;

  /// True when both expense and goals months are settled.
  bool get isClosed => expensesClosed && goalsClosed;

  /// True when neither the expense nor the goals month exists yet.
  bool get isMissing =>
      expensesStatus == ExpenseMonthStatus.missing &&
      goalsStatus == ExpenseMonthStatus.missing;

  /// The ritual's overall state, as shown in the checklist header.
  String get statusLabel {
    if (isClosed) {
      return 'Fechado';
    }
    if (isMissing) {
      return 'Por criar';
    }
    return 'Por fechar';
  }

  /// The action the ritual's main button opens.
  MonthRitualAction get nextAction =>
      isClosed ? MonthRitualAction.transfers : MonthRitualAction.closeMonth;

  /// The wizard step to start from: goals once expenses are settled.
  int get wizardStartStep => expensesClosed ? 1 : 0;

  /// The label of the ritual's main button.
  String get actionLabel {
    if (isClosed) {
      return 'Ver resumo';
    }
    if (isMissing) {
      return 'Começar';
    }
    return 'Continuar';
  }

  /// How many of the six steps are done.
  int get doneCount => steps.where((step) => step.isDone).length;

  /// The share of steps done, from `0` to `1`.
  double get progress => doneCount / steps.length;

  /// The step the user should tackle next, or null when all are done.
  MonthRitualStep? get currentStep {
    for (final step in steps) {
      if (step.isCurrent) {
        return step;
      }
    }
    return null;
  }

  /// True when every step is done.
  bool get isComplete => doneCount == steps.length;

  static List<MonthRitualStep> _buildSteps({
    required ExpenseMonthStatus expensesStatus,
    required int filledEntries,
    required int totalEntries,
    required ExpenseMonthStatus goalsStatus,
    required double goalsReserved,
    required double goalsPlanned,
  }) {
    const labels = [
      'Criar o mês',
      'Preencher despesas reais',
      'Fechar despesas',
      'Definir objetivos',
      'Fechar objetivos',
      'Ver transferências',
    ];
    final goalsMonthExists = goalsStatus != ExpenseMonthStatus.missing;
    final expensesExists = expensesStatus != ExpenseMonthStatus.missing;
    final expensesClosed = expensesStatus == ExpenseMonthStatus.closed;
    final completed = [
      expensesExists,
      expensesExists &&
          (expensesClosed ||
              totalEntries == 0 ||
              filledEntries >= totalEntries),
      expensesClosed,
      goalsMonthExists,
      goalsStatus == ExpenseMonthStatus.closed,
      expensesClosed && goalsStatus == ExpenseMonthStatus.closed,
    ];
    final details = <String?>[
      null,
      totalEntries > 0 ? '$filledEntries de $totalEntries preenchidas' : null,
      null,
      goalsMonthExists
          ? '${AppFormatters.currency(goalsReserved)} de '
                '${AppFormatters.currency(goalsPlanned)}'
          : null,
      null,
      null,
    ];
    final currentIndex = completed.indexOf(false);

    return List<MonthRitualStep>.unmodifiable([
      for (var index = 0; index < labels.length; index++)
        MonthRitualStep(
          label: labels[index],
          detail: details[index],
          state: completed[index]
              ? MonthRitualStepState.done
              : index == currentIndex
              ? MonthRitualStepState.current
              : MonthRitualStepState.pending,
        ),
    ]);
  }
}
