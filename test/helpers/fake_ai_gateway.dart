import 'dart:typed_data';

import 'package:memora/core/backend/contracts/ai_gateway.dart';
import 'package:memora/core/backend/contracts/pdf_text_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/backend/models/pdf_extraction_result.dart';

/// Substitui a DeepSeek nos testes.
///
/// Os contratos existem exatamente para isto: nenhum teste precisa de rede, e
/// nenhum precisa de chave. Cada campo `on...` deixa o teste decidir o que a
/// IA responde; sem eles, as respostas padrão bastam para exercitar o caminho
/// feliz.
class FakeAiGateway implements AiGateway {
  FakeAiGateway({this.onGenerateCards, this.onChat, this.onInsight});

  final Future<List<GeneratedCard>> Function(int quantity)? onGenerateCards;
  final Future<String> Function(String userMessage)? onChat;
  final Future<String> Function()? onInsight;

  final List<String> chatCalls = <String>[];
  int generateCallCount = 0;
  int insightCallCount = 0;

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
    List<String> avoidFronts = const [],
    bool fromPdf = false,
  }) {
    generateCallCount += 1;
    if (onGenerateCards != null) {
      return onGenerateCards!(quantity);
    }
    return Future.value([
      for (var i = 0; i < quantity; i++)
        GeneratedCard(front: 'frente $i', back: 'verso $i'),
    ]);
  }

  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) {
    chatCalls.add(userMessage);
    if (onChat != null) {
      return onChat!(userMessage);
    }
    return Future.value('resposta do tutor');
  }

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) {
    insightCallCount += 1;
    if (onInsight != null) {
      return onInsight!();
    }
    return Future.value('insight sobre $front');
  }
}

/// PDF de mentira: devolve o texto que o teste mandar, sem tocar em bytes.
class FakePdfTextGateway implements PdfTextGateway {
  FakePdfTextGateway({this.text = 'texto do pdf', this.pages = 1});

  final String text;
  final int pages;

  @override
  Future<PdfExtractionResult> extractText({
    required String fileName,
    required Uint8List bytes,
  }) {
    return Future.value(PdfExtractionResult(text: text, pages: pages));
  }
}
