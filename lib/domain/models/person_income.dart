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
