import 'package:flutter/material.dart';
import 'package:nest/ui/core/widgets/widgets.dart';

/// Placeholder for the goals destination; content is not implemented yet.
class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objectivos')),
      body: const AppEmpty(icon: Icons.flag_outlined, message: 'Em breve.'),
    );
  }
}
