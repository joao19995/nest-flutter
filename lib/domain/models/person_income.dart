/// A salary record for a household member.
///
/// [validFrom] is a calendar date (`YYYY-MM-DD`). The amount applies from that
/// month onwards until a newer record takes over.
class PersonIncome {
  const PersonIncome({
    required this.id,
    required this.personId,
    required this.amount,
    required this.validFrom,
  });

  final String id;
  final String personId;
  final double amount;
  final String validFrom;
}

/// A pending income row in the person form.
///
/// A null [id] marks a new record; an existing [id] updates that record.
class PersonIncomeDraft {
  const PersonIncomeDraft({
    this.id,
    required this.amount,
    required this.validFrom,
  });

  final String? id;
  final double amount;

  /// A calendar date, `YYYY-MM-DD`.
  final String validFrom;
}

/// A year in which a salary change raised the money available for goals.
///
/// Detected by the server when the incomes are saved — the before/after
/// comparison only exists there. The client only chooses where to allocate
/// [extra].
class PersonIncomeRaise {
  const PersonIncomeRaise({
    required this.year,
    required this.extra,
    required this.annualTotal,
    required this.validFromMonth,
  });

  final int year;

  /// The extra money for the year, in euros.
  final double extra;

  /// The year's total available for goals after the change, in euros.
  final double annualTotal;

  /// The month the new goal-template version would start, `YYYY-MM`.
  final String validFromMonth;
}

/// The result of a batch income save: the person's current history and the
/// raises detected by the server.
class SavedPersonIncomes {
  const SavedPersonIncomes({required this.incomes, required this.raises});

  final List<PersonIncome> incomes;
  final List<PersonIncomeRaise> raises;
}
