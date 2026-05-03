import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/decks_table.dart';

part 'decks_dao.g.dart';

@DriftAccessor(tables: [DecksTable])
class DecksDao extends DatabaseAccessor<AppDatabase> with _$DecksDaoMixin {
  DecksDao(super.db);

  Stream<List<LocalDeck>> watchAllDecks() {
    return (select(decksTable)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .watch();
  }

  Future<List<LocalDeck>> getAllDecks() {
    return (select(decksTable)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .get();
  }

  Future<LocalDeck?> getDeckById(String id) {
    return (select(decksTable)
          ..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<LocalDeck>> getPendingSyncDecks() {
    return (select(decksTable)
          ..where((table) => table.syncPending.equals(true))
          ..orderBy([(table) => OrderingTerm.asc(table.updatedAt)]))
        .get();
  }

  Future<List<LocalDeck>> getSyncedDecks() {
    return (select(decksTable)..where(
          (table) => table.deletedAt.isNull() & table.syncPending.equals(false),
        ))
        .get();
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
