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

  Stream<List<LocalReview>> watchReviewsSince(int fromEpochMs) {
    return (select(reviewsTable)
          ..where((table) => table.reviewedAt.isBiggerOrEqualValue(fromEpochMs))
          ..orderBy([(table) => OrderingTerm.asc(table.reviewedAt)]))
        .watch();
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
