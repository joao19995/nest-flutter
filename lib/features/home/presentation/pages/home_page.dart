import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(AppConstants.appName),
      ),
      body: const Center(
        child: Text('Welcome to Nest'),
      ),
    );
  }
}
