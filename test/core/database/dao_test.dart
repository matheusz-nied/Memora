import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('decks dao inserts, watches, and filters tombstones', () async {
    final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;

    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'user-1',
        title: 'Biology',
        description: const Value('Cell basics'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final watchedDecks = await database.decksDao.watchAllDecks().first;
    expect(watchedDecks, hasLength(1));
    expect(watchedDecks.single.title, 'Biology');

    await database.decksDao.markDeckDeleted('deck-1', now + 1);

    expect(await database.decksDao.getAllDecks(), isEmpty);

    final pendingDecks = await database.decksDao.getPendingSyncDecks();
    expect(pendingDecks, hasLength(1));
    expect(pendingDecks.single.deletedAt, now + 1);
    expect(pendingDecks.single.syncPending, isTrue);
  });

  test('cards dao updates progress and persists insight locally', () async {
    final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;
    final dueDate = DateTime(2026, 5, 5);

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'What is ATP?',
        back: 'Cellular energy currency.',
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.cardsDao.updateProgress(
      cardId: 'card-1',
      easeFactor: 2.7,
      intervalDays: 3,
      dueDate: dueDate,
    );
    await database.cardsDao.updateInsight(
      cardId: 'card-1',
      insight: 'ATP stores and transfers energy in cells.',
    );

    final card = await database.cardsDao.getCardById('card-1');
    expect(card, isNotNull);
    expect(card!.easeFactor, 2.7);
    expect(card.intervalDays, 3);
    expect(card.dueDate, dueDate.millisecondsSinceEpoch);
    expect(card.insight, 'ATP stores and transfers energy in cells.');
    expect(card.syncPending, isTrue);
  });

  test('cards dao filters deleted cards but keeps tombstone pending', () async {
    final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Front',
        back: 'Back',
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.cardsDao.markCardDeleted('card-1', now + 1);

    expect(await database.cardsDao.getCardsForDeck('deck-1'), isEmpty);

    final pendingCards = await database.cardsDao.getPendingSyncCards(
      deckId: 'deck-1',
    );
    expect(pendingCards, hasLength(1));
    expect(pendingCards.single.deletedAt, now + 1);
    expect(pendingCards.single.syncPending, isTrue);
  });
}
