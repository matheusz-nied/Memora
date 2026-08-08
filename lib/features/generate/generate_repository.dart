import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/contracts/ai_gateway.dart';
import '../../core/backend/contracts/pdf_text_gateway.dart';
import '../../core/backend/gateway_providers.dart';
import '../../core/backend/models/backend_exception.dart';
import '../../core/backend/models/generated_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/connectivity_service.dart';
import 'batch_planner.dart';
import 'generate_text.dart';
import 'generation_progress.dart';

final generateRepositoryProvider = Provider<GenerateRepository>((ref) {
  return GenerateRepository(
    aiGateway: ref.watch(aiGatewayProvider),
    pdfTextGateway: ref.watch(pdfTextGatewayProvider),
    isOnline: ref.watch(connectivityServiceProvider).isOnline,
  );
});

typedef GenerateProgressCallback = void Function(GenerateProgress progress);

class GenerateRepository {
  const GenerateRepository({
    required AiGateway aiGateway,
    required PdfTextGateway pdfTextGateway,
    required Future<bool> Function() isOnline,
    Future<void> Function(Duration) wait = _defaultWait,
  }) : _aiGateway = aiGateway,
       _pdfTextGateway = pdfTextGateway,
       _isOnline = isOnline,
       _wait = wait;

  final AiGateway _aiGateway;
  final PdfTextGateway _pdfTextGateway;
  final Future<bool> Function() _isOnline;
  final Future<void> Function(Duration) _wait;

  /// Espera antes de repetir um lote barrado por excesso de requisições. O
  /// limite da DeepSeek é por minuto, então a janela seguinte abre logo.
  static const Duration _rateLimitBackoff = Duration(seconds: 11);

  Future<GenerationResult> generateFromText({
    required String deckId,
    required String text,
    required int quantity,
    GenerateProgressCallback? onProgress,
  }) async {
    await _ensureOnline();
    _validateQuantity(quantity);
    final trimmed = text.trim();
    _validateText(trimmed);

    final batches = computeBatchSizes(quantity);

    return _runBatches(
      deckId: deckId,
      chunks: chunkText(trimmed),
      batches: batches,
      quantity: quantity,
      fromPdf: false,
      onProgress: onProgress,
    );
  }

  Future<GenerationResult> generateFromPdf({
    required String deckId,
    required String fileName,
    required Uint8List bytes,
    required int quantity,
    GenerateProgressCallback? onProgress,
  }) async {
    await _ensureOnline();
    _validateQuantity(quantity);
    _validatePdf(fileName: fileName, bytes: bytes);

    final batches = computeBatchSizes(quantity);

    onProgress?.call(
      GenerateProgress(
        phase: GeneratePhase.extracting,
        batchesDone: 0,
        batchesTotal: batches.length,
        cardsDone: 0,
        cardsRequested: quantity,
      ),
    );

    // A extração acontece uma vez só: o texto alimenta todos os lotes, então
    // um PDF de 100 páginas é lido uma vez, não uma vez por lote.
    final extraction = await _pdfTextGateway.extractText(
      fileName: fileName,
      bytes: bytes,
    );

    return _runBatches(
      deckId: deckId,
      chunks: chunkText(extraction.text),
      batches: batches,
      quantity: quantity,
      fromPdf: true,
      onProgress: onProgress,
    );
  }

  Future<GenerationResult> _runBatches({
    required String deckId,
    required List<String> chunks,
    required List<int> batches,
    required int quantity,
    required bool fromPdf,
    GenerateProgressCallback? onProgress,
  }) async {
    if (chunks.isEmpty) {
      throw const BackendException(GenerateText.textRequired);
    }

    final cards = <GeneratedCard>[];
    final seenFronts = <String>{};

    for (var index = 0; index < batches.length; index++) {
      onProgress?.call(
        GenerateProgress(
          phase: GeneratePhase.generating,
          batchesDone: index,
          batchesTotal: batches.length,
          cardsDone: cards.length,
          cardsRequested: quantity,
        ),
      );

      final chunk =
          chunks[chunkIndexForBatch(
            batchIndex: index,
            batchCount: batches.length,
            chunkCount: chunks.length,
          )];

      try {
        final batch = await _generateBatch(
          deckId: deckId,
          text: chunk,
          quantity: batches[index],
          avoidFronts: _avoidFronts(cards),
          fromPdf: fromPdf,
        );

        for (final card in batch) {
          if (seenFronts.add(_normalizeFront(card.front))) {
            cards.add(card);
          }
        }
      } on BackendException catch (error) {
        // Os lotes anteriores já foram pagos e são cards válidos: quem chamou
        // decide se aproveita ou descarta.
        return GenerationResult(cards: cards, error: error);
      }
    }

    onProgress?.call(
      GenerateProgress(
        phase: GeneratePhase.generating,
        batchesDone: batches.length,
        batchesTotal: batches.length,
        cardsDone: cards.length,
        cardsRequested: quantity,
      ),
    );

    return GenerationResult(cards: cards);
  }

  /// Uma retentativa por lote, só para falhas de espera.
  ///
  /// Rate limit e timeout são o motivo mais comum de uma geração longa morrer
  /// no meio, e ambos passam sozinhos. Erro de quota, deck ou material não
  /// melhora repetindo.
  Future<List<GeneratedCard>> _generateBatch({
    required String deckId,
    required String text,
    required int quantity,
    required List<String> avoidFronts,
    required bool fromPdf,
  }) async {
    try {
      return await _aiGateway.generateCards(
        text: text,
        quantity: quantity,
        deckId: deckId,
        avoidFronts: avoidFronts,
        fromPdf: fromPdf,
      );
    } on BackendException catch (error) {
      if (error.isRateLimited) {
        await _wait(_rateLimitBackoff);
      } else if (!error.isTimeout) {
        rethrow;
      }

      return _aiGateway.generateCards(
        text: text,
        quantity: quantity,
        deckId: deckId,
        avoidFronts: avoidFronts,
        fromPdf: fromPdf,
      );
    }
  }

  List<String> _avoidFronts(List<GeneratedCard> cards) {
    final fronts = cards.map((card) => card.front).toList();
    if (fronts.length <= AppConstants.kMaxAvoidFronts) {
      return fronts;
    }
    return fronts.sublist(fronts.length - AppConstants.kMaxAvoidFronts);
  }

  String _normalizeFront(String front) =>
      front.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
    if (text.length < AppConstants.kMinTextInput) {
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

Future<void> _defaultWait(Duration duration) => Future<void>.delayed(duration);
