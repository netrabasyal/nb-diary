import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Contract every NB Diary module (Gym now; Tasks, Habits, Diary later)
/// implements so the shell can host it without knowing its internals.
abstract interface class NbModule {
  /// Stable identifier, also used as the first URL segment.
  String get id;

  /// Label shown in the navigation bar.
  String get label;

  IconData get icon;
  IconData get selectedIcon;

  /// The module's top-level route. Its path must be `/$id`.
  GoRoute get route;
}
