import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Key/value facts about this installation, such as how many times it has opened.
/// Gym tables arrive from Phase 6 onwards.
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [AppMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  static const _launchCountKey = 'launch_count';

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Workout data must survive crashes and power loss, so trade a little
      // write speed for full durability.
      await customStatement('PRAGMA synchronous = FULL');
    },
  );

  /// Increments and returns the number of times the app has opened on this device.
  Future<int> recordLaunch() => transaction(() async {
    final next = await readLaunchCount() + 1;
    await into(appMeta).insertOnConflictUpdate(
      AppMetaCompanion.insert(key: _launchCountKey, value: '$next'),
    );
    return next;
  });

  Future<int> readLaunchCount() async {
    final row = await (select(
      appMeta,
    )..where((t) => t.key.equals(_launchCountKey))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }
}
