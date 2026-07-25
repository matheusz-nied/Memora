import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/constants/app_constants.dart';
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
    expect(
      await database.decksDao.watchAllDecks(userId: 'user-2').first,
      isEmpty,
    );

    await database.decksDao.markDeckDeleted('deck-1', now + 1);

    expect(await database.decksDao.getAllDecks(), isEmpty);

    final pendingDecks = await database.decksDao.getPendingSyncDecks();
    expect(pendingDecks, hasLength(1));
    expect(pendingDecks.single.deletedAt, now + 1);
    expect(pendingDecks.single.syncPending, isTrue);
  });

  test('decks dao watches a local page and counts visible decks', () async {
    final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;

    for (var index = 0; index < 35; index += 1) {
      await database.decksDao.upsertDeck(
        DecksTableCompanion.insert(
          id: 'deck-$index',
          userId: 'user-1',
          title: 'Deck $index',
          createdAt: now + index,
          updatedAt: now + index,
        ),
      );
    }
    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'other-user-deck',
        userId: 'user-2',
        title: 'Other user',
        createdAt: now + 100,
        updatedAt: now + 100,
      ),
    );
    await database.decksDao.markDeckDeleted('deck-34', now + 200);

    final page = await database.decksDao
        .watchDecksPage(userId: 'user-1', limit: AppConstants.kLocalPageSize)
        .first;

    expect(page, hasLength(AppConstants.kLocalPageSize));
    expect(page.first.id, 'deck-33');
    expect(
      page,
      isNot(contains(predicate<LocalDeck>((deck) => deck.id == 'deck-34'))),
    );
    expect(
      page,
      isNot(contains(predicate<LocalDeck>((deck) => deck.userId == 'user-2'))),
    );
    expect(await database.decksDao.countDecks(userId: 'user-1'), 34);
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
      repetitions: 2,
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

  test('cards dao watches a local page and counts visible cards', () async {
    final now = DateTime(2026, 5, 2).millisecondsSinceEpoch;

    for (var index = 0; index < 35; index += 1) {
      await database.cardsDao.upsertCard(
        CardsTableCompanion.insert(
          id: 'card-$index',
          deckId: 'deck-1',
          front: 'Front $index',
          back: 'Back $index',
          dueDate: now,
          createdAt: now + index,
          updatedAt: now + index,
        ),
      );
    }
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'other-deck-card',
        deckId: 'deck-2',
        front: 'Other',
        back: 'Other back',
        dueDate: now,
        createdAt: now + 100,
        updatedAt: now + 100,
      ),
    );
    await database.cardsDao.markCardDeleted('card-0', now + 200);

    final page = await database.cardsDao
        .watchCardsPage(deckId: 'deck-1', limit: AppConstants.kLocalPageSize)
        .first;

    expect(page, hasLength(AppConstants.kLocalPageSize));
    expect(page.first.id, 'card-1');
    expect(
      page,
      isNot(contains(predicate<LocalCard>((card) => card.id == 'card-0'))),
    );
    expect(
      page,
      isNot(contains(predicate<LocalCard>((card) => card.deckId == 'deck-2'))),
    );
    expect(await database.cardsDao.countCardsForDeck('deck-1'), 34);
  });

  test('cards dao marks every card in a deck as deleted', () async {
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
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-2',
        deckId: 'deck-2',
        front: 'Other',
        back: 'Other back',
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.cardsDao.markCardsForDeckDeleted('deck-1', now + 1);

    expect(await database.cardsDao.getCardsForDeck('deck-1'), isEmpty);
    expect(await database.cardsDao.getCardsForDeck('deck-2'), hasLength(1));

    final pendingCards = await database.cardsDao.getPendingSyncCards(
      deckId: 'deck-1',
    );
    expect(pendingCards, hasLength(1));
    expect(pendingCards.single.id, 'card-1');
    expect(pendingCards.single.deletedAt, now + 1);
  });
}
