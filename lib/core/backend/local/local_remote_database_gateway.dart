import '../../database/app_database.dart';
import '../contracts/remote_database_gateway.dart';
import '../models/backend_card.dart';
import '../models/backend_chat_message.dart';
import '../models/backend_deck.dart';
import '../models/backend_exception.dart';
import '../models/backend_review.dart';

/// O "remoto" que não existe.
///
/// Decks, cards e revisões nunca chegam aqui: o sync fica desligado neste modo
/// e o Drift é a única fonte da verdade, acessado pelos DAOs.
///
/// O chat é a exceção, porque `AgentRepository` guarda o histórico pelo gateway
/// de banco em vez de por um DAO. Em vez de mudar a feature, este adaptador
/// atende as duas operações contra a tabela `chat_messages` local — a conversa
/// passa a sobreviver a fechar a tela, sem uma linha de mudança na feature nem
/// no modo nuvem, que segue no Postgres.
class LocalRemoteDatabaseGateway implements RemoteDatabaseGateway {
  const LocalRemoteDatabaseGateway(this._database);

  final AppDatabase _database;

  @override
  Future<List<BackendChatMessage>> fetchChatMessages(String deckId) async {
    final messages = await _database.chatMessagesDao.getMessagesForDeck(deckId);

    return messages
        .map(
          (message) => BackendChatMessage(
            id: message.id,
            deckId: message.deckId,
            // Sem conta, a mensagem não pertence a um usuário remoto; o dono
            // é o aparelho.
            userId: '',
            role: _roleFromName(message.role),
            content: message.content,
            createdAt: DateTime.fromMillisecondsSinceEpoch(message.createdAt),
          ),
        )
        .toList();
  }

  @override
  Future<BackendChatMessage> insertChatMessage(
    BackendChatMessage message,
  ) async {
    await _database.chatMessagesDao.insertMessage(
      ChatMessagesTableCompanion.insert(
        id: message.id,
        deckId: message.deckId,
        role: message.role.name,
        content: message.content,
        createdAt: message.createdAt.millisecondsSinceEpoch,
      ),
    );
    return message;
  }

  BackendChatRole _roleFromName(String name) {
    return BackendChatRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => BackendChatRole.assistant,
    );
  }

  @override
  Future<void> insertReviews(List<BackendReview> reviews) => throw _noRemote();

  @override
  Future<List<BackendDeck>> fetchDecks() => throw _noRemote();

  @override
  Future<BackendDeck> upsertDeck(BackendDeck deck) => throw _noRemote();

  @override
  Future<void> deleteDeck(String deckId) => throw _noRemote();

  @override
  Future<List<BackendCard>> fetchCards(String deckId) => throw _noRemote();

  @override
  Future<BackendCard> upsertCard(BackendCard card) => throw _noRemote();

  @override
  Future<void> deleteCard(String cardId) => throw _noRemote();

  @override
  Future<BackendCard> updateCardProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
    required DateTime updatedAt,
  }) => throw _noRemote();

  @override
  Future<BackendCard> updateCardInsight({
    required String cardId,
    required String insight,
    required DateTime updatedAt,
  }) => throw _noRemote();
}

BackendException _noRemote() {
  return const BackendException(
    'Esta versão guarda tudo apenas neste aparelho.',
    code: 'remote_unsupported',
  );
}
