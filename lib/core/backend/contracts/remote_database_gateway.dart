import '../models/backend_card.dart';
import '../models/backend_chat_message.dart';
import '../models/backend_deck.dart';
import '../models/backend_review.dart';

abstract interface class RemoteDatabaseGateway {
  /// Envia revisões. Append-only, então é idempotente por `id`: reenviar uma
  /// revisão já sincronizada não duplica nem sobrescreve nada relevante.
  Future<void> insertReviews(List<BackendReview> reviews);

  Future<List<BackendDeck>> fetchDecks();

  Future<BackendDeck> upsertDeck(BackendDeck deck);

  Future<void> deleteDeck(String deckId);

  Future<List<BackendCard>> fetchCards(String deckId);

  Future<BackendCard> upsertCard(BackendCard card);

  Future<void> deleteCard(String cardId);

  Future<BackendCard> updateCardProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
    required DateTime updatedAt,
  });

  Future<BackendCard> updateCardInsight({
    required String cardId,
    required String insight,
    required DateTime updatedAt,
  });

  Future<List<BackendChatMessage>> fetchChatMessages(String deckId);

  Future<BackendChatMessage> insertChatMessage(BackendChatMessage message);
}
