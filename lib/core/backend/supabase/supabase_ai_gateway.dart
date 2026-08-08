import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../contracts/ai_gateway.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_quota_status.dart';
import '../models/backend_exception.dart';
import '../models/generated_card.dart';

class SupabaseAiGateway implements AiGateway {
  const SupabaseAiGateway(this._client);

  static const String _generateCardsFunction = 'generate-cards';
  static const String _chatFunction = 'chat';
  static const String _cardInsightFunction = 'card-insight';
  static const String _quotaStatusRpc = 'ai_quota_status';

  /// Sem timeout, uma Edge Function pendurada deixa a tela em "gerando..."
  /// para sempre. Os valores dão folga sobre o timeout de 60s que a própria
  /// function aplica na chamada à IA.
  static const Duration _generateTimeout = Duration(seconds: 90);
  static const Duration _defaultTimeout = Duration(seconds: 45);

  final SupabaseClient _client;

  @override
  Future<AiQuotaStatus> fetchQuotaStatus() async {
    final Object? data;
    try {
      data = await _client.rpc<Object?>(_quotaStatusRpc);
    } on PostgrestException catch (error) {
      throw BackendException(error.message, code: error.code);
    }

    final row = data is List ? data.firstOrNull : data;
    if (row is! Map) {
      throw const BackendException('Resposta de quota inválida.');
    }

    return AiQuotaStatus(
      used: (row['used'] as num?)?.toInt() ?? 0,
      quota: (row['quota'] as num?)?.toInt() ?? 0,
      tier: row['tier'] as String? ?? 'free',
      periodEnd:
          DateTime.tryParse(row['period_end'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
    List<String> avoidFronts = const [],
    bool fromPdf = false,
  }) async {
    final data = await _invoke(_generateCardsFunction, {
      'text': text,
      'quantity': quantity,
      'deckId': deckId,
      'source': fromPdf ? 'pdf' : 'text',
      'avoidFronts': avoidFronts,
    }, timeout: _generateTimeout);
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
    Map<String, dynamic> body, {
    Duration timeout = _defaultTimeout,
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions
          .invoke(functionName, body: body)
          .timeout(timeout);
    } on FunctionException catch (error) {
      // As Edge Functions respondem erro com status >= 400, e nesse caso o
      // functions_client lança em vez de devolver o corpo. Sem este catch a
      // mensagem em português da function era descartada e a UI mostrava o
      // toString() cru da FunctionException.
      throw _exceptionFromDetails(error.details);
    } on TimeoutException {
      throw const BackendException(
        'A operação demorou demais. Verifique sua conexão e tente novamente.',
        code: BackendException.codeClientTimeout,
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw const BackendException('Invalid function response.');
    }
    if (data['error'] != null) {
      throw _exceptionFromDetails(data);
    }

    return Map<String, dynamic>.from(data);
  }

  BackendException _exceptionFromDetails(Object? details) {
    if (details is Map) {
      final message = details['error'];
      if (message != null) {
        return BackendException(
          message.toString(),
          code: details['code'] as String?,
        );
      }
    }

    if (details is String && details.trim().isNotEmpty) {
      return BackendException(details.trim());
    }

    return const BackendException(
      'Não foi possível concluir a operação de IA agora.',
    );
  }
}
