import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/identity/device_user_id.dart';
import 'backup_data.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    database: ref.watch(appDatabaseProvider),
    userId: ref.watch(deviceUserIdProvider),
  );
});

/// Resultado de uma importação, para a tela dizer o que entrou.
class BackupSummary {
  const BackupSummary({
    required this.decks,
    required this.cards,
    required this.reviews,
  });

  final int decks;
  final int cards;
  final int reviews;

  bool get isEmpty => decks == 0 && cards == 0 && reviews == 0;
}

/// Exporta e importa todo o conteúdo do usuário em JSON.
///
/// Existe porque no modo local não há nuvem: perder o aparelho apagaria meses
/// de histórico de estudo, que é justamente o dado que não dá para
/// reconstruir. Serve também à portabilidade exigida pela LGPD.
class BackupRepository {
  const BackupRepository({
    required AppDatabase database,
    required String userId,
  }) : _database = database,
       _userId = userId;

  final AppDatabase _database;
  final String _userId;

  Future<String> buildExport({DateTime? exportedAt}) async {
    final decks = await _database.decksDao.getAllDecks(userId: _userId);
    final deckIds = decks.map((deck) => deck.id).toList();

    final cards = <LocalCard>[];
    for (final deckId in deckIds) {
      cards.addAll(await _database.cardsDao.getCardsForDeck(deckId));
    }

    return encodeBackup(
      decks: decks,
      cards: cards,
      reviews: await _database.reviewsDao.getReviewsForDecks(deckIds),
      exportedAt: exportedAt ?? DateTime.now(),
    );
  }

  /// Aplica um backup sobre o que já existe.
  ///
  /// Regras, nesta ordem de importância:
  /// 1. **Nunca apaga.** Importar é somar; quem quiser recomeçar desinstala.
  /// 2. Em conflito de `id`, vence o `updatedAt` mais recente — reimportar um
  ///    backup velho não pode desfazer o estudo feito depois dele. A comparação
  ///    enxerga também o que foi apagado: apagar é uma edição como outra
  ///    qualquer, e ignorar a tombstone ressuscitaria o que o usuário tirou.
  /// 3. Os decks são re-atribuídos ao usuário atual: o `userId` do arquivo é
  ///    de outra instalação, e mantê-lo deixaria os decks invisíveis.
  Future<BackupSummary> applyImport(String source) async {
    final backup = decodeBackup(source);

    var importedDecks = 0;
    for (final deck in backup.decks) {
      final existing = await _database.decksDao.getDeckByIdIncludingDeleted(
        deck.id,
      );
      if (existing != null && existing.updatedAt >= deck.updatedAt) {
        continue;
      }

      await _database.decksDao.upsertDeck(
        DecksTableCompanion.insert(
          id: deck.id,
          userId: _userId,
          title: deck.title,
          description: Value(deck.description),
          agentName: Value(deck.agentName),
          agentPrompt: Value(deck.agentPrompt),
          agentTemplate: Value(deck.agentTemplate),
          agentLanguage: Value(deck.agentLanguage),
          agentLevel: Value(deck.agentLevel),
          deletedAt: Value(deck.deletedAt),
          createdAt: deck.createdAt,
          updatedAt: deck.updatedAt,
        ),
      );
      importedDecks += 1;
    }

    var importedCards = 0;
    for (final card in backup.cards) {
      final existing = await _database.cardsDao.getCardByIdIncludingDeleted(
        card.id,
      );
      if (existing != null && existing.updatedAt >= card.updatedAt) {
        continue;
      }

      await _database.cardsDao.upsertCard(
        CardsTableCompanion.insert(
          id: card.id,
          deckId: card.deckId,
          front: card.front,
          back: card.back,
          easeFactor: Value(card.easeFactor),
          intervalDays: Value(card.intervalDays),
          repetitions: Value(card.repetitions),
          dueDate: card.dueDate,
          insight: Value(card.insight),
          deletedAt: Value(card.deletedAt),
          createdAt: card.createdAt,
          updatedAt: card.updatedAt,
        ),
      );
      importedCards += 1;
    }

    // `reviews` é append-only: reescrever uma revisão existente falsificaria o
    // histórico, então só entra o que ainda não existe.
    final existingReviewIds = await _database.reviewsDao.getExistingReviewIds(
      backup.reviews.map((review) => review.id),
    );

    var importedReviews = 0;
    for (final review in backup.reviews) {
      if (existingReviewIds.contains(review.id)) {
        continue;
      }

      await _database.reviewsDao.insertReview(
        ReviewsTableCompanion.insert(
          id: review.id,
          cardId: review.cardId,
          deckId: review.deckId,
          rating: review.rating,
          easeBefore: review.easeBefore,
          easeAfter: review.easeAfter,
          intervalBefore: review.intervalBefore,
          intervalAfter: review.intervalAfter,
          reviewedAt: review.reviewedAt,
        ),
      );
      importedReviews += 1;
    }

    return BackupSummary(
      decks: importedDecks,
      cards: importedCards,
      reviews: importedReviews,
    );
  }
}
