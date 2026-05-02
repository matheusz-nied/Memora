import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cards_table.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [CardsTable])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Stream<List<LocalCard>> watchCardsForDeck(String deckId) {
    return (select(cardsTable)
          ..where(
            (table) => table.deckId.equals(deckId) & table.deletedAt.isNull(),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch();
  }

  Future<List<LocalCard>> getCardsForDeck(String deckId) {
    return (select(cardsTable)
          ..where(
            (table) => table.deckId.equals(deckId) & table.deletedAt.isNull(),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
  }

  Future<LocalCard?> getCardById(String id) {
    return (select(cardsTable)
          ..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<LocalCard>> getPendingSyncCards({String? deckId}) {
    final query = select(cardsTable)
      ..where((table) => table.syncPending.equals(true));
    if (deckId != null) {
      query.where((table) => table.deckId.equals(deckId));
    }
    query.orderBy([(table) => OrderingTerm.asc(table.updatedAt)]);
    return query.get();
  }

  Future<void> upsertCard(CardsTableCompanion card) {
    return into(cardsTable).insertOnConflictUpdate(card);
  }

  Future<void> upsertCards(Iterable<CardsTableCompanion> cards) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cardsTable, cards.toList());
    });
  }

  Future<void> updateProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
  }) {
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    return (update(
      cardsTable,
    )..where((table) => table.id.equals(cardId))).write(
      CardsTableCompanion(
        easeFactor: Value(easeFactor),
        intervalDays: Value(intervalDays),
        dueDate: Value(dueDate.millisecondsSinceEpoch),
        syncPending: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateInsight({
    required String cardId,
    required String insight,
  }) {
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    return (update(
      cardsTable,
    )..where((table) => table.id.equals(cardId))).write(
      CardsTableCompanion(
        insight: Value(insight),
        syncPending: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> clearSyncPending(String id) {
    return (update(cardsTable)..where((table) => table.id.equals(id))).write(
      const CardsTableCompanion(syncPending: Value(false)),
    );
  }

  Future<void> markCardDeleted(String id, int deletedAt) {
    return (update(cardsTable)..where((table) => table.id.equals(id))).write(
      CardsTableCompanion(
        syncPending: const Value(true),
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }

  Future<void> deleteCardPermanently(String id) {
    return (delete(cardsTable)..where((table) => table.id.equals(id))).go();
  }

  Future<void> deleteCardsForDeckPermanently(String deckId) {
    return (delete(
      cardsTable,
    )..where((table) => table.deckId.equals(deckId))).go();
  }
}
