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

  /// Revisões acertadas seguidas. Zera em "Não sei".
  ///
  /// Distingue card novo de card maduro: os learning steps só valem para as
  /// duas primeiras repetições, e o limite diário de cards novos filtra por
  /// `repetitions == 0`.
  IntColumn get repetitions => integer().withDefault(const Constant(0))();

  /// FSRS state: 1 = learning, 2 = review, 3 = relearning.
  ///
  /// The legacy SM-2 columns above remain in the schema so older backups and
  /// installations can still be opened, but scheduling decisions use this
  /// state plus stability/difficulty.
  IntColumn get fsrsState => integer().withDefault(const Constant(1))();
  IntColumn get fsrsStep => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  IntColumn get lastReview => integer().nullable()();

  IntColumn get dueDate => integer()();
  TextColumn get insight => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
