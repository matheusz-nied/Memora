import 'package:drift/drift.dart';

/// Histórico de revisões, append-only.
///
/// Sem ele não existe streak real, curva de retenção, heatmap nem caminho de
/// migração para FSRS — e o histórico não pode ser reconstruído depois.
///
/// Por ser append-only o sync é só push: nunca há conflito para resolver.
@DataClassName('LocalReview')
class ReviewsTable extends Table {
  @override
  String get tableName => 'reviews';

  TextColumn get id => text()();
  TextColumn get cardId => text()();

  /// Redundante com `cards.deckId`, mas evita um join no caminho de sync e
  /// mantém a revisão utilizável depois que o card é apagado.
  TextColumn get deckId => text()();

  /// Índice de [CardRating]: 0 = again, 1 = hard, 2 = good, 3 = easy.
  IntColumn get rating => integer()();

  RealColumn get easeBefore => real()();
  RealColumn get easeAfter => real()();
  IntColumn get intervalBefore => integer()();
  IntColumn get intervalAfter => integer()();

  /// Epoch ms.
  IntColumn get reviewedAt => integer()();

  BoolColumn get syncPending => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
