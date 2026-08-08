import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/reviews_table.dart';

part 'reviews_dao.g.dart';

@DriftAccessor(tables: [ReviewsTable])
class ReviewsDao extends DatabaseAccessor<AppDatabase> with _$ReviewsDaoMixin {
  ReviewsDao(super.db);

  Future<void> insertReview(ReviewsTableCompanion review) {
    return into(reviewsTable).insertOnConflictUpdate(review);
  }

  Future<List<LocalReview>> getPendingSyncReviews({int limit = 200}) {
    return (select(reviewsTable)
          ..where((table) => table.syncPending.equals(true))
          ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> markSynced(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) {
      return;
    }
    await (update(reviewsTable)..where((table) => table.id.isIn(idList))).write(
      const ReviewsTableCompanion(syncPending: Value(false)),
    );
  }

  /// Revisões a partir de um instante, para streak e estatísticas.
  Future<List<LocalReview>> getReviewsSince(int fromEpochMs) {
    return (select(reviewsTable)
          ..where((table) => table.reviewedAt.isBiggerOrEqualValue(fromEpochMs))
          ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)]))
        .get();
  }

  /// Revisões a partir de um instante, opcionalmente restritas a alguns decks.
  ///
  /// O filtro por deck existe porque o banco local pode conter dados de mais
  /// de um usuário — quem trocou de conta no mesmo aparelho. Sem ele, o
  /// dashboard somaria o histórico de outra pessoa.
  Stream<List<LocalReview>> watchReviewsSince(
    int fromEpochMs, {
    List<String>? deckIds,
  }) {
    final query = select(reviewsTable)
      ..where((table) => table.reviewedAt.isBiggerOrEqualValue(fromEpochMs))
      ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)]);

    if (deckIds != null) {
      query.where((table) => table.deckId.isIn(deckIds));
    }

    return query.watch();
  }

  /// Todo o histórico dos decks informados, para exportação.
  Future<List<LocalReview>> getReviewsForDecks(List<String> deckIds) {
    if (deckIds.isEmpty) {
      return Future.value(const []);
    }

    return (select(reviewsTable)
          ..where((table) => table.deckId.isIn(deckIds))
          ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)]))
        .get();
  }

  /// Ids já existentes, para o import não duplicar revisão nem sobrescrever
  /// uma linha de uma tabela que é append-only.
  Future<Set<String>> getExistingReviewIds(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) {
      return <String>{};
    }

    final rows =
        await (selectOnly(reviewsTable)
              ..addColumns([reviewsTable.id])
              ..where(reviewsTable.id.isIn(idList)))
            .get();

    return rows
        .map((row) => row.read(reviewsTable.id))
        .whereType<String>()
        .toSet();
  }

  Future<int> countReviewsForDeck(String deckId) async {
    final count = reviewsTable.id.count();
    final query = selectOnly(reviewsTable)
      ..addColumns([count])
      ..where(reviewsTable.deckId.equals(deckId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> deleteReviewsForDeck(String deckId) {
    return (delete(
      reviewsTable,
    )..where((table) => table.deckId.equals(deckId))).go();
  }
}
