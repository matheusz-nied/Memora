import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import 'card_model.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(database: ref.watch(appDatabaseProvider));
});

final cardsStreamProvider = StreamProvider.family<List<CardModel>, String>((
  ref,
  deckId,
) {
  return ref.watch(cardRepositoryProvider).watchCards(deckId);
});

final cardStreamProvider = StreamProvider.family<CardModel?, String>((
  ref,
  cardId,
) {
  return ref.watch(cardRepositoryProvider).watchCard(cardId);
});

/// Fim do dia local. Um card que vence hoje entra na sessão de hoje.
DateTime endOfDay(DateTime moment) {
  return DateTime(moment.year, moment.month, moment.day, 23, 59, 59, 999);
}

typedef DueCardsQuery = ({String deckId, int newCardLimit});

/// Cards a estudar hoje neste deck.
final dueCardsStreamProvider =
    StreamProvider.family<List<CardModel>, DueCardsQuery>((ref, query) {
      return ref
          .watch(cardRepositoryProvider)
          .watchDueCards(query.deckId, newCardLimit: query.newCardLimit);
    });

typedef CardsPageQuery = ({String deckId, int limit});

final cardsPageProvider =
    StreamProvider.family<List<CardModel>, CardsPageQuery>((ref, query) {
      return ref
          .watch(cardRepositoryProvider)
          .watchCardsPage(query.deckId, limit: query.limit);
    });

class CardRepository {
  CardRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Stream<List<CardModel>> watchCards(String deckId) {
    return _database.cardsDao
        .watchCardsForDeck(deckId)
        .map((cards) => cards.map(CardModel.fromLocal).toList());
  }

  Stream<List<CardModel>> watchCardsPage(String deckId, {required int limit}) {
    return _database.cardsDao
        .watchCardsPage(deckId: deckId, limit: limit)
        .map((cards) => cards.map(CardModel.fromLocal).toList());
  }

  Stream<CardModel?> watchCard(String cardId) {
    return _database.cardsDao
        .watchCardById(cardId)
        .map((card) => card == null ? null : CardModel.fromLocal(card));
  }

  /// Cards vencidos hoje, já com o limite diário de cards novos aplicado.
  Stream<List<CardModel>> watchDueCards(
    String deckId, {
    required int newCardLimit,
    DateTime? now,
  }) {
    return _database.cardsDao
        .watchDueCards(
          deckId: deckId,
          dueBefore: endOfDay(now ?? DateTime.now()).millisecondsSinceEpoch,
          newCardLimit: newCardLimit,
        )
        .map((cards) => cards.map(CardModel.fromLocal).toList());
  }

  Future<int> countDueCards(String deckId, {DateTime? now}) {
    return _database.cardsDao.countDueCards(
      deckId: deckId,
      dueBefore: endOfDay(now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  Future<int> countCards(String deckId) {
    return _database.cardsDao.countCardsForDeck(deckId);
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
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      ),
    );
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
        insight: Value(card.insight),
        createdAt: card.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteCard(CardModel card) async {
    await _database.cardsDao.markCardDeleted(
      card.id,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Grava o novo agendamento do card e a revisão correspondente na mesma
  /// transação: sem isso o histórico pode divergir do estado do card se o app
  /// morrer entre as duas escritas.
  Future<void> updateProgress({
    required CardModel card,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime dueDate,
    required int rating,
    DateTime? reviewedAt,
  }) async {
    final reviewTime = reviewedAt ?? DateTime.now();

    await _database.transaction(() async {
      await _database.cardsDao.updateProgress(
        cardId: card.id,
        easeFactor: easeFactor,
        intervalDays: intervalDays,
        repetitions: repetitions,
        dueDate: dueDate,
      );
      await _database.reviewsDao.insertReview(
        ReviewsTableCompanion.insert(
          id: _uuid.v4(),
          cardId: card.id,
          deckId: card.deckId,
          rating: rating,
          easeBefore: card.easeFactor,
          easeAfter: easeFactor,
          intervalBefore: card.intervalDays,
          intervalAfter: intervalDays,
          reviewedAt: reviewTime.millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> updateInsight({
    required CardModel card,
    required String insight,
  }) async {
    await _database.cardsDao.updateInsight(cardId: card.id, insight: insight);
  }
}
