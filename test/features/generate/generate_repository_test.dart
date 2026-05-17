import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/contracts/ai_gateway.dart';
import 'package:memora/core/backend/contracts/auth_gateway.dart';
import 'package:memora/core/backend/contracts/storage_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/backend/models/backend_session.dart';
import 'package:memora/core/backend/models/backend_user.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/backend/models/storage_upload_result.dart';
import 'package:memora/features/generate/generate_repository.dart';
import 'package:memora/features/generate/generate_text.dart';

void main() {
  final longText = List.filled(120, 'A').join();

  test('generateFromText blocks when offline', () async {
    final repository = _repository(isOnline: false);

    await expectLater(
      repository.generateFromText(
        deckId: 'deck-1',
        text: longText,
        quantity: 5,
      ),
      throwsA(
        isA<BackendException>().having(
          (error) => error.message,
          'message',
          GenerateText.offline,
        ),
      ),
    );
  });

  test('generateFromText validates short text', () async {
    final repository = _repository();

    await expectLater(
      repository.generateFromText(deckId: 'deck-1', text: 'curto', quantity: 5),
      throwsA(
        isA<BackendException>().having(
          (error) => error.message,
          'message',
          GenerateText.textTooShort,
        ),
      ),
    );
  });

  test('generateFromText calls ai gateway with trimmed text', () async {
    final ai = _FakeAiGateway();
    final repository = _repository(ai: ai);

    final cards = await repository.generateFromText(
      deckId: 'deck-1',
      text: ' $longText ',
      quantity: 10,
    );

    expect(cards, hasLength(1));
    expect(ai.lastText, longText);
    expect(ai.lastQuantity, 10);
    expect(ai.lastDeckId, 'deck-1');
  });

  test('generateFromPdf uploads pdf and calls ai gateway with path', () async {
    final ai = _FakeAiGateway();
    final storage = _FakeStorageGateway();
    final repository = _repository(ai: ai, storage: storage);

    await repository.generateFromPdf(
      deckId: 'deck-1',
      fileName: 'notes.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
      quantity: 5,
    );

    expect(storage.lastUserId, 'user-1');
    expect(storage.lastFileName, 'notes.pdf');
    expect(ai.lastPdfPath, 'user-1/notes.pdf');
  });

  test('generateFromPdf rejects non-pdf file', () async {
    final repository = _repository();

    await expectLater(
      repository.generateFromPdf(
        deckId: 'deck-1',
        fileName: 'notes.txt',
        bytes: Uint8List.fromList([1]),
        quantity: 5,
      ),
      throwsA(
        isA<BackendException>().having(
          (error) => error.message,
          'message',
          GenerateText.invalidPdf,
        ),
      ),
    );
  });
}

GenerateRepository _repository({
  _FakeAiGateway? ai,
  _FakeStorageGateway? storage,
  bool isOnline = true,
}) {
  return GenerateRepository(
    aiGateway: ai ?? _FakeAiGateway(),
    authGateway: const _FakeAuthGateway(),
    storageGateway: storage ?? _FakeStorageGateway(),
    isOnline: () async => isOnline,
  );
}

class _FakeAuthGateway implements AuthGateway {
  const _FakeAuthGateway();

  @override
  Stream<BackendSession?> get authStateChanges => Stream.value(currentSession);

  @override
  BackendSession? get currentSession => const BackendSession(
    user: BackendUser(id: 'user-1', email: 'user@example.com'),
    accessToken: 'token',
  );

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  @override
  Future<BackendSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<BackendSession?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) {
    throw UnimplementedError();
  }
}

class _FakeStorageGateway implements StorageGateway {
  String? lastUserId;
  String? lastFileName;

  @override
  Future<StorageUploadResult> uploadPdf({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    lastUserId = userId;
    lastFileName = fileName;
    return StorageUploadResult(path: '$userId/$fileName');
  }
}

class _FakeAiGateway implements AiGateway {
  String? lastText;
  String? lastDeckId;
  String? lastPdfPath;
  int? lastQuantity;

  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
  }) async {
    lastText = text;
    lastDeckId = deckId;
    lastQuantity = quantity;
    return const [GeneratedCard(front: 'Front', back: 'Back')];
  }

  @override
  Future<List<GeneratedCard>> generateCardsFromPdf({
    required String pdfPath,
    required int quantity,
    required String deckId,
  }) async {
    lastPdfPath = pdfPath;
    lastDeckId = deckId;
    lastQuantity = quantity;
    return const [GeneratedCard(front: 'Front', back: 'Back')];
  }
}
