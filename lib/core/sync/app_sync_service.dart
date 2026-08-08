import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_provider.dart';
import '../backend/contracts/remote_database_gateway.dart';
import '../config/app_mode.dart';
import '../database/app_database.dart';
import '../database/local_model_mappers.dart';
import '../utils/connectivity_service.dart';

class AppSyncService {
  AppSyncService({
    required AppDatabase database,
    required RemoteDatabaseGateway remoteDatabase,
    Future<bool> Function()? isOnline,
    Future<bool> Function()? canSync,
    String? Function()? currentUserId,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) : _database = database,
       _remoteDatabase = remoteDatabase,
       _isOnline = isOnline ?? (() async => true),
       _canSync = canSync ?? (() async => true),
       _currentUserId = currentUserId ?? (() => null),
       _retryDelay = retryDelay;

  final AppDatabase _database;
  final RemoteDatabaseGateway _remoteDatabase;
  final Future<bool> Function() _isOnline;
  final Future<bool> Function() _canSync;
  final String? Function() _currentUserId;
  final Duration _retryDelay;

  static const int _maxSyncAttempts = 3;

  Future<void> syncDecks({bool requireSync = false}) async {
    if (!await _shouldSync(requireSync: requireSync)) {
      return;
    }
    final userId = _currentUserId();
    if (userId == null) {
      if (requireSync) {
        throw StateError('Sessão expirada. Entre novamente para sincronizar.');
      }
      return;
    }

    final pendingDecks = await _database.decksDao.getPendingSyncDecks(
      userId: userId,
    );
    final protectedDeckIds = pendingDecks.map((deck) => deck.id).toSet();

    for (final deck in pendingDecks) {
      if (deck.deletedAt != null) {
        await _withRetry(() => _remoteDatabase.deleteDeck(deck.id));
        await _database.cardsDao.deleteCardsForDeckPermanently(deck.id);
        await _database.decksDao.deleteDeckPermanently(deck.id);
      } else {
        final syncedDeck = await _withRetry(
          () => _remoteDatabase.upsertDeck(deck.toBackendDeck()),
        );
        await _database.decksDao.upsertDeck(syncedDeck.toLocalDeckCompanion());
      }
    }

    final remoteDecks = await _withRetry(_remoteDatabase.fetchDecks);
    final remoteDeckIds = remoteDecks.map((deck) => deck.id).toSet();
    final decksToCache = remoteDecks
        .where((deck) => !protectedDeckIds.contains(deck.id))
        .map((deck) => deck.toLocalDeckCompanion())
        .toList();
    await _database.decksDao.upsertDecks(decksToCache);

    final syncedLocalDecks = await _database.decksDao.getSyncedDecks(
      userId: userId,
    );
    final remotelyDeletedDecks = syncedLocalDecks.where(
      (deck) =>
          !remoteDeckIds.contains(deck.id) &&
          !protectedDeckIds.contains(deck.id),
    );
    for (final deck in remotelyDeletedDecks) {
      await _database.cardsDao.deleteCardsForDeckPermanently(deck.id);
      await _database.decksDao.deleteDeckPermanently(deck.id);
    }
  }

  Future<void> syncCards(String deckId, {bool requireSync = false}) async {
    if (!await _shouldSync(requireSync: requireSync)) {
      return;
    }
    final userId = _currentUserId();
    if (userId == null) {
      if (requireSync) {
        throw StateError('Sessão expirada. Entre novamente para sincronizar.');
      }
      return;
    }
    final userDeckIds = await _database.decksDao.getDeckIdsForUser(userId);
    if (!userDeckIds.contains(deckId)) {
      return;
    }

    final pendingCards = await _database.cardsDao.getPendingSyncCards(
      deckId: deckId,
    );
    final protectedCardIds = pendingCards.map((card) => card.id).toSet();

    for (final card in pendingCards) {
      if (card.deletedAt != null) {
        await _withRetry(() => _remoteDatabase.deleteCard(card.id));
        await _database.cardsDao.deleteCardPermanently(card.id);
      } else {
        final syncedCard = await _withRetry(
          () => _remoteDatabase.upsertCard(card.toBackendCard()),
        );
        await _database.cardsDao.upsertCard(syncedCard.toLocalCardCompanion());
      }
    }

    final remoteCards = await _withRetry(
      () => _remoteDatabase.fetchCards(deckId),
    );
    final remoteCardIds = remoteCards.map((card) => card.id).toSet();
    final cardsToCache = remoteCards
        .where((card) => !protectedCardIds.contains(card.id))
        .map((card) => card.toLocalCardCompanion())
        .toList();
    await _database.cardsDao.upsertCards(cardsToCache);

    final syncedLocalCards = await _database.cardsDao.getSyncedCardsForDeck(
      deckId,
    );
    final remotelyDeletedCards = syncedLocalCards.where(
      (card) =>
          !remoteCardIds.contains(card.id) &&
          !protectedCardIds.contains(card.id),
    );
    for (final card in remotelyDeletedCards) {
      await _database.cardsDao.deleteCardPermanently(card.id);
    }
  }

  Future<void> syncPendingCards({bool requireSync = false}) async {
    if (!await _shouldSync(requireSync: requireSync)) {
      return;
    }
    final userId = _currentUserId();
    if (userId == null) {
      if (requireSync) {
        throw StateError('Sessão expirada. Entre novamente para sincronizar.');
      }
      return;
    }

    final userDeckIds = (await _database.decksDao.getDeckIdsForUser(
      userId,
    )).toSet();
    final pendingCards = await _database.cardsDao.getPendingSyncCards();
    for (final card in pendingCards.where(
      (card) => userDeckIds.contains(card.deckId),
    )) {
      if (card.deletedAt != null) {
        await _withRetry(() => _remoteDatabase.deleteCard(card.id));
        await _database.cardsDao.deleteCardPermanently(card.id);
      } else {
        final syncedCard = await _withRetry(
          () => _remoteDatabase.upsertCard(card.toBackendCard()),
        );
        await _database.cardsDao.upsertCard(syncedCard.toLocalCardCompanion());
      }
    }
  }

  /// Envia as revisões pendentes. Só push: a tabela é append-only, então não
  /// há conflito a resolver nem deleção remota a propagar.
  Future<void> syncPendingReviews({bool requireSync = false}) async {
    if (!await _shouldSync(requireSync: requireSync)) {
      return;
    }
    final userId = _currentUserId();
    if (userId == null) {
      if (requireSync) {
        throw StateError('Sessão expirada. Entre novamente para sincronizar.');
      }
      return;
    }

    final userDeckIds = (await _database.decksDao.getDeckIdsForUser(
      userId,
    )).toSet();

    final pending = await _database.reviewsDao.getPendingSyncReviews();
    final mine = pending
        .where((review) => userDeckIds.contains(review.deckId))
        .toList();
    if (mine.isEmpty) {
      return;
    }

    await _withRetry(
      () => _remoteDatabase.insertReviews(
        mine.map((review) => review.toBackendReview(userId: userId)).toList(),
      ),
    );
    await _database.reviewsDao.markSynced(mine.map((review) => review.id));
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= _maxSyncAttempts; attempt += 1) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        if (attempt == _maxSyncAttempts) {
          break;
        }

        await Future<void>.delayed(_retryDelay * attempt);
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  Future<bool> _shouldSync({required bool requireSync}) async {
    if (!await _canSync()) {
      if (requireSync) {
        throw StateError('Sessão expirada. Entre novamente para sincronizar.');
      }
      return false;
    }

    if (!await _isOnline()) {
      if (requireSync) {
        throw StateError(
          'Sem conexão. Conecte-se à internet para sincronizar.',
        );
      }
      return false;
    }

    return true;
  }
}

final appSyncServiceProvider = Provider<AppSyncService>((ref) {
  final backendClient = ref.watch(backendClientProvider);

  return AppSyncService(
    database: ref.watch(appDatabaseProvider),
    remoteDatabase: backendClient.database,
    isOnline: ref.watch(connectivityServiceProvider).isOnline,
    // No modo local existe sessão (a identidade do aparelho), mas não existe
    // remoto para onde sincronizar. Sem este corte, cada deck aberto dispara
    // um fetch que só serve para lançar.
    canSync: () async =>
        kIsCloudMode && backendClient.auth.currentSession != null,
    currentUserId: () => backendClient.auth.currentSession?.user.id,
  );
});

final appAutoSyncProvider = Provider<void>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  var isSyncing = false;

  Future<void> runGlobalPendingSync() async {
    if (isSyncing) {
      return;
    }

    isSyncing = true;
    try {
      if (!await connectivityService.isOnline()) {
        return;
      }

      final syncService = ref.read(appSyncServiceProvider);
      await syncService.syncDecks();
      await syncService.syncPendingCards();
      await syncService.syncPendingReviews();
    } catch (error, stackTrace) {
      debugPrint('Global pending sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Sync failures leave pending rows intact for the next online attempt.
    } finally {
      isSyncing = false;
    }
  }

  unawaited(runGlobalPendingSync());
  ref.listen<AsyncValue<bool>>(onlineStatusProvider, (previous, next) {
    final wasOnline =
        previous?.maybeWhen(data: (value) => value, orElse: () => false) ??
        false;
    final isOnline = next.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
    if (!wasOnline && isOnline) {
      unawaited(runGlobalPendingSync());
    }
  });
});
