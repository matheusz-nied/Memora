import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';

import '../../drift/generated/schema.dart';
import '../../drift/generated/schema_v1.dart' as v1;
import '../../drift/generated/schema_v2.dart' as v2;

/// Garante que o schema declarado no código continua igual ao snapshot da
/// versão correspondente e que toda migração intermediária roda limpa.
///
/// Quando uma tabela ou coluna mudar:
///   1. incrementar `AppDatabase.schemaVersion`
///   2. adicionar o passo em `AppDatabase.migration.onUpgrade`
///   3. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
///   4. `dart run drift_dev schema generate drift_schemas/ test/drift/generated/`
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('schema declarado corresponde ao snapshot de cada versão', () async {
    for (
      var version = 1;
      version <= AppDatabase.latestSchemaVersion;
      version++
    ) {
      final connection = await verifier.startAt(version);
      final database = AppDatabase(connection);

      await verifier.migrateAndValidate(database, version);
      await database.close();
    }
  });

  test(
    'v1 -> v2 preserva decks e cards e aplica o default de repetitions',
    () async {
      const deckId = 'deck-1';
      const cardId = 'card-1';
      final createdAt = DateTime(2026, 5, 2).millisecondsSinceEpoch;
      final dueDate = DateTime(2026, 5, 20).millisecondsSinceEpoch;

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insert(
            oldDb.decks,
            v1.DecksCompanion.insert(
              id: deckId,
              userId: 'user-1',
              title: 'Biologia',
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
          batch.insert(
            oldDb.cards,
            v1.CardsCompanion.insert(
              id: cardId,
              deckId: deckId,
              front: 'Mitocôndria',
              back: 'Organela responsável pela respiração celular',
              easeFactor: const Value(2.7),
              intervalDays: const Value(9),
              dueDate: dueDate,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
        },
        validateItems: (newDb) async {
          final decks = await newDb.select(newDb.decks).get();
          expect(decks, hasLength(1));
          expect(decks.single.title, 'Biologia');

          final cards = await newDb.select(newDb.cards).get();
          expect(cards, hasLength(1));

          final card = cards.single;
          expect(card.front, 'Mitocôndria');
          expect(card.easeFactor, closeTo(2.7, 0.0001));
          expect(card.intervalDays, 9);
          expect(card.dueDate, dueDate);
          // Coluna nova entra com o default sem apagar a linha existente.
          expect(card.repetitions, 0);

          // A tabela append-only de revisões nasce vazia.
          final reviews = await newDb.select(newDb.reviews).get();
          expect(reviews, isEmpty);
        },
      );
    },
  );
}
