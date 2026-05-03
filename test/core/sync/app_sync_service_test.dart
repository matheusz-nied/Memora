import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/contracts/remote_database_gateway.dart';
import 'package:memora/core/backend/models/backend_card.dart';
import 'package:memora/core/backend/models/backend_chat_message.dart';
import 'package:memora/core/backend/models/backend_deck.dart';
import 'package:memora/core/database/app_database.dart';
import 'package:memora/core/sync/app_sync_service.dart';

void main() {
  late AppDatabase database;
  late _FakeRemoteDatabaseGateway remote;
  late AppSyncService syncService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemoteDatabaseGateway();
    syncService = AppSyncService(
      database: database,
      remoteDatabase: remote,
      isOnline: () async => true,
      retryDelay: Duration.zero,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('syncDecks keeps pending local deck from being overwritten', () async {
    final now = DateTime(2026, 5, 2);
    remote.decks['deck-1'] = _deck(
      id: 'deck-1',
      title: 'Remote title',
      updatedAt: now.add(const Duration(days: 1)),
    );

    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'user-1',
        title: 'Local title',
        syncPending: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncDecks();

    final deck = await database.decksDao.getDeckById('deck-1');
    expect(deck, isNotNull);
    expect(deck!.title, 'Local title');
    expect(deck.syncPending, isFalse);
    expect(remote.decks['deck-1']!.title, 'Local title');
  });

  test('syncCards keeps pending local card from being overwritten', () async {
    final now = DateTime(2026, 5, 2);
    remote.cards['card-1'] = _card(
      id: 'card-1',
      front: 'Remote front',
      updatedAt: now.add(const Duration(days: 1)),
    );

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Local front',
        back: 'Local back',
        dueDate: now.millisecondsSinceEpoch,
        syncPending: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncCards('deck-1');

    final card = await database.cardsDao.getCardById('card-1');
    expect(card, isNotNull);
    expect(card!.front, 'Local front');
    expect(card.syncPending, isFalse);
    expect(remote.cards['card-1']!.front, 'Local front');
  });

  test('syncCards deletes remote card and clears local tombstone', () async {
    final now = DateTime(2026, 5, 2);
    remote.cards['card-1'] = _card(id: 'card-1');

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Front',
        back: 'Back',
        dueDate: now.millisecondsSinceEpoch,
        syncPending: const Value(true),
        deletedAt: Value(now.millisecondsSinceEpoch),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncCards('deck-1');

    expect(remote.deletedCards, contains('card-1'));
    expect(await database.cardsDao.getCardById('card-1'), isNull);
    expect(await database.cardsDao.getPendingSyncCards(), isEmpty);
  });

  test('syncDecks deletes remote deck and local cards for tombstone', () async {
    final now = DateTime(2026, 5, 2);
    remote.decks['deck-1'] = _deck(id: 'deck-1');

    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'user-1',
        title: 'Deleted deck',
        syncPending: const Value(true),
        deletedAt: Value(now.millisecondsSinceEpoch),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Front',
        back: 'Back',
        dueDate: now.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncDecks();

    expect(remote.deletedDecks, contains('deck-1'));
    expect(await database.decksDao.getDeckById('deck-1'), isNull);
    expect(await database.cardsDao.getCardsForDeck('deck-1'), isEmpty);
  });

  test('syncDecks removes local synced deck missing from remote', () async {
    final now = DateTime(2026, 5, 2);

    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'user-1',
        title: 'Remote deleted deck',
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Front',
        back: 'Back',
        dueDate: now.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncDecks();

    expect(await database.decksDao.getDeckById('deck-1'), isNull);
    expect(await database.cardsDao.getCardsForDeck('deck-1'), isEmpty);
  });

  test('syncCards removes local synced card missing from remote', () async {
    final now = DateTime(2026, 5, 2);

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Remote deleted front',
        back: 'Back',
        dueDate: now.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncCards('deck-1');

    expect(await database.cardsDao.getCardById('card-1'), isNull);
  });

  test('syncCards preserves pending local card missing from remote', () async {
    final now = DateTime(2026, 5, 2);

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Offline front',
        back: 'Offline back',
        dueDate: now.millisecondsSinceEpoch,
        syncPending: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncCards('deck-1');

    final card = await database.cardsDao.getCardById('card-1');
    expect(card, isNotNull);
    expect(card!.front, 'Offline front');
    expect(remote.cards['card-1']!.front, 'Offline front');
  });

  test('syncPendingCards retries remote upsert before succeeding', () async {
    final now = DateTime(2026, 5, 2);
    remote.failUpsertCardAttempts = 2;

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Front',
        back: 'Back',
        dueDate: now.millisecondsSinceEpoch,
        syncPending: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await syncService.syncPendingCards();

    expect(remote.upsertCardCalls, 3);
    expect((await database.cardsDao.getCardById('card-1'))!.syncPending, false);
  });

  test('syncPendingCards keeps pending card when retries fail', () async {
    final now = DateTime(2026, 5, 2);
    remote.failUpsertCardAttempts = 3;

    await database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: 'card-1',
        deckId: 'deck-1',
        front: 'Front',
        back: 'Back',
        dueDate: now.millisecondsSinceEpoch,
        syncPending: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );

    await expectLater(syncService.syncPendingCards(), throwsException);

    final card = await database.cardsDao.getCardById('card-1');
    expect(card, isNotNull);
    expect(card!.syncPending, true);
    expect(remote.cards.containsKey('card-1'), false);
  });
}

BackendDeck _deck({
  String id = 'deck-1',
  String title = 'Deck',
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 5, 2);
  return BackendDeck(
    id: id,
    userId: 'user-1',
    title: title,
    agentName: 'Tutor',
    agentTemplate: 'general',
    agentLanguage: 'português',
    agentLevel: 'intermediário',
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

BackendCard _card({
  String id = 'card-1',
  String front = 'Front',
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 5, 2);
  return BackendCard(
    id: id,
    deckId: 'deck-1',
    front: front,
    back: 'Back',
    easeFactor: 2.5,
    intervalDays: 1,
    dueDate: now,
    createdAt: now,
    updatedAt: updatedAt ?? now,
  );
}

class _FakeRemoteDatabaseGateway implements RemoteDatabaseGateway {
  final Map<String, BackendDeck> decks = {};
  final Map<String, BackendCard> cards = {};
  final List<String> deletedDecks = [];
  final List<String> deletedCards = [];
  int failUpsertCardAttempts = 0;
  int upsertCardCalls = 0;

  @override
  Future<List<BackendDeck>> fetchDecks() async => decks.values.toList();

  @override
  Future<BackendDeck> upsertDeck(BackendDeck deck) async {
    decks[deck.id] = deck;
    return deck;
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    deletedDecks.add(deckId);
    decks.remove(deckId);
  }

  @override
  Future<List<BackendCard>> fetchCards(String deckId) async {
    return cards.values.where((card) => card.deckId == deckId).toList();
  }

  @override
  Future<BackendCard> upsertCard(BackendCard card) async {
    upsertCardCalls += 1;
    if (failUpsertCardAttempts > 0) {
      failUpsertCardAttempts -= 1;
      throw Exception('upsert card failed');
    }

    cards[card.id] = card;
    return card;
  }

  @override
  Future<void> deleteCard(String cardId) async {
    deletedCards.add(cardId);
    cards.remove(cardId);
  }

  @override
  Future<BackendCard> updateCardProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
    required DateTime updatedAt,
  }) async {
    final card = cards[cardId]!;
    final updated = BackendCard(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      dueDate: dueDate,
      insight: card.insight,
      createdAt: card.createdAt,
      updatedAt: updatedAt,
    );
    cards[cardId] = updated;
    return updated;
  }

  @override
  Future<BackendCard> updateCardInsight({
    required String cardId,
    required String insight,
    required DateTime updatedAt,
  }) async {
    final card = cards[cardId]!;
    final updated = BackendCard(
      id: card.id,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      dueDate: card.dueDate,
      insight: insight,
      createdAt: card.createdAt,
      updatedAt: updatedAt,
    );
    cards[cardId] = updated;
    return updated;
  }

  @override
  Future<List<BackendChatMessage>> fetchChatMessages(String deckId) async => [];

  @override
  Future<BackendChatMessage> insertChatMessage(
    BackendChatMessage message,
  ) async {
    return message;
  }
}
