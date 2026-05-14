import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Recurring'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: const Center(
        child: Text('Recurring', style: TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }
}