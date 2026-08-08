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

  /// Inclui o que foi apagado.
  ///
  /// Serve a quem precisa saber que a linha existe, e não apenas que ela está
  /// visível: sem a tombstone, um `id` apagado parece inédito e volta à vida na
  /// primeira escrita por `id`.
  Future<LocalDeck?> getDeckByIdIncludingDeleted(String id) {
    return (select(
      decksTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertDeck(DecksTableCompanion deck) {
    return into(decksTable).insertOnConflictUpdate(deck);
  }

  Future<void> markDeckDeleted(String id, int deletedAt) {
    return (update(decksTable)..where((table) => table.id.equals(id))).write(
      DecksTableCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }
}
