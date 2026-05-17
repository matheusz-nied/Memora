import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/sync/app_sync_service.dart';
import '../auth/auth_repository.dart';
import 'deck_model.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(
    database: ref.watch(appDatabaseProvider),
    syncService: ref.watch(appSyncServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final decksStreamProvider = StreamProvider<List<DeckModel>>((ref) {
  return ref.watch(deckRepositoryProvider).watchDecks();
});

final deckStreamProvider = StreamProvider.family<DeckModel?, String>((
  ref,
  deckId,
) {
  return ref.watch(deckRepositoryProvider).watchDeck(deckId);
});

class DeckRepository {
  DeckRepository({
    required AppDatabase database,
    required AppSyncService syncService,
    required AuthRepository authRepository,
  }) : _database = database,
       _syncService = syncService,
       _authRepository = authRepository;

  final AppDatabase _database;
  final AppSyncService _syncService;
  final AuthRepository _authRepository;
  final Uuid _uuid = const Uuid();

  Stream<List<DeckModel>> watchDecks() {
    final userId = _authRepository.currentSession?.user.id;
    if (userId == null) {
      return Stream<List<DeckModel>>.value([]);
    }
    _runSyncSilently(syncDecks);
    return _database.decksDao
        .watchAllDecks(userId: userId)
        .map((decks) => decks.map(DeckModel.fromLocal).toList());
  }

  Stream<DeckModel?> watchDeck(String deckId) {
    final userId = _authRepository.currentSession?.user.id;
    if (userId == null) {
      return Stream<DeckModel?>.value(null);
    }
    return _database.decksDao
        .watchDeckById(deckId, userId: userId)
        .map((deck) => deck == null ? null : DeckModel.fromLocal(deck));
  }

  Future<void> syncDecks({bool requireSync = false}) {
    return _syncService.syncDecks(requireSync: requireSync);
  }

  Future<void> createDeck({required String title, String? description}) async {
    final session = _authRepository.currentSession;
    if (session == null) {
      throw StateError('Sessão expirada. Entre novamente.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: _uuid.v4(),
        userId: session.user.id,
        title: title.trim(),
        description: Value(_nullableTrim(description)),
        syncPending: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    _runSyncSilently(syncDecks);
  }

  Future<void> updateDeck({
    required DeckModel deck,
    required String title,
    String? description,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: deck.id,
        userId: deck.userId,
        title: title.trim(),
        description: Value(_nullableTrim(description)),
        agentName: Value(deck.agentName),
        agentPrompt: Value(deck.agentPrompt),
        agentTemplate: Value(deck.agentTemplate),
        agentLanguage: Value(deck.agentLanguage),
        agentLevel: Value(deck.agentLevel),
        syncPending: const Value(true),
        createdAt: deck.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      ),
    );
    _runSyncSilently(syncDecks);
  }

  Future<void> deleteDeck(String deckId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.cardsDao.markCardsForDeckDeleted(deckId, now);
    await _database.decksDao.markDeckDeleted(deckId, now);
    _runSyncSilently(syncDecks);
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _runSyncSilently(Future<void> Function() sync) {
    unawaited(
      sync().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Deck sync failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }),
    );
  }
}
