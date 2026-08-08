import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/identity/device_user_id.dart';
import 'deck_model.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(
    database: ref.watch(appDatabaseProvider),
    userId: ref.watch(deviceUserIdProvider),
  );
});

final decksStreamProvider = StreamProvider<List<DeckModel>>((ref) {
  return ref.watch(deckRepositoryProvider).watchDecks();
});

final decksPageProvider = StreamProvider.family<List<DeckModel>, int>((
  ref,
  limit,
) {
  return ref.watch(deckRepositoryProvider).watchDecksPage(limit: limit);
});

final deckStreamProvider = StreamProvider.family<DeckModel?, String>((
  ref,
  deckId,
) {
  return ref.watch(deckRepositoryProvider).watchDeck(deckId);
});

class DeckRepository {
  DeckRepository({required AppDatabase database, required String userId})
    : _database = database,
      _userId = userId;

  final AppDatabase _database;

  /// O dono dos decks: o próprio aparelho. Filtrar por ele é o que impede um
  /// backup importado de outra instalação de aparecer misturado.
  final String _userId;

  final Uuid _uuid = const Uuid();

  Stream<List<DeckModel>> watchDecks() {
    return _database.decksDao
        .watchAllDecks(userId: _userId)
        .map((decks) => decks.map(DeckModel.fromLocal).toList());
  }

  Stream<List<DeckModel>> watchDecksPage({required int limit}) {
    return _database.decksDao
        .watchDecksPage(userId: _userId, limit: limit)
        .map((decks) => decks.map(DeckModel.fromLocal).toList());
  }

  Future<int> countDecks() {
    return _database.decksDao.countDecks(userId: _userId);
  }

  Stream<DeckModel?> watchDeck(String deckId) {
    return _database.decksDao
        .watchDeckById(deckId, userId: _userId)
        .map((deck) => deck == null ? null : DeckModel.fromLocal(deck));
  }

  Future<String> createDeck({
    required String title,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: id,
        userId: _userId,
        title: title.trim(),
        description: Value(_nullableTrim(description)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
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
        createdAt: deck.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      ),
    );
  }

  /// Apaga o deck por tombstone, junto com seus cards.
  ///
  /// O `deletedAt` fica: é ele que faz reimportar um backup antigo não
  /// ressuscitar o que o usuário tirou — apagar é uma edição como outra
  /// qualquer, e o import compara `updatedAt`.
  Future<void> deleteDeck(String deckId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.cardsDao.markCardsForDeckDeleted(deckId, now);
    await _database.decksDao.markDeckDeleted(deckId, now);
    // A conversa não é exportada no backup e não precisa de tombstone: some
    // junto com o deck.
    await _database.chatMessagesDao.deleteMessagesForDeck(deckId);
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
