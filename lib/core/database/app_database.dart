import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'daos/cards_dao.dart';
import 'daos/chat_messages_dao.dart';
import 'daos/decks_dao.dart';
import 'daos/reviews_dao.dart';
import 'tables/cards_table.dart';
import 'tables/chat_messages_table.dart';
import 'tables/decks_table.dart';
import 'tables/reviews_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [DecksTable, CardsTable, ReviewsTable, ChatMessagesTable],
  daos: [DecksDao, CardsDao, ReviewsDao, ChatMessagesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDatabase());

  /// Incrementar a cada mudança de schema, junto com um novo passo em
  /// [migration] e um snapshot em `drift_schemas/`. Ver AGENTS.md.
  static const int latestSchemaVersion = 3;

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // `repetitions` tem default 0, então as linhas existentes entram
          // como card novo e voltam a passar pelos learning steps — o que é o
          // comportamento desejado, já que não há histórico para reconstruir
          // o valor real.
          await migrator.addColumn(cardsTable, cardsTable.repetitions);
          await migrator.createTable(reviewsTable);
        }
        if (from < 3) {
          // Tabela nova e vazia: no modo nuvem o histórico continua no
          // Postgres, e no modo local nunca houve histórico para migrar.
          await migrator.createTable(chatMessagesTable);
        }
      },
    );
  }
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
