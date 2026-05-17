import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/sync/app_sync_service.dart';
import 'card_model.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(
    database: ref.watch(appDatabaseProvider),
    syncService: ref.watch(appSyncServiceProvider),
  );
});

final cardsStreamProvider = StreamProvider.family<List<CardModel>, String>((
  ref,
  deckId,
) {
  return ref.watch(cardRepositoryProvider).watchCards(deckId);
});

typedef CardsPageQuery = ({String deckId, int limit});

final cardsPageProvider =
    StreamProvider.family<List<CardModel>, CardsPageQuery>((ref, query) {
      return ref
          .watch(cardRepositoryProvider)
          .watchCardsPage(query.deckId, limit: query.limit);
    });

class CardRepository {
  CardRepository({
    required AppDatabase database,
    required AppSyncService syncService,
  }) : _database = database,
       _syncService = syncService;

  final AppDatabase _database;
  final AppSyncService _syncService;
  final Uuid _uuid = const Uuid();

  Stream<List<CardModel>> watchCards(String deckId) {
    _runSyncSilently(() => syncCards(deckId));
    return _database.cardsDao
        .watchCardsForDeck(deckId)
        .map((cards) => cards.map(CardModel.fromLocal).toList());
  }

  Stream<List<CardModel>> watchCardsPage(String deckId, {required int limit}) {
    _runSyncSilently(() => syncCards(deckId));
    return _database.cardsDao
        .watchCardsPage(deckId: deckId, limit: limit)
        .map((cards) => cards.map(CardModel.fromLocal).toList());
  }

  Future<int> countCards(String deckId) {
    return _database.cardsDao.countCardsForDeck(deckId);
  }

  Future<void> syncCards(String deckId, {bool requireSync = false}) {
    return _syncService.syncCards(deckId, requireSync: requireSync);
  }

  Future<void> createCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final now = DateTime.now();
    await _database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: _uuid.v4(),
        deckId: deckId,
        front: front.trim(),
        back: back.trim(),
        dueDate: now.millisecondsSinceEpoch,
        syncPending: const Value(true),
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
    _runSyncSilently(() => syncCards(deckId));
  }

  Future<void> updateCard({
    required CardModel card,
    required String front,
    required String back,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.cardsDao.upsertCard(
      CardsTableCompanion.insert(
        id: card.id,
        deckId: card.deckId,
        front: front.trim(),
        back: back.trim(),
        easeFactor: Value(card.easeFactor),
        intervalDays: Value(card.intervalDays),
        dueDate: card.dueDate.millisecondsSinceEpoch,
        syncPending: const Value(true),
        insight: Value(card.insight),
        createdAt: card.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      ),
    );
    _runSyncSilently(() => syncCards(card.deckId));
  }

  Future<void> deleteCard(CardModel card) async {
    await _database.cardsDao.markCardDeleted(
      card.id,
      DateTime.now().millisecondsSinceEpoch,
    );
    _runSyncSilently(() => syncCards(card.deckId));
  }

  Future<void> updateProgress({
    required CardModel card,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
  }) async {
    await _database.cardsDao.updateProgress(
      cardId: card.id,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      dueDate: dueDate,
    );
    _runSyncSilently(() => syncCards(card.deckId));
  }

  void _runSyncSilently(Future<void> Function() sync) {
    unawaited(
      sync().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Card sync failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }),
    );
  }
}
