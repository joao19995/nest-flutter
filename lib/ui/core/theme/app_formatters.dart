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

  static final NumberFormat _percentage = NumberFormat.decimalPattern('pt_PT')
    ..maximumFractionDigits = 2;

  static const List<String> _monthNames = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static const List<String> _monthNamesFull = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  /// Formats a numeric value as a EUR currency string.
  /// Example: `12.9` → `"12,90 €"`.
  static String currency(num value) => _currency.format(value);

  /// Formats a value already expressed as a percentage.
  /// Example: `25` → `"25%"`, `12.5` → `"12,5%"`.
  static String percentage(num value) => '${_percentage.format(value)}%';

  /// Formats a calendar date (`YYYY-MM-DD`) as short month and year.
  /// Example: `"2025-01-01"` → `"jan 2025"`.
  static String monthYear(String isoDate) {
    final month = int.tryParse(
      isoDate.length >= 7 ? isoDate.substring(5, 7) : '',
    );
    final year = isoDate.length >= 4 ? isoDate.substring(0, 4) : isoDate;
    if (month == null || month < 1 || month > 12) {
      return isoDate;
    }
    return '${_monthNames[month - 1]} $year';
  }

  /// Formats a month (`YYYY-MM`) as a capitalised short month name.
  /// Example: `"2026-01"` → `"Jan"`.
  static String monthShort(String isoMonth) {
    final month = int.tryParse(
      isoMonth.length >= 7 ? isoMonth.substring(5, 7) : '',
    );
    if (month == null || month < 1 || month > 12) {
      return isoMonth;
    }
    final name = _monthNames[month - 1];
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  }

  /// Formats a month (`YYYY-MM`) as its full, capitalised name.
  /// Example: `"2026-10"` → `"Outubro"`.
  static String monthName(String isoMonth) {
    final month = int.tryParse(
      isoMonth.length >= 7 ? isoMonth.substring(5, 7) : '',
    );
    if (month == null || month < 1 || month > 12) {
      return isoMonth;
    }
    return _monthNamesFull[month - 1];
  }
}
