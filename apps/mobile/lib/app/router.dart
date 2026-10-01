import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../modules/settings/settings_screen.dart';
import '../platform/module/nb_module.dart';

/// Builds the app's router from the registered modules.
/// Each module gets a tab; Settings belongs to the shell.
GoRouter buildRouter(List<NbModule> modules) {
  final branches = [
    for (final module in modules)
      StatefulShellBranch(routes: [module.route]),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ];

  return GoRouter(
    initialLocation: '/${modules.first.id}',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            _ShellScaffold(shell: shell, modules: modules),
        branches: branches,
      ),
    ],
  );
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell, required this.modules});

  final StatefulNavigationShell shell;
  final List<NbModule> modules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          for (final module in modules)
            NavigationDestination(
              icon: Icon(module.icon),
              selectedIcon: Icon(module.selectedIcon),
              label: module.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
