/// Helpers for the `YYYY-MM` month keys the Nest API uses everywhere.
abstract final class MonthKey {
  /// The key for [year] and [month] (1-12).
  static String of(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  /// The current month's key.
  static String current() {
    final now = DateTime.now();
    return of(now.year, now.month);
  }

  /// Whole months from [from] to [to]. Positive when [to] is later.
  static int monthsBetween(String from, String to) {
    final fromParts = from.split('-');
    final toParts = to.split('-');
    final fromYear = int.tryParse(fromParts.isNotEmpty ? fromParts[0] : '');
    final fromMonth = int.tryParse(fromParts.length > 1 ? fromParts[1] : '');
    final toYear = int.tryParse(toParts.isNotEmpty ? toParts[0] : '');
    final toMonth = int.tryParse(toParts.length > 1 ? toParts[1] : '');
    if (fromYear == null ||
        fromMonth == null ||
        toYear == null ||
        toMonth == null) {
      return 0;
    }
    return (toYear - fromYear) * 12 + (toMonth - fromMonth);
  }

  /// [month] shifted by [delta] months, forward or back. Returns [month]
  /// unchanged when it cannot be parsed.
  static String shift(String month, int delta) {
    final parts = month.split('-');
    final year = int.tryParse(parts.isNotEmpty ? parts[0] : '');
    final number = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (year == null || number == null) {
      return month;
    }
    final shifted = DateTime(year, number + delta);
    return of(shifted.year, shifted.month);
  }
}
