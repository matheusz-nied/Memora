import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';

import '../../drift/generated/schema.dart';
import '../../drift/generated/schema_v1.dart' as v1;
import '../../drift/generated/schema_v2.dart' as v2;
import '../../drift/generated/schema_v3.dart' as v3;

/// Garante que o schema declarado no código continua igual ao snapshot da
/// versão correspondente e que toda migração intermediária roda limpa.
///
/// Quando uma tabela ou coluna mudar:
///   1. incrementar `AppDatabase.schemaVersion`
///   2. adicionar o passo em `AppDatabase.migration.onUpgrade`
///   3. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
///   4. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift/generated/`
///
/// As duas flags do passo 4 não são opcionais: sem elas o gerador reescreve os
/// snapshots antigos sem data classes nem companions, e os testes de migração
/// que inserem dados param de compilar.
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

  test('v2 -> v3 preserva o histórico e cria a tabela de chat', () async {
    const deckId = 'deck-1';
    final createdAt = DateTime(2026, 7, 1).millisecondsSinceEpoch;

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.decks,
          v2.DecksCompanion.insert(
            id: deckId,
            userId: 'user-1',
            title: 'Biologia',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
        batch.insert(
          oldDb.cards,
          v2.CardsCompanion.insert(
            id: 'card-1',
            deckId: deckId,
            front: 'Mitocôndria',
            back: 'Respiração celular',
            repetitions: const Value(3),
            dueDate: createdAt,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
        batch.insert(
          oldDb.reviews,
          v2.ReviewsCompanion.insert(
            id: 'review-1',
            cardId: 'card-1',
            deckId: deckId,
            rating: 2,
            easeBefore: 2.5,
            easeAfter: 2.6,
            intervalBefore: 1,
            intervalAfter: 6,
            reviewedAt: createdAt,
          ),
        );
      },
      validateItems: (newDb) async {
        // O histórico de estudo é o dado mais caro de perder: não existe como
        // reconstruir uma revisão apagada.
        final reviews = await newDb.select(newDb.reviews).get();
        expect(reviews, hasLength(1));
        expect(reviews.single.rating, 2);

        final cards = await newDb.select(newDb.cards).get();
        expect(cards.single.repetitions, 3);
        expect(await newDb.select(newDb.decks).get(), hasLength(1));

        // A conversa nasce vazia: no modo nuvem ela vive no Postgres, e no
        // local nunca houve histórico para migrar.
        final messages = await newDb.select(newDb.chatMessages).get();
        expect(messages, isEmpty);
      },
    );
  });
}
