import 'package:drift/drift.dart';

@DataClassName('LocalDeck')
class DecksTable extends Table {
  @override
  String get tableName => 'decks';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get agentName => text().withDefault(const Constant('Tutor'))();
  TextColumn get agentPrompt => text().nullable()();
  TextColumn get agentTemplate =>
      text().withDefault(const Constant('general'))();
  TextColumn get agentLanguage =>
      text().withDefault(const Constant('português'))();
  TextColumn get agentLevel =>
      text().withDefault(const Constant('intermediário'))();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
