import 'package:drift/drift.dart';

@DataClassName('LocalCard')
class CardsTable extends Table {
  @override
  String get tableName => 'cards';

  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(1))();
  IntColumn get dueDate => integer()();
  BoolColumn get syncPending => boolean().withDefault(const Constant(false))();
  TextColumn get insight => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
