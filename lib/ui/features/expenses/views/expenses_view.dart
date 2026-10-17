import 'package:flutter/material.dart';
import 'package:nest/ui/core/widgets/widgets.dart';

/// Placeholder for the expenses destination; content is not implemented yet.
class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: const AppEmpty(
        icon: Icons.receipt_long_outlined,
        message: 'Em breve.',
      ),
    );
  }
}
