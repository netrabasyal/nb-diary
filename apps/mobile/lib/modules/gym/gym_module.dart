import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../platform/module/nb_module.dart';
import 'gym_home_screen.dart';

class GymModule implements NbModule {
  const GymModule();

  @override
  String get id => 'gym';

  @override
  String get label => 'Gym';

  @override
  IconData get icon => Icons.fitness_center_outlined;

  @override
  IconData get selectedIcon => Icons.fitness_center;

  @override
  GoRoute get route => GoRoute(
    path: '/gym',
    builder: (context, state) => const GymHomeScreen(),
  );
}
