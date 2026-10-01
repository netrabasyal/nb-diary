import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/database/database_providers.dart';

/// Shell-owned settings. Shows on-device facts that prove local storage works.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(launchInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('This device')),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Times opened'),
            trailing: Text('${info.launchCount}'),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Local storage'),
            trailing: Text(info.storage),
          ),
        ],
      ),
    );
  }
}
