import 'dart:typed_data';

import 'backend_client.dart';
import 'contracts/ai_gateway.dart';
import 'contracts/auth_gateway.dart';
import 'contracts/remote_database_gateway.dart';
import 'contracts/storage_gateway.dart';
import 'models/ai_chat_message.dart';
import 'models/backend_card.dart';
import 'models/backend_chat_message.dart';
import 'models/backend_deck.dart';
import 'models/backend_exception.dart';
import 'models/backend_session.dart';
import 'models/generated_card.dart';
import 'models/storage_upload_result.dart';

class DisabledBackendClient implements BackendClient {
  const DisabledBackendClient();

  @override
  AuthGateway get auth => const DisabledAuthGateway();

  @override
  RemoteDatabaseGateway get database => const DisabledRemoteDatabaseGateway();

  @override
  StorageGateway get storage => const DisabledStorageGateway();

  @override
  AiGateway get ai => const DisabledAiGateway();
}

class DisabledAuthGateway implements AuthGateway {
  const DisabledAuthGateway();

  @override
  Stream<BackendSession?> get authStateChanges => Stream.value(null);

  @override
  BackendSession? get currentSession => null;

  @override
  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw _notConfigured();
  }

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) {
    throw _notConfigured();
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    throw _notConfigured();
  }

  @override
  Future<void> signOut() async {}
}

class DisabledRemoteDatabaseGateway implements RemoteDatabaseGateway {
  const DisabledRemoteDatabaseGateway();

  @override
  Future<void> deleteCard(String cardId) {
    throw _notConfigured();
  }

  @override
  Future<void> deleteDeck(String deckId) {
    throw _notConfigured();
  }

  @override
  Future<List<BackendCard>> fetchCards(String deckId) {
    throw _notConfigured();
  }

  @override
  Future<List<BackendChatMessage>> fetchChatMessages(String deckId) {
    throw _notConfigured();
  }

  @override
  Future<List<BackendDeck>> fetchDecks() {
    throw _notConfigured();
  }

  @override
  Future<BackendChatMessage> insertChatMessage(BackendChatMessage message) {
    throw _notConfigured();
  }

  @override
  Future<BackendCard> updateCardInsight({
    required String cardId,
    required String insight,
    required DateTime updatedAt,
  }) {
    throw _notConfigured();
  }

  @override
  Future<BackendCard> updateCardProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
    required DateTime updatedAt,
  }) {
    throw _notConfigured();
  }

  @override
  Future<BackendCard> upsertCard(BackendCard card) {
    throw _notConfigured();
  }

  @override
  Future<BackendDeck> upsertDeck(BackendDeck deck) {
    throw _notConfigured();
  }
}

class DisabledStorageGateway implements StorageGateway {
  const DisabledStorageGateway();

  @override
  Future<StorageUploadResult> uploadPdf({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) {
    throw _notConfigured();
  }
}

class DisabledAiGateway implements AiGateway {
  const DisabledAiGateway();

  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    throw _notConfigured();
  }

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) {
    throw _notConfigured();
  }

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
  }) {
    throw _notConfigured();
  }

  @override
  Future<List<GeneratedCard>> generateCardsFromPdf({
    required String pdfPath,
    required int quantity,
    required String deckId,
  }) {
    throw _notConfigured();
  }
}

BackendException _notConfigured() {
  return const BackendException(
    'Backend remoto não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env.',
  );
}
