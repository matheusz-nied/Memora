import 'package:drift/drift.dart';

/// Histórico de revisões, append-only.
///
/// Sem ele não existe streak real, curva de retenção, heatmap nem caminho de
/// migração para FSRS — e o histórico não pode ser reconstruído depois. É
/// também o dado mais caro de perder, e por isso o que o backup mais protege.
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

  /// Legacy SM-2 snapshots kept for compatibility with old backups. New FSRS
  /// reviews leave these at the card's legacy values; the scheduler never
  /// reads them.
  RealColumn get easeBefore => real()();
  RealColumn get easeAfter => real()();
  IntColumn get intervalBefore => integer()();
  IntColumn get intervalAfter => integer()();

  /// 0 = scheduled review, 1 = free practice (never changes FSRS state).
  IntColumn get reviewKind =>
      integer().nullable().withDefault(const Constant(0))();

  /// Epoch ms.
  IntColumn get reviewedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
