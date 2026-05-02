import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_provider.dart';
import '../backend/contracts/remote_database_gateway.dart';
import '../database/app_database.dart';
import '../database/local_model_mappers.dart';
import '../utils/connectivity_service.dart';

class AppSyncService {
  AppSyncService({
    required AppDatabase database,
    required RemoteDatabaseGateway remoteDatabase,
    Future<bool> Function()? isOnline,
  }) : _database = database,
       _remoteDatabase = remoteDatabase,
       _isOnline = isOnline ?? (() async => true);

  final AppDatabase _database;
  final RemoteDatabaseGateway _remoteDatabase;
  final Future<bool> Function() _isOnline;

  Future<void> syncDecks() async {
    if (!await _isOnline()) {
      return;
    }

    final pendingDecks = await _database.decksDao.getPendingSyncDecks();
    final protectedDeckIds = pendingDecks.map((deck) => deck.id).toSet();

    for (final deck in pendingDecks) {
      if (deck.deletedAt != null) {
        await _remoteDatabase.deleteDeck(deck.id);
        await _database.cardsDao.deleteCardsForDeckPermanently(deck.id);
        await _database.decksDao.deleteDeckPermanently(deck.id);
      } else {
        final syncedDeck = await _remoteDatabase.upsertDeck(
          deck.toBackendDeck(),
        );
        await _database.decksDao.upsertDeck(syncedDeck.toLocalDeckCompanion());
      }
    }

    final remoteDecks = await _remoteDatabase.fetchDecks();
    final decksToCache = remoteDecks
        .where((deck) => !protectedDeckIds.contains(deck.id))
        .map((deck) => deck.toLocalDeckCompanion())
        .toList();
    await _database.decksDao.upsertDecks(decksToCache);
  }

  Future<void> syncCards(String deckId) async {
    if (!await _isOnline()) {
      return;
    }

    final pendingCards = await _database.cardsDao.getPendingSyncCards(
      deckId: deckId,
    );
    final protectedCardIds = pendingCards.map((card) => card.id).toSet();

    for (final card in pendingCards) {
      if (card.deletedAt != null) {
        await _remoteDatabase.deleteCard(card.id);
        await _database.cardsDao.deleteCardPermanently(card.id);
      } else {
        final syncedCard = await _remoteDatabase.upsertCard(
          card.toBackendCard(),
        );
        await _database.cardsDao.upsertCard(syncedCard.toLocalCardCompanion());
      }
    }

    final remoteCards = await _remoteDatabase.fetchCards(deckId);
    final cardsToCache = remoteCards
        .where((card) => !protectedCardIds.contains(card.id))
        .map((card) => card.toLocalCardCompanion())
        .toList();
    await _database.cardsDao.upsertCards(cardsToCache);
  }

  Future<void> syncPendingCards() async {
    if (!await _isOnline()) {
      return;
    }

    final pendingCards = await _database.cardsDao.getPendingSyncCards();
    for (final card in pendingCards) {
      if (card.deletedAt != null) {
        await _remoteDatabase.deleteCard(card.id);
        await _database.cardsDao.deleteCardPermanently(card.id);
      } else {
        final syncedCard = await _remoteDatabase.upsertCard(
          card.toBackendCard(),
        );
        await _database.cardsDao.upsertCard(syncedCard.toLocalCardCompanion());
      }
    }
  }
}

final appSyncServiceProvider = Provider<AppSyncService>((ref) {
  return AppSyncService(
    database: ref.watch(appDatabaseProvider),
    remoteDatabase: ref.watch(backendClientProvider).database,
    isOnline: ref.watch(connectivityServiceProvider).isOnline,
  );
});
