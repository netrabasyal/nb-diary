import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the on-device database.
///
/// In the browser this is SQLite compiled to WebAssembly. Drift picks the best
/// storage the browser supports (origin private file system, else IndexedDB)
/// and reports its choice through [onStorageChosen].
QueryExecutor openAppDatabase({void Function(String storage)? onStorageChosen}) {
  return driftDatabase(
    name: 'nb_diary',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) =>
          onStorageChosen?.call(result.chosenImplementation.name),
    ),
  );
}
