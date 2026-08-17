import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/contracts/ai_gateway.dart';
import 'package:memora/core/backend/contracts/pdf_text_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/backend/models/pdf_extraction_result.dart';
import 'package:memora/features/generate/generate_repository.dart';
import 'package:memora/features/generate/generate_text.dart';
import 'package:memora/features/generate/generation_progress.dart';

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

  test('generateFromText accepts 50 characters', () async {
    final ai = _FakeAiGateway();
    final repository = _repository(ai: ai);

    final result = await repository.generateFromText(
      deckId: 'deck-1',
      text: List.filled(50, 'A').join(),
      quantity: 5,
    );

    expect(result.isComplete, isTrue);
    expect(ai.calls, hasLength(1));
  });

  test('generateFromText rejects 49 characters', () async {
    final repository = _repository();

    await expectLater(
      repository.generateFromText(
        deckId: 'deck-1',
        text: List.filled(49, 'A').join(),
        quantity: 5,
      ),
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

    final result = await repository.generateFromText(
      deckId: 'deck-1',
      text: ' $longText ',
      quantity: 10,
    );

    expect(result.cards, hasLength(10));
    expect(ai.calls.single.text, longText);
    expect(ai.calls.single.quantity, 10);
    expect(ai.calls.single.deckId, 'deck-1');
    expect(ai.calls.single.fromPdf, isFalse);
  });

  test('generateFromText splits 50 cards into balanced batches', () async {
    final ai = _FakeAiGateway();
    final repository = _repository(ai: ai);

    final result = await repository.generateFromText(
      deckId: 'deck-1',
      text: longText,
      quantity: 50,
    );

    expect(ai.calls.map((call) => call.quantity), [13, 13, 12, 12]);
    expect(result.isComplete, isTrue);
    expect(result.cards, hasLength(50));
  });

  test('each batch sends the fronts generated so far', () async {
    final ai = _FakeAiGateway();
    final repository = _repository(ai: ai);

    await repository.generateFromText(
      deckId: 'deck-1',
      text: longText,
      quantity: 25,
    );

    expect(ai.calls.first.avoidFronts, isEmpty);
    expect(ai.calls.last.avoidFronts, hasLength(13));
    expect(ai.calls.last.avoidFronts.first, 'Front 1');
  });

  test('duplicated fronts across batches are dropped', () async {
    final ai = _FakeAiGateway(cardsPerCall: 13, repeatFronts: true);
    final repository = _repository(ai: ai);

    final result = await repository.generateFromText(
      deckId: 'deck-1',
      text: longText,
      quantity: 25,
    );

    expect(ai.calls, hasLength(2));
    expect(result.cards, hasLength(13));
  });

  test('a failing batch keeps the cards already generated', () async {
    final ai = _FakeAiGateway(
      failOnCall: 2,
      failure: const BackendException('IA fora do ar', code: 'deepseek_502'),
    );
    final repository = _repository(ai: ai);

    final result = await repository.generateFromText(
      deckId: 'deck-1',
      text: longText,
      quantity: 50,
    );

    expect(result.isPartial, isTrue);
    expect(result.cards, hasLength(13));
    expect(result.error?.message, 'IA fora do ar');
  });

  test('a batch is retried once after a rate limit', () async {
    final ai = _FakeAiGateway(
      failOnCall: 1,
      failure: const BackendException(
        'Muitas requisições',
        code: BackendException.codeRateLimited,
      ),
    );
    final waits = <Duration>[];
    final repository = _repository(
      ai: ai,
      wait: (duration) async => waits.add(duration),
    );

    final result = await repository.generateFromText(
      deckId: 'deck-1',
      text: longText,
      quantity: 5,
    );

    expect(waits, hasLength(1));
    expect(ai.calls, hasLength(2));
    expect(result.isComplete, isTrue);
  });

  test('reports progress for every batch', () async {
    final ai = _FakeAiGateway();
    final repository = _repository(ai: ai);
    final progress = <GenerateProgress>[];

    await repository.generateFromText(
      deckId: 'deck-1',
      text: longText,
      quantity: 25,
      onProgress: progress.add,
    );

    expect(progress.first.batchesTotal, 2);
    expect(progress.first.cardsRequested, 25);
    expect(progress.last.batchesDone, 2);
    expect(progress.last.cardsDone, 25);
  });

  test('generateFromPdf extrai uma vez e gera em lotes', () async {
    final ai = _FakeAiGateway();
    final pdf = _FakePdfTextGateway(
      text: List.filled(400, 'texto de estudo. ').join(),
    );
    final repository = _repository(ai: ai, pdf: pdf);

    final result = await repository.generateFromPdf(
      deckId: 'deck-1',
      fileName: 'notes.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
      quantity: 25,
    );

    // O PDF é lido uma vez só, por mais lotes que saiam dele.
    expect(pdf.extractedFiles, ['notes.pdf']);
    expect(ai.calls, hasLength(2));
    expect(ai.calls.every((call) => call.fromPdf), isTrue);
    expect(result.isComplete, isTrue);
  });

  test('generateFromPdf sends a different chunk to each batch', () async {
    final ai = _FakeAiGateway();
    final pdf = _FakePdfTextGateway(
      text: List.generate(
        400,
        (index) => 'Fato numero $index sobre o assunto estudado.',
      ).join('\n\n'),
    );
    final repository = _repository(ai: ai, pdf: pdf);

    await repository.generateFromPdf(
      deckId: 'deck-1',
      fileName: 'notes.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
      quantity: 25,
    );

    expect(ai.calls.first.text, isNot(ai.calls.last.text));
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

  test('generateFromPdf rejects a file over the size limit', () async {
    final repository = _repository();

    await expectLater(
      repository.generateFromPdf(
        deckId: 'deck-1',
        fileName: 'book.pdf',
        bytes: Uint8List(21 * 1024 * 1024),
        quantity: 5,
      ),
      throwsA(
        isA<BackendException>().having(
          (error) => error.message,
          'message',
          GenerateText.pdfTooLarge,
        ),
      ),
    );
  });
}

GenerateRepository _repository({
  _FakeAiGateway? ai,
  _FakePdfTextGateway? pdf,
  bool isOnline = true,
  Future<void> Function(Duration)? wait,
}) {
  return GenerateRepository(
    aiGateway: ai ?? _FakeAiGateway(),
    pdfTextGateway: pdf ?? _FakePdfTextGateway(),
    isOnline: () async => isOnline,
    wait: wait ?? (_) async {},
  );
}

class _FakePdfTextGateway implements PdfTextGateway {
  _FakePdfTextGateway({
    this.text = 'Texto extraido do PDF para gerar cards de estudo.',
  });

  final String text;
  final List<String> extractedFiles = [];

  @override
  Future<PdfExtractionResult> extractText({
    required String fileName,
    required Uint8List bytes,
  }) async {
    extractedFiles.add(fileName);
    return PdfExtractionResult(text: text, pages: 3);
  }
}

class _GenerateCall {
  const _GenerateCall({
    required this.text,
    required this.quantity,
    required this.deckId,
    required this.avoidFronts,
    required this.fromPdf,
  });

  final String text;
  final int quantity;
  final String deckId;
  final List<String> avoidFronts;
  final bool fromPdf;
}

class _FakeAiGateway implements AiGateway {
  _FakeAiGateway({
    this.cardsPerCall,
    this.failOnCall,
    this.failure,
    this.repeatFronts = false,
  });

  /// Cards devolvidos por chamada. `null` devolve a quantidade pedida, como
  /// faz a IA quando tudo dá certo.
  final int? cardsPerCall;

  /// Índice (1-based) da chamada que falha; as demais respondem normalmente.
  final int? failOnCall;
  final BackendException? failure;

  /// Devolve sempre as mesmas frentes, para exercitar a deduplicação.
  final bool repeatFronts;

  final List<_GenerateCall> calls = [];
  var _generated = 0;

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
    List<String> avoidFronts = const [],
    bool fromPdf = false,
  }) async {
    calls.add(
      _GenerateCall(
        text: text,
        quantity: quantity,
        deckId: deckId,
        avoidFronts: List.of(avoidFronts),
        fromPdf: fromPdf,
      ),
    );

    if (calls.length == failOnCall && failure != null) {
      throw failure!;
    }

    return List.generate(cardsPerCall ?? quantity, (index) {
      final number = repeatFronts ? index + 1 : ++_generated;
      return GeneratedCard(front: 'Front $number', back: 'Back $number');
    });
  }

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
}
