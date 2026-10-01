import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_diary/platform/database/app_database.dart';

void main() {
  test('recordLaunch counts every launch', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.recordLaunch(), 1);
    expect(await db.recordLaunch(), 2);
    expect(await db.readLaunchCount(), 2);
  });

  test('data survives closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('nb_diary_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/nb_diary.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await first.recordLaunch();
    await first.recordLaunch();
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await reopened.readLaunchCount(), 2);
  });

  test('foreign keys and full durability are switched on', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final foreignKeys = await db.customSelect('PRAGMA foreign_keys').getSingle();
    final synchronous = await db.customSelect('PRAGMA synchronous').getSingle();

    expect(foreignKeys.data.values.single, 1);
    expect(synchronous.data.values.single, 2); // 2 = FULL
  });
}
