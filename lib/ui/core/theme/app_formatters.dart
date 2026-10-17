import 'package:intl/intl.dart';

/// Nest value formatters.
///
/// Monetary values are single-currency EUR, always two decimals (matches the
/// web `formatEuro`). Never format money with raw string interpolation.
abstract final class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_PT',
    symbol: '€',
    decimalDigits: 2,
  );

  /// Formats a numeric value as a EUR currency string.
  /// Example: `12.9` → `"12,90 €"`.
  static String currency(num value) => _currency.format(value);
}
