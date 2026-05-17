import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/decks_table.dart';

part 'decks_dao.g.dart';

@DriftAccessor(tables: [DecksTable])
class DecksDao extends DatabaseAccessor<AppDatabase> with _$DecksDaoMixin {
  DecksDao(super.db);

  Stream<List<LocalDeck>> watchAllDecks({String? userId}) {
    final query = select(decksTable)
      ..where((table) => table.deletedAt.isNull());
    if (userId != null) {
      query.where((table) => table.userId.equals(userId));
    }
    return (query..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .watch();
  }

  Stream<List<LocalDeck>> watchDecksPage({
    required String userId,
    required int limit,
  }) {
    return (select(decksTable)
          ..where(
            (table) => table.userId.equals(userId) & table.deletedAt.isNull(),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> countDecks({required String userId}) async {
    final count = decksTable.id.count();
    final query = selectOnly(decksTable)
      ..addColumns([count])
      ..where(decksTable.userId.equals(userId) & decksTable.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<LocalDeck?> watchDeckById(String id, {String? userId}) {
    final query = select(decksTable)
      ..where((table) => table.id.equals(id) & table.deletedAt.isNull());
    if (userId != null) {
      query.where((table) => table.userId.equals(userId));
    }
    return query.watchSingleOrNull();
  }

  Future<List<LocalDeck>> getAllDecks({String? userId}) {
    final query = select(decksTable)
      ..where((table) => table.deletedAt.isNull());
    if (userId != null) {
      query.where((table) => table.userId.equals(userId));
    }
    return (query..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .get();
  }

  Future<LocalDeck?> getDeckById(String id) {
    return (select(decksTable)
          ..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<LocalDeck>> getPendingSyncDecks({String? userId}) {
    final query = select(decksTable)
      ..where((table) => table.syncPending.equals(true));
    if (userId != null) {
      query.where((table) => table.userId.equals(userId));
    }
    return (query..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]))
        .get();
  }

  Future<List<LocalDeck>> getSyncedDecks({String? userId}) {
    final query = select(decksTable)
      ..where(
        (table) => table.deletedAt.isNull() & table.syncPending.equals(false),
      );
    if (userId != null) {
      query.where((table) => table.userId.equals(userId));
    }
    return query.get();
  }

  Future<List<String>> getDeckIdsForUser(String userId) async {
    final rows = await (select(
      decksTable,
    )..where((table) => table.userId.equals(userId))).get();
    return rows.map((deck) => deck.id).toList();
  }

  Future<void> upsertDeck(DecksTableCompanion deck) {
    return into(decksTable).insertOnConflictUpdate(deck);
  }

  Future<void> upsertDecks(Iterable<DecksTableCompanion> decks) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(decksTable, decks.toList());
    });
  }

  Future<void> clearSyncPending(String id) {
    return (update(decksTable)..where((table) => table.id.equals(id))).write(
      const DecksTableCompanion(syncPending: Value(false)),
    );
  }

  Future<void> markDeckDeleted(String id, int deletedAt) {
    return (update(decksTable)..where((table) => table.id.equals(id))).write(
      DecksTableCompanion(
        syncPending: const Value(true),
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }

  Future<void> deleteDeckPermanently(String id) {
    return (delete(decksTable)..where((table) => table.id.equals(id))).go();
  }
}
