import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';

import '../../drift/generated/schema.dart';
import '../../drift/generated/schema_v1.dart' as v1;
import '../../drift/generated/schema_v2.dart' as v2;
import '../../drift/generated/schema_v3.dart' as v3;
import '../../drift/generated/schema_v4.dart' as v4;
import '../../drift/generated/schema_v5.dart' as v5;

/// Garante que o schema declarado no código continua igual ao snapshot da
/// versão correspondente e que toda migração roda limpa, sem perder dado.
///
/// Quando uma tabela ou coluna mudar:
///   1. incrementar `AppDatabase.latestSchemaVersion`
///   2. adicionar o passo em `AppDatabase.migration.onUpgrade`, guardado por
///      `from` **e** `to`
///   3. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
///   4. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift/generated/`
///   5. repontar os testes de integridade abaixo para a versão nova
///
/// As duas flags do passo 4 não são opcionais: sem elas o gerador reescreve os
/// snapshots antigos sem data classes nem companions, e os testes de migração
/// que inserem dados param de compilar.
///
/// **Os testes de integridade sempre terminam na última versão.** É o caminho
/// real — quem abre o app depois de meses pula direto de onde parou para o
/// schema atual — e evita uma armadilha do drift: um passo antigo que chama
/// `migrator.createTable(reviewsTable)` cria a tabela com a forma **de hoje**,
/// não com a que ela tinha naquela versão. Validar um passo intermediário
/// contra o snapshot da época acusaria uma diferença que nunca acontece em
/// produção.
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

  test('v1 -> v4 preserva decks e cards e cria o que faltava', () async {
    const deckId = 'deck-1';
    const cardId = 'card-1';
    final createdAt = DateTime(2026, 5, 2).millisecondsSinceEpoch;
    final dueDate = DateTime(2026, 5, 20).millisecondsSinceEpoch;

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 4,
      createOld: v1.DatabaseAtV1.new,
      createNew: v4.DatabaseAtV4.new,
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

        // As duas tabelas que ainda não existiam na v1 nascem vazias.
        expect(await newDb.select(newDb.reviews).get(), isEmpty);
        expect(await newDb.select(newDb.chatMessages).get(), isEmpty);
      },
    );
  });

  test('v2 -> v4 preserva o histórico e cria a tabela de chat', () async {
    const deckId = 'deck-1';
    final createdAt = DateTime(2026, 7, 1).millisecondsSinceEpoch;

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 4,
      createOld: v2.DatabaseAtV2.new,
      createNew: v4.DatabaseAtV4.new,
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

        // A conversa nasce vazia: antes da v3 ela nem era guardada.
        expect(await newDb.select(newDb.chatMessages).get(), isEmpty);
      },
    );
  });

  test('v3 -> v4 derruba sync_pending sem perder linha nenhuma', () async {
    const deckId = 'deck-1';
    final createdAt = DateTime(2026, 8, 1).millisecondsSinceEpoch;

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.decks,
          v3.DecksCompanion.insert(
            id: deckId,
            userId: 'user-1',
            title: 'Biologia',
            // Justamente a coluna que a v4 elimina. Vale gravar com valor: o
            // risco da migração é a recriação da tabela levar junto o que
            // devia ficar.
            syncPending: const Value(1),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
        batch.insert(
          oldDb.cards,
          v3.CardsCompanion.insert(
            id: 'card-1',
            deckId: deckId,
            front: 'Mitocôndria',
            back: 'Respiração celular',
            easeFactor: const Value(2.7),
            intervalDays: const Value(9),
            repetitions: const Value(3),
            dueDate: createdAt,
            syncPending: const Value(1),
            insight: const Value('Organela de dupla membrana.'),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
        batch.insert(
          oldDb.reviews,
          v3.ReviewsCompanion.insert(
            id: 'review-1',
            cardId: 'card-1',
            deckId: deckId,
            rating: 2,
            easeBefore: 2.5,
            easeAfter: 2.6,
            intervalBefore: 1,
            intervalAfter: 6,
            reviewedAt: createdAt,
            syncPending: const Value(1),
          ),
        );
        batch.insert(
          oldDb.chatMessages,
          v3.ChatMessagesCompanion.insert(
            id: 'msg-1',
            deckId: deckId,
            role: 'user',
            content: 'O que é ATP?',
            createdAt: createdAt,
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
        expect(card.repetitions, 3);
        expect(card.insight, 'Organela de dupla membrana.');

        final reviews = await newDb.select(newDb.reviews).get();
        expect(reviews, hasLength(1));
        expect(reviews.single.rating, 2);
        expect(reviews.single.easeAfter, closeTo(2.6, 0.0001));

        final messages = await newDb.select(newDb.chatMessages).get();
        expect(messages, hasLength(1));
        expect(messages.single.content, 'O que é ATP?');
      },
    );
  });

  test('v4 -> v5 preserva vencimento e reconstrói estado FSRS', () async {
    const deckId = 'deck-1';
    const cardId = 'card-1';
    final createdAt = DateTime(2026, 8, 1, 9).millisecondsSinceEpoch;
    final updatedAt = createdAt + 1234;
    final dueDate = DateTime(2026, 8, 20, 18).millisecondsSinceEpoch;
    final reviewedAt = DateTime(2026, 8, 10, 12).millisecondsSinceEpoch;

    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.cards,
          v4.CardsCompanion.insert(
            id: cardId,
            deckId: deckId,
            front: 'Mitocôndria',
            back: 'Respiração celular',
            repetitions: const Value(4),
            intervalDays: const Value(9),
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
        batch.insert(
          oldDb.reviews,
          v4.ReviewsCompanion.insert(
            id: 'review-1',
            cardId: cardId,
            deckId: deckId,
            rating: 2,
            easeBefore: 2.5,
            easeAfter: 2.5,
            intervalBefore: 1,
            intervalAfter: 9,
            reviewedAt: reviewedAt,
          ),
        );
      },
      validateItems: (newDb) async {
        final card = (await newDb.select(newDb.cards).get()).single;
        expect(card.dueDate, dueDate);
        expect(card.updatedAt, updatedAt);
        expect(card.fsrsState, 2);
        expect(card.stability, isNotNull);
        expect(card.difficulty, isNotNull);
        expect(card.lastReview, reviewedAt);

        final review = (await newDb.select(newDb.reviews).get()).single;
        expect(review.reviewKind, 0);
      },
    );
  });

  test(
    'v1 -> v5 adiciona estado novo sem reabrir card como revisado',
    () async {
      const deckId = 'deck-1';
      const cardId = 'card-1';
      final createdAt = DateTime(2026, 8, 1).millisecondsSinceEpoch;
      final dueDate = DateTime(2026, 8, 30).millisecondsSinceEpoch;

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 5,
        createOld: v1.DatabaseAtV1.new,
        createNew: v5.DatabaseAtV5.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insert(
            oldDb.cards,
            v1.CardsCompanion.insert(
              id: cardId,
              deckId: deckId,
              front: 'Pergunta',
              back: 'Resposta',
              dueDate: dueDate,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
        },
        validateItems: (newDb) async {
          final card = (await newDb.select(newDb.cards).get()).single;
          expect(card.dueDate, dueDate);
          expect(card.fsrsState, 1);
          expect(card.fsrsStep, 0);
          expect(card.stability, isNull);
          expect(await newDb.select(newDb.reviews).get(), isEmpty);
        },
      );
    },
  );
}
