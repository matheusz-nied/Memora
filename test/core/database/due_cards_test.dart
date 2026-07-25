import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  final today = DateTime(2026, 5, 20);
  final endOfToday = DateTime(
    2026,
    5,
    20,
    23,
    59,
    59,
    999,
  ).millisecondsSinceEpoch;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'user-1',
        title: 'Biologia',
        createdAt: today.millisecondsSinceEpoch,
        updatedAt: today.millisecondsSinceEpoch,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> addCard({
    required String id,
    required DateTime dueDate,
    int repetitions = 0,
    int createdOffsetMinutes = 0,
    bool deleted = false,
  }) {
    final createdAt = today
        .add(Duration(minutes: createdOffsetMinutes))
        .millisecondsSinceEpoch;
    return database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: id,
        deckId: 'deck-1',
        front: 'front-$id',
        back: 'back-$id',
        repetitions: Value(repetitions),
        dueDate: dueDate.millisecondsSinceEpoch,
        deletedAt: Value(deleted ? createdAt : null),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
  }

  Future<List<String>> dueIds({int newCardLimit = 20}) async {
    final cards = await database.cardsDao
        .watchDueCards(
          deckId: 'deck-1',
          dueBefore: endOfToday,
          newCardLimit: newCardLimit,
        )
        .first;
    return cards.map((card) => card.id).toList();
  }

  test('traz vencidos e de hoje, mas não os futuros', () async {
    await addCard(id: 'atrasado', dueDate: DateTime(2026, 5, 18));
    await addCard(id: 'hoje', dueDate: DateTime(2026, 5, 20, 8));
    await addCard(id: 'amanha', dueDate: DateTime(2026, 5, 21));

    expect(await dueIds(), ['atrasado', 'hoje']);
  });

  test('inclui card que vence no fim do dia de hoje', () async {
    await addCard(id: 'tarde', dueDate: DateTime(2026, 5, 20, 23, 30));

    expect(await dueIds(), ['tarde']);
  });

  test('ignora cards apagados', () async {
    await addCard(id: 'vivo', dueDate: DateTime(2026, 5, 19));
    await addCard(id: 'morto', dueDate: DateTime(2026, 5, 19), deleted: true);

    expect(await dueIds(), ['vivo']);
  });

  test('ordena por vencimento e desempata por criação', () async {
    await addCard(
      id: 'b',
      dueDate: DateTime(2026, 5, 19),
      createdOffsetMinutes: 10,
    );
    await addCard(
      id: 'a',
      dueDate: DateTime(2026, 5, 19),
      createdOffsetMinutes: 5,
    );
    await addCard(id: 'antigo', dueDate: DateTime(2026, 5, 17));

    expect(await dueIds(), ['antigo', 'a', 'b']);
  });

  group('limite diário de cards novos', () {
    test('corta os novos excedentes mas mantém todas as revisões', () async {
      // Cards criados agora nascem com dueDate = now, então um deck
      // recém-gerado apareceria inteiro como vencido.
      for (var i = 0; i < 5; i++) {
        await addCard(
          id: 'novo-$i',
          dueDate: DateTime(2026, 5, 20),
          repetitions: 0,
          createdOffsetMinutes: i,
        );
      }
      for (var i = 0; i < 3; i++) {
        await addCard(
          id: 'revisao-$i',
          dueDate: DateTime(2026, 5, 19),
          repetitions: 4,
          createdOffsetMinutes: i,
        );
      }

      final ids = await dueIds(newCardLimit: 2);

      expect(ids.where((id) => id.startsWith('revisao')), hasLength(3));
      expect(ids.where((id) => id.startsWith('novo')), ['novo-0', 'novo-1']);
    });

    test('limite zero deixa a sessão só com revisões', () async {
      await addCard(id: 'novo', dueDate: DateTime(2026, 5, 20));
      await addCard(
        id: 'revisao',
        dueDate: DateTime(2026, 5, 19),
        repetitions: 1,
      );

      expect(await dueIds(newCardLimit: 0), ['revisao']);
    });

    test('limite negativo desliga o corte', () async {
      for (var i = 0; i < 4; i++) {
        await addCard(
          id: 'novo-$i',
          dueDate: DateTime(2026, 5, 20),
          createdOffsetMinutes: i,
        );
      }

      expect(await dueIds(newCardLimit: -1), hasLength(4));
    });
  });

  test('countDueCards bate com o total sem o corte de novos', () async {
    await addCard(id: 'a', dueDate: DateTime(2026, 5, 19));
    await addCard(id: 'b', dueDate: DateTime(2026, 5, 20));
    await addCard(id: 'futuro', dueDate: DateTime(2026, 6, 1));

    final count = await database.cardsDao.countDueCards(
      deckId: 'deck-1',
      dueBefore: endOfToday,
    );

    expect(count, 2);
  });

  test('a revisão é gravada junto com o progresso do card', () async {
    await addCard(id: 'card-1', dueDate: DateTime(2026, 5, 19));

    await database.transaction(() async {
      await database.cardsDao.updateProgress(
        cardId: 'card-1',
        easeFactor: 2.36,
        intervalDays: 3,
        repetitions: 2,
        dueDate: DateTime(2026, 5, 23),
      );
      await database.reviewsDao.insertReview(
        ReviewsTableCompanion.insert(
          id: 'review-1',
          cardId: 'card-1',
          deckId: 'deck-1',
          rating: 1,
          easeBefore: 2.5,
          easeAfter: 2.36,
          intervalBefore: 1,
          intervalAfter: 3,
          reviewedAt: today.millisecondsSinceEpoch,
        ),
      );
    });

    final card = await database.cardsDao.getCardById('card-1');
    expect(card!.repetitions, 2);
    expect(card.intervalDays, 3);
    expect(card.syncPending, isTrue);

    final pending = await database.reviewsDao.getPendingSyncReviews();
    expect(pending, hasLength(1));
    expect(pending.single.rating, 1);
    expect(pending.single.easeBefore, closeTo(2.5, 0.0001));

    await database.reviewsDao.markSynced(['review-1']);
    expect(await database.reviewsDao.getPendingSyncReviews(), isEmpty);
  });
}
