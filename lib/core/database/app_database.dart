import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'daos/cards_dao.dart';
import 'daos/decks_dao.dart';
import 'tables/cards_table.dart';
import 'tables/decks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [DecksTable, CardsTable], daos: [DecksDao, CardsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDatabase());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openDatabase() {
  // drift_flutter requires the `web` parameter on all web builds.
  // In debug mode the WASM worker fails to load (DDC vs dart2js), but Drift
  // automatically falls back to sharedIndexedDb — the app still works.
  // In release/profile mode WASM loads correctly via drift_worker.dart.js.
  return driftDatabase(
    name: 'memora',
    web: kIsWeb
        ? DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.dart.js'),
          )
        : null,
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final decksDaoProvider = Provider<DecksDao>((ref) {
  return ref.watch(appDatabaseProvider).decksDao;
});

final cardsDaoProvider = Provider<CardsDao>((ref) {
  return ref.watch(appDatabaseProvider).cardsDao;
});
