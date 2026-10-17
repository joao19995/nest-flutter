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

  /// The month (`YYYY-MM`) from which this record applies.
  String get validFromMonth => validFrom.substring(0, 7);

  /// The record that applies to [month] (`YYYY-MM`) for [personId].
  ///
  /// Returns the record with the latest [validFrom] at or before [month], or
  /// `null` when the person has no income up to that month.
  static PersonIncome? applicableFor(
    List<PersonIncome> incomes,
    String personId,
    String month,
  ) {
    PersonIncome? latest;
    for (final income in incomes) {
      if (income.personId != personId ||
          income.validFromMonth.compareTo(month) > 0) {
        continue;
      }
      if (latest == null || income.validFrom.compareTo(latest.validFrom) >= 0) {
        latest = income;
      }
    }
    return latest;
  }
}
