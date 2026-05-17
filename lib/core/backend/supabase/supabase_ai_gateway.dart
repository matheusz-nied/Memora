import 'package:supabase_flutter/supabase_flutter.dart';

import '../contracts/ai_gateway.dart';
import '../models/ai_chat_message.dart';
import '../models/backend_exception.dart';
import '../models/generated_card.dart';

class SupabaseAiGateway implements AiGateway {
  const SupabaseAiGateway(this._client);

  static const String _generateCardsFunction = 'generate-cards';
  static const String _generateCardsFromPdfFunction = 'generate-cards-from-pdf';
  static const String _chatFunction = 'chat';
  static const String _cardInsightFunction = 'card-insight';

  final SupabaseClient _client;

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
  }) async {
    final data = await _invoke(_generateCardsFunction, {
      'text': text,
      'quantity': quantity,
      'deckId': deckId,
    });
    return _generatedCardsFromData(data);
  }

  @override
  Future<List<GeneratedCard>> generateCardsFromPdf({
    required String pdfPath,
    required int quantity,
    required String deckId,
  }) async {
    final data = await _invoke(_generateCardsFromPdfFunction, {
      'pdfPath': pdfPath,
      'quantity': quantity,
      'deckId': deckId,
    });
    return _generatedCardsFromData(data);
  }

  List<GeneratedCard> _generatedCardsFromData(Map<String, dynamic> data) {
    final cards = data['cards'];
    if (cards is! List) {
      throw const BackendException('Invalid generated cards response.');
    }

    return cards
        .whereType<Map>()
        .map(
          (card) => GeneratedCard(
            front: card['front'] as String,
            back: card['back'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) async {
    final data = await _invoke(_chatFunction, {
      'deckId': deckId,
      'messages': messages
          .map(
            (message) => {
              'role': message.role.name,
              'content': message.content,
            },
          )
          .toList(),
      'userMessage': userMessage,
    });

    final reply = data['reply'];
    if (reply is! String) {
      throw const BackendException('Invalid chat response.');
    }
    return reply;
  }

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final data = await _invoke(_cardInsightFunction, {
      'deckId': deckId,
      'front': front,
      'back': back,
    });

    final insight = data['insight'];
    if (insight is! String) {
      throw const BackendException('Invalid insight response.');
    }
    return insight;
  }

  Future<Map<String, dynamic>> _invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(functionName, body: body);
    final data = response.data;
    if (data is! Map) {
      throw const BackendException('Invalid function response.');
    }
    if (data['error'] != null) {
      throw BackendException(data['error'].toString());
    }

    return Map<String, dynamic>.from(data);
  }
}
