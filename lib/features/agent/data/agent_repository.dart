import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backend/contracts/ai_gateway.dart';
import '../../../core/backend/gateway_providers.dart';
import '../../../core/backend/models/ai_chat_message.dart';
import '../../../core/database/app_database.dart';
import '../../decks/deck_model.dart';
import 'chat_message.dart';

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(
    database: ref.watch(appDatabaseProvider),
    aiGateway: ref.watch(aiGatewayProvider),
  );
});

class AgentRepository {
  AgentRepository({required AppDatabase database, required AiGateway aiGateway})
    : _database = database,
      _aiGateway = aiGateway;

  final AppDatabase _database;
  final AiGateway _aiGateway;
  final Uuid _uuid = const Uuid();

  /// Grava a configuração do agente no deck.
  Future<void> updateAgentConfig({
    required DeckModel deck,
    required String agentName,
    required String agentTemplate,
    String? agentPrompt,
    required String agentLanguage,
    required String agentLevel,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: deck.id,
        userId: deck.userId,
        title: deck.title,
        description: Value(deck.description),
        agentName: Value(agentName.trim()),
        agentPrompt: Value(agentPrompt?.trim()),
        agentTemplate: Value(agentTemplate),
        agentLanguage: Value(agentLanguage),
        agentLevel: Value(agentLevel),
        createdAt: deck.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      ),
    );
  }

  /// Manda a mensagem para o tutor e devolve a resposta.
  Future<String> sendMessage({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    return _aiGateway.chat(
      deckId: deckId,
      messages: messages,
      userMessage: userMessage,
    );
  }

  /// Histórico do deck, do mais antigo para o mais novo.
  Future<List<ChatMessage>> fetchChatHistory(String deckId) async {
    final messages = await _database.chatMessagesDao.getMessagesForDeck(deckId);
    return messages.map(ChatMessage.fromLocal).toList();
  }

  Future<ChatMessage> saveChatMessage({
    required String deckId,
    required ChatRole role,
    required String content,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );

    await _database.chatMessagesDao.insertMessage(
      ChatMessagesTableCompanion.insert(
        id: message.id,
        deckId: deckId,
        role: role.name,
        content: content,
        createdAt: message.createdAt.millisecondsSinceEpoch,
      ),
    );

    return message;
  }
}
