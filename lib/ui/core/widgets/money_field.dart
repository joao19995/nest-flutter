import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/app_saved_tick.dart';

/// An editable euro amount that saves on focus loss (or on submit), with a
/// confirmation tick and a haptic tap.
///
/// [value] is what the field shows; [originalValue] is the persisted amount —
/// a save is skipped when the parsed input matches it, and it is restored when
/// the input is not a valid amount.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.value,
    required this.originalValue,
    required this.onSave,
    this.isLast = false,
  });

  /// The amount shown in the field.
  final double value;

  /// The persisted amount, used to detect changes and to reset invalid input.
  final double originalValue;

  final ValueChanged<double> onSave;

  /// Whether this is the last editable amount: the keyboard action becomes
  /// "done" instead of moving to the next field.
  final bool isLast;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this, duration: AppMotion.confirm);
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        _parse(_controller.text) != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _tick.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _save();
    }
  }

  void _save() {
    final parsed = _parse(_controller.text);
    if (parsed == null || parsed < 0) {
      _controller.text = _format(widget.originalValue);
      return;
    }
    if (parsed == widget.originalValue) {
      return;
    }
    widget.onSave(parsed);
    HapticFeedback.selectionClick();
    _tick.forward(from: 0);
  }

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static String _format(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSavedTick(animation: _tick),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: AppSizes.moneyFieldWidth,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            textInputAction: widget.isLast
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: const InputDecoration(
              isDense: true,
              suffixText: '€',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
