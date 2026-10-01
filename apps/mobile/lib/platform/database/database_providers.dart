import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The open database. Overridden at start-up in `main.dart` and in tests.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

/// Facts gathered while the app started.
class LaunchInfo {
  const LaunchInfo({required this.launchCount, required this.storage});

  final int launchCount;

  /// Which browser storage Drift chose, or "native" outside the browser.
  final String storage;
}

final launchInfoProvider = Provider<LaunchInfo>(
  (ref) => throw UnimplementedError('launchInfoProvider must be overridden'),
);
