import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';
import 'package:nest/ui/core/widgets/widgets.dart';

/// Signature of the create-person callback injected into [PersonFormSheet].
typedef PersonSubmit =
    Future<bool> Function({
      required String name,
      required double dailySpendingPercentage,
      required int emergencyFundMonths,
    });

/// A bottom-sheet form that creates a person.
///
/// Stays open on failure (the message is surfaced by the list's retry state)
/// and closes on success.
class PersonFormSheet extends StatefulWidget {
  const PersonFormSheet({super.key, required this.onSubmit});

  final PersonSubmit onSubmit;

  @override
  State<PersonFormSheet> createState() => _PersonFormSheetState();
}

class _PersonFormSheetState extends State<PersonFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dailyController = TextEditingController(
    text: '25',
  );
  final TextEditingController _emergencyController = TextEditingController(
    text: '6',
  );

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dailyController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    final created = await widget.onSubmit(
      name: _nameController.text.trim(),
      dailySpendingPercentage: _parseDecimal(_dailyController.text),
      emergencyFundMonths: int.parse(_emergencyController.text.trim()),
    );
    if (!mounted) {
      return;
    }
    if (created) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  double _parseDecimal(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.length > 100) {
      return 'Indica um nome (1–100 caracteres).';
    }
    return null;
  }

  String? _validatePercentage(String? value) {
    final text = value?.trim() ?? '';
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite) {
      return 'Indica um número válido.';
    }
    return null;
  }

  String? _validateMonths(String? value) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) {
      return 'Indica um número inteiro ≥ 0.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppBreakpoints.pagePadding(context),
        right: AppBreakpoints.pagePadding(context),
        top: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nova pessoa', style: AppTextStyles.pageTitle),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: _validateName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _dailyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Gasto diário (%)',
                helperText: 'Percentagem do rendimento para gasto diário.',
              ),
              validator: _validatePercentage,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emergencyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fundo de emergência (meses)',
              ),
              validator: _validateMonths,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Guardar',
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
