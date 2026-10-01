import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../modules/gym/gym_module.dart';
import '../platform/module/nb_module.dart';
import 'router.dart';

/// Modules hosted by the shell, in navigation order.
const List<NbModule> registeredModules = [GymModule()];

class NbDiaryApp extends StatefulWidget {
  const NbDiaryApp({super.key});

  @override
  State<NbDiaryApp> createState() => _NbDiaryAppState();
}

class _NbDiaryAppState extends State<NbDiaryApp> {
  late final GoRouter _router = buildRouter(registeredModules);

  // Interim theme. The NB Diary design system replaces this in Phase 5.
  static const _seed = Color(0xFF1D55B5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NB Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
