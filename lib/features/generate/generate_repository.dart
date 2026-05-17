import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_provider.dart';
import '../../core/backend/contracts/ai_gateway.dart';
import '../../core/backend/contracts/auth_gateway.dart';
import '../../core/backend/contracts/storage_gateway.dart';
import '../../core/backend/models/backend_exception.dart';
import '../../core/backend/models/generated_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/connectivity_service.dart';
import 'generate_text.dart';

final generateRepositoryProvider = Provider<GenerateRepository>((ref) {
  final backend = ref.watch(backendClientProvider);
  return GenerateRepository(
    aiGateway: backend.ai,
    authGateway: backend.auth,
    storageGateway: backend.storage,
    isOnline: ref.watch(connectivityServiceProvider).isOnline,
  );
});

class GenerateRepository {
  const GenerateRepository({
    required AiGateway aiGateway,
    required AuthGateway authGateway,
    required StorageGateway storageGateway,
    required Future<bool> Function() isOnline,
  }) : _aiGateway = aiGateway,
       _authGateway = authGateway,
       _storageGateway = storageGateway,
       _isOnline = isOnline;

  final AiGateway _aiGateway;
  final AuthGateway _authGateway;
  final StorageGateway _storageGateway;
  final Future<bool> Function() _isOnline;

  Future<List<GeneratedCard>> generateFromText({
    required String deckId,
    required String text,
    required int quantity,
  }) async {
    await _ensureOnline();
    _validateQuantity(quantity);
    final trimmed = text.trim();
    _validateText(trimmed);

    return _aiGateway.generateCards(
      text: trimmed,
      quantity: quantity,
      deckId: deckId,
    );
  }

  Future<List<GeneratedCard>> generateFromPdf({
    required String deckId,
    required String fileName,
    required Uint8List bytes,
    required int quantity,
  }) async {
    await _ensureOnline();
    _validateQuantity(quantity);
    _validatePdf(fileName: fileName, bytes: bytes);

    final session = _authGateway.currentSession;
    if (session == null) {
      throw const BackendException(GenerateText.noSession);
    }

    final upload = await _storageGateway.uploadPdf(
      userId: session.user.id,
      fileName: fileName,
      bytes: bytes,
    );

    return _aiGateway.generateCardsFromPdf(
      pdfPath: upload.path,
      quantity: quantity,
      deckId: deckId,
    );
  }

  Future<void> _ensureOnline() async {
    if (!await _isOnline()) {
      throw const BackendException(GenerateText.offline);
    }
  }

  void _validateQuantity(int quantity) {
    if (!AppConstants.kCardQuantityOptions.contains(quantity)) {
      throw const BackendException(GenerateText.invalidQuantity);
    }
  }

  void _validateText(String text) {
    if (text.isEmpty) {
      throw const BackendException(GenerateText.textRequired);
    }
    if (text.length < 100) {
      throw const BackendException(GenerateText.textTooShort);
    }
    if (text.length > AppConstants.kMaxTextInput) {
      throw const BackendException(GenerateText.textTooLong);
    }
  }

  void _validatePdf({required String fileName, required Uint8List bytes}) {
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      throw const BackendException(GenerateText.invalidPdf);
    }
    if (bytes.isEmpty) {
      throw const BackendException(GenerateText.invalidPdf);
    }
    final maxBytes = AppConstants.kMaxPdfSizeMb * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw const BackendException(GenerateText.pdfTooLarge);
    }
  }
}
