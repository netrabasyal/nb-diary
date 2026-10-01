import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'platform/database/app_database.dart';
import 'platform/database/connection.dart';
import 'platform/database/database_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real paths (/gym) instead of /#/gym, so links and the back button behave.
  usePathUrlStrategy();

  var storage = kIsWeb ? 'unknown' : 'native';
  final database = AppDatabase(
    openAppDatabase(onStorageChosen: (chosen) => storage = chosen),
  );
  // Opening the database happens on first query, which also tells us
  // which browser storage Drift picked.
  final launchCount = await database.recordLaunch();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        launchInfoProvider.overrideWithValue(
          LaunchInfo(launchCount: launchCount, storage: storage),
        ),
      ],
      child: const NbDiaryApp(),
    ),
  );
}
