import 'dart:async';

import 'package:drift/drift.dart';
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

  Future<void> syncCards(String deckId) => _syncService.syncCards(deckId);

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

  void _runSyncSilently(Future<void> Function() sync) {
    unawaited(sync().catchError((_) {}));
  }
}
