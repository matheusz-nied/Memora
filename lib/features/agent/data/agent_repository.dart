import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backend/backend_provider.dart';
import '../../../core/backend/models/ai_chat_message.dart';
import '../../../core/backend/models/backend_chat_message.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/app_sync_service.dart';
import '../../auth/auth_repository.dart';
import '../../decks/deck_model.dart';

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(
    database: ref.watch(appDatabaseProvider),
    backendClient: ref.watch(backendClientProvider),
    syncService: ref.watch(appSyncServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class AgentRepository {
  AgentRepository({
    required AppDatabase database,
    required dynamic backendClient,
    required AppSyncService syncService,
    required AuthRepository authRepository,
  }) : _database = database,
       _backendClient = backendClient,
       _syncService = syncService,
       _authRepository = authRepository;

  final AppDatabase _database;
  final dynamic _backendClient;
  final AppSyncService _syncService;
  final AuthRepository _authRepository;
  final Uuid _uuid = const Uuid();

  /// Updates the agent configuration on the deck (local + sync).
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
        syncPending: const Value(true),
        createdAt: deck.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      ),
    );
    _runSyncSilently(() => _syncService.syncDecks());
  }

  /// Sends a message to the AI agent via [AiGateway].
  Future<String> sendMessage({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    return _backendClient.ai.chat(
      deckId: deckId,
      messages: messages,
      userMessage: userMessage,
    );
  }

  /// Fetches chat history from the remote backend.
  Future<List<BackendChatMessage>> fetchChatHistory(String deckId) {
    return _backendClient.database.fetchChatMessages(deckId);
  }

  /// Saves a single chat message to the remote backend.
  Future<BackendChatMessage> saveChatMessage({
    required String deckId,
    required BackendChatRole role,
    required String content,
  }) {
    final session = _authRepository.currentSession;
    if (session == null) {
      throw StateError('Sessão expirada. Entre novamente.');
    }

    final message = BackendChatMessage(
      id: _uuid.v4(),
      deckId: deckId,
      userId: session.user.id,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );

    return _backendClient.database.insertChatMessage(message);
  }

  void _runSyncSilently(Future<void> Function() sync) {
    Future<void>.value(sync()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('Agent sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }
}
