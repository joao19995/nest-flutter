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

  /// Weekday abbreviations, indexed by `DateTime.weekday` (1 = Monday).
  static const List<String> _weekdayShort = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  /// Full weekday names, indexed by `DateTime.weekday` (1 = Monday).
  static const List<String> _weekdayFull = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
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

  /// Formats a date's month and year with its full, capitalised name.
  /// Example: `2026-10-20` → `"Outubro 2026"`.
  static String monthTitle(DateTime date) =>
      '${_monthNamesFull[date.month - 1]} ${date.year}';

  /// A three-letter weekday abbreviation (`1` = Monday).
  /// Example: `DateTime.monday` → `"Seg"`.
  static String weekdayShort(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return '';
    }
    return _weekdayShort[weekday - 1];
  }

  /// A long, human date with the full weekday.
  /// Example: `2026-10-20` → `"Terça-feira, 20 de outubro"`.
  static String dayLong(DateTime date) =>
      '${_weekdayFull[date.weekday - 1]}, ${date.day} de '
      '${_monthNames[date.month - 1]}';

  /// A compact date.
  /// Example: `2026-10-20` → `"20 out 2026"`.
  static String shortDate(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  /// A wall-clock time with zero-padded hour and minute.
  /// Example: `09:30`.
  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
