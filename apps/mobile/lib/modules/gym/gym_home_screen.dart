import 'package:flutter/material.dart';

/// Placeholder Gym dashboard. The real dashboard arrives in later phases;
/// this keeps "Start workout" as the obvious primary action from day one.
class GymHomeScreen extends StatelessWidget {
  const GymHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gym')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ready when you are', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Workout logging arrives in Phase 8. This build proves the app '
                'installs, opens offline and keeps data on this device.',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              const FilledButton(
                onPressed: null,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Start workout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
