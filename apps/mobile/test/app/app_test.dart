import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_diary/app/app.dart';
import 'package:nb_diary/platform/database/app_database.dart';
import 'package:nb_diary/platform/database/database_providers.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          launchInfoProvider.overrideWithValue(
            const LaunchInfo(launchCount: 3, storage: 'opfsLocks'),
          ),
        ],
        child: const NbDiaryApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the Gym tab with Start workout as the main action',
      (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Gym'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start workout'), findsOneWidget);
  });

  testWidgets('Settings shows on-device storage facts', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Times opened'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('opfsLocks'), findsOneWidget);
  });
}
