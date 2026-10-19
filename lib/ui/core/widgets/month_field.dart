import 'package:flutter/material.dart';
import 'package:nest/ui/core/month_key.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A year-and-month selector that yields a `YYYY-MM` key.
///
/// Shared by the template editors, whose versions are keyed by the first month
/// they apply to.
class MonthField extends StatefulWidget {
  const MonthField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Aplicável a partir',
  });

  /// The current key, `YYYY-MM`.
  final String value;

  final ValueChanged<String> onChanged;
  final String label;

  @override
  State<MonthField> createState() => _MonthFieldState();
}

class _MonthFieldState extends State<MonthField> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant MonthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _parse();
    }
  }

  void _parse() {
    final parts = widget.value.split('-');
    _year =
        int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? DateTime.now().year;
    _month =
        int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
  }

  void _emit() => widget.onChanged(MonthKey.of(_year, _month));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = <int>{
      for (var y = now.year - 2; y <= now.year + 5; y++) y,
      _year,
    }.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label(context.colors)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('month-field-year-$_year'),
                initialValue: _year,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ano'),
                items: [
                  for (final year in years)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _year = value);
                  _emit();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('month-field-month-$_month'),
                initialValue: _month,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mês'),
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(
                        AppFormatters.monthName(MonthKey.of(_year, month)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _month = value);
                  _emit();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
