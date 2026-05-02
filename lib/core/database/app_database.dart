import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daos/cards_dao.dart';
import 'daos/decks_dao.dart';
import 'tables/cards_table.dart';
import 'tables/decks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [DecksTable, CardsTable], daos: [DecksDao, CardsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'memora'));

  @override
  int get schemaVersion => 1;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final decksDaoProvider = Provider<DecksDao>((ref) {
  return ref.watch(appDatabaseProvider).decksDao;
});

final cardsDaoProvider = Provider<CardsDao>((ref) {
  return ref.watch(appDatabaseProvider).cardsDao;
});
