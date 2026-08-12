import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cards_table.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [CardsTable])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Stream<List<LocalCard>> watchCardsForDeck(String deckId) {
    return (select(cardsTable)
          ..where(
            (table) => table.deckId.equals(deckId) & table.deletedAt.isNull(),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .watch();
  }

  Stream<List<LocalCard>> watchCardsPage({
    required String deckId,
    required int limit,
  }) {
    return (select(cardsTable)
          ..where(
            (table) => table.deckId.equals(deckId) & table.deletedAt.isNull(),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> countCardsForDeck(String deckId) async {
    final count = cardsTable.id.count();
    final query = selectOnly(cardsTable)
      ..addColumns([count])
      ..where(cardsTable.deckId.equals(deckId) & cardsTable.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<LocalCard>> getCardsForDeck(String deckId) {
    return (select(cardsTable)
          ..where(
            (table) => table.deckId.equals(deckId) & table.deletedAt.isNull(),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
  }

  Future<LocalCard?> getCardById(String id) {
    return (select(cardsTable)
          ..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Inclui o que foi apagado — ver `DecksDao.getDeckByIdIncludingDeleted`.
  Future<LocalCard?> getCardByIdIncludingDeleted(String id) {
    return (select(
      cardsTable,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Stream<LocalCard?> watchCardById(String id) {
    return (select(cardsTable)
          ..where((table) => table.id.equals(id) & table.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<void> upsertCard(CardsTableCompanion card) {
    return into(cardsTable).insertOnConflictUpdate(card);
  }

  Future<void> updateProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime dueDate,
    int? fsrsState,
    int? fsrsStep,
    double? stability,
    double? difficulty,
    DateTime? lastReview,
    bool persistFsrsState = false,
  }) {
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    return (update(
      cardsTable,
    )..where((table) => table.id.equals(cardId))).write(
      CardsTableCompanion(
        easeFactor: Value(easeFactor),
        intervalDays: Value(intervalDays),
        repetitions: Value(repetitions),
        fsrsState: persistFsrsState
            ? Value(fsrsState ?? 1)
            : const Value.absent(),
        fsrsStep: persistFsrsState ? Value(fsrsStep) : const Value.absent(),
        stability: persistFsrsState ? Value(stability) : const Value.absent(),
        difficulty: persistFsrsState ? Value(difficulty) : const Value.absent(),
        lastReview: persistFsrsState
            ? Value(lastReview?.millisecondsSinceEpoch)
            : const Value.absent(),
        dueDate: Value(dueDate.millisecondsSinceEpoch),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Cards vencidos, filtrados no banco e não em memória.
  ///
  /// `dueBefore` é o fim do dia corrente: um card com vencimento hoje deve
  /// aparecer na sessão de hoje.
  Stream<List<LocalCard>> watchDueCards({
    required String deckId,
    required int dueBefore,
    required int newCardLimit,
  }) {
    return (select(cardsTable)
          ..where(
            (table) =>
                table.deckId.equals(deckId) &
                table.deletedAt.isNull() &
                table.dueDate.isSmallerOrEqualValue(dueBefore),
          )
          ..orderBy([
            (table) => OrderingTerm.asc(table.dueDate),
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .watch()
        .map((cards) => _capNewCards(cards, newCardLimit));
  }

  /// Limita quantos cards nunca revisados entram na sessão.
  ///
  /// Sem isto, gerar 100 cards de uma vez cria 100 vencidos no mesmo dia —
  /// `createCard` nasce com `dueDate = now`, então card novo e card atrasado
  /// são indistinguíveis pelo vencimento. FSRS state is authoritative; the
  /// repetition check is only a compatibility fallback for old backups.
  List<LocalCard> _capNewCards(List<LocalCard> cards, int newCardLimit) {
    if (newCardLimit < 0) {
      return cards;
    }

    final result = <LocalCard>[];
    var newCards = 0;
    for (final card in cards) {
      if (card.repetitions == 0 &&
          card.fsrsState == 1 &&
          card.stability == null &&
          card.lastReview == null) {
        if (newCards >= newCardLimit) {
          continue;
        }
        newCards += 1;
      }
      result.add(card);
    }
    return result;
  }

  /// Vencimentos dos cards dos decks informados até [untilEpochMs].
  ///
  /// Devolve só a coluna de vencimento: a carga dos próximos dias é uma
  /// contagem por dia, e trazer os cards inteiros seria carregar o deck todo
  /// na memória para depois descartar.
  Future<List<int>> getUpcomingDueDates({
    required List<String> deckIds,
    required int untilEpochMs,
  }) async {
    if (deckIds.isEmpty) {
      return const [];
    }

    final query = selectOnly(cardsTable)
      ..addColumns([cardsTable.dueDate])
      ..where(
        cardsTable.deckId.isIn(deckIds) &
            cardsTable.deletedAt.isNull() &
            cardsTable.dueDate.isSmallerOrEqualValue(untilEpochMs),
      );

    final rows = await query.get();
    return rows
        .map((row) => row.read(cardsTable.dueDate))
        .whereType<int>()
        .toList();
  }

  Future<int> countDueCards({
    required String deckId,
    required int dueBefore,
  }) async {
    final count = cardsTable.id.count();
    final query = selectOnly(cardsTable)
      ..addColumns([count])
      ..where(
        cardsTable.deckId.equals(deckId) &
            cardsTable.deletedAt.isNull() &
            cardsTable.dueDate.isSmallerOrEqualValue(dueBefore),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> updateInsight({
    required String cardId,
    required String insight,
  }) {
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    return (update(
      cardsTable,
    )..where((table) => table.id.equals(cardId))).write(
      CardsTableCompanion(insight: Value(insight), updatedAt: Value(updatedAt)),
    );
  }

  Future<void> markCardDeleted(String id, int deletedAt) {
    return (update(cardsTable)..where((table) => table.id.equals(id))).write(
      CardsTableCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }

  Future<void> markCardsForDeckDeleted(String deckId, int deletedAt) {
    return (update(
      cardsTable,
    )..where((table) => table.deckId.equals(deckId))).write(
      CardsTableCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }
}
