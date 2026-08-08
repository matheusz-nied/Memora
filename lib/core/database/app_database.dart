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
  static const int latestSchemaVersion = 4;

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      // Cada passo olha `from` **e** `to`. Sem o `to`, uma migração 1→2 rodaria
      // também os passos de 3 e 4 — o que era inofensivo enquanto todos só
      // acrescentavam, e deixa de ser no primeiro que remove. É também o que
      // `SchemaVerifier` exercita, versão por versão, em
      // `test/core/database/migration_test.dart`.
      onUpgrade: (migrator, from, to) async {
        if (from < 2 && to >= 2) {
          // `repetitions` tem default 0, então as linhas existentes entram
          // como card novo e voltam a passar pelos learning steps — o que é o
          // comportamento desejado, já que não há histórico para reconstruir
          // o valor real.
          await migrator.addColumn(cardsTable, cardsTable.repetitions);
          await migrator.createTable(reviewsTable);
        }
        if (from < 3 && to >= 3) {
          // Tabela nova e vazia: nunca houve histórico de conversa para
          // migrar, porque antes dela a conversa não era guardada.
          await migrator.createTable(chatMessagesTable);
        }
        if (from < 4 && to >= 4) {
          // `sync_pending` marcava a linha que ainda não tinha subido para o
          // servidor. Não há servidor: a coluna só ocupava espaço e mentia
          // sobre um estado que nunca mudaria.
          //
          // O SQLite não dropa coluna direto — `alterTable` recria a tabela
          // com o schema novo e copia os dados. `columnTransformer` fica
          // vazio: as colunas que sobram mantêm nome e tipo.
          //
          // `TableMigration` é marcada como experimental no drift, mas é a
          // única API pública para isto e está documentada como tal. O
          // `ignore` é preferível a desligar o lint no projeto inteiro: se um
          // dia ela sumir, é aqui que o build precisa quebrar.
          // ignore: experimental_member_use
          await migrator.alterTable(TableMigration(decksTable));
          // ignore: experimental_member_use
          await migrator.alterTable(TableMigration(cardsTable));
          // ignore: experimental_member_use
          await migrator.alterTable(TableMigration(reviewsTable));
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
