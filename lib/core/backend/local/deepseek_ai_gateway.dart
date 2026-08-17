import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../ai/deepseek_prompts.dart';
import '../../database/app_database.dart';
import '../contracts/ai_gateway.dart';
import '../models/ai_chat_message.dart';
import '../models/backend_exception.dart';
import '../models/generated_card.dart';

/// Fala direto com a DeepSeek usando a chave do próprio usuário.
///
/// Sem intermediário: o contexto do deck vem do Drift do aparelho e a conta é
/// paga pela chave cadastrada, então não há quota a controlar.
///
/// A orquestração continua fora daqui: lotes, fatiamento do material,
/// anti-duplicação, progresso e resultado parcial são do `GenerateRepository`.
/// Este gateway resolve uma chamada de cada vez.
class DeepSeekAiGateway implements AiGateway {
  DeepSeekAiGateway({
    required AppDatabase database,
    required String? Function() readApiKey,
    http.Client? httpClient,
  }) : _database = database,
       _readApiKey = readApiKey,
       _httpClient = httpClient ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://api.deepseek.com/chat/completions',
  );

  static const String _model = 'deepseek-chat';

  /// Tetos de tokens por operação. Sem eles a resposta não tem teto de custo —
  /// e quem paga é a chave do usuário.
  static const int _maxTokensGenerate = 4000;
  static const int _maxTokensChat = 1500;
  static const int _maxTokensInsight = 1200;

  /// Um lote de 15 cards é a chamada mais longa; conversa e insight respondem
  /// bem mais rápido e não merecem a mesma paciência.
  static const Duration _generateTimeout = Duration(seconds: 90);
  static const Duration _defaultTimeout = Duration(seconds: 45);

  final AppDatabase _database;
  final String? Function() _readApiKey;
  final http.Client _httpClient;

  /// Devolve o pool de conexões quando o gateway é descartado.
  ///
  /// Sem isto, cada recriação do `aiGatewayProvider` deixa um socket keep-alive
  /// para trás.
  void close() => _httpClient.close();

  @override
  Future<List<GeneratedCard>> generateCards({
    required String text,
    required int quantity,
    required String deckId,
    List<String> avoidFronts = const [],
    bool fromPdf = false,
  }) async {
    final deck = await _deckContext(deckId);
    final prompt = buildGenerateCardsPrompt(
      deck: deck,
      text: text,
      quantity: quantity,
      avoidFronts: avoidFronts,
      isChunk: fromPdf,
    );

    return _withOneRetry(() async {
      final content = await _complete(
        messages: [
          const {
            'role': 'system',
            'content':
                'Você gera flashcards objetivos, claros e fiéis ao material '
                'do usuário. Responda somente com JSON válido.',
          },
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.3,
        maxTokens: _maxTokensGenerate,
        jsonMode: true,
        timeout: _generateTimeout,
        fallback: 'A DeepSeek não conseguiu processar a geração agora.',
      );

      return parseGeneratedCards(content, quantity);
    });
  }

  @override
  Future<String> chat({
    required String deckId,
    required List<AiChatMessage> messages,
    required String userMessage,
  }) async {
    final deck = await _deckContext(deckId);
    final cards = await _database.cardsDao.getCardsForDeck(deckId);

    // Os 20 mais recentes, do mais novo para o mais antigo: o que o usuário
    // acabou de estudar é o que mais provavelmente motivou a pergunta.
    final recentCards =
        (cards.length <= 20 ? cards : cards.sublist(cards.length - 20)).reversed
            .map((card) => GeneratedCard(front: card.front, back: card.back))
            .toList();

    return _complete(
      messages: [
        {
          'role': 'system',
          'content': buildChatSystemPrompt(deck: deck, cards: recentCards),
        },
        for (final message in boundedChatHistory(messages))
          {'role': chatRoleName(message.role), 'content': message.content},
        {'role': 'user', 'content': userMessage},
      ],
      temperature: 0.4,
      maxTokens: _maxTokensChat,
      timeout: _defaultTimeout,
      fallback: 'A DeepSeek não conseguiu processar a mensagem agora.',
    );
  }

  @override
  Future<String> generateCardInsight({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final deck = await _deckContext(deckId);

    return _complete(
      messages: [
        const {
          'role': 'system',
          'content':
              'Você é um tutor que explica flashcards com clareza, exemplos e '
              'dicas de memorização. Responda somente com o insight em texto '
              'simples.',
        },
        {
          'role': 'user',
          'content': buildInsightPrompt(deck: deck, front: front, back: back),
        },
      ],
      temperature: 0.35,
      maxTokens: _maxTokensInsight,
      timeout: _defaultTimeout,
      fallback: 'A DeepSeek não conseguiu gerar o insight agora.',
    );
  }

  Future<DeckAiContext> _deckContext(String deckId) async {
    final deck = await _database.decksDao.getDeckById(deckId);
    if (deck == null) {
      throw const BackendException(
        'Deck não encontrado.',
        code: 'deck_not_found',
      );
    }

    return DeckAiContext(
      title: deck.title,
      description: deck.description,
      language: deck.agentLanguage,
      level: deck.agentLevel,
      agentName: deck.agentName,
      agentPrompt: deck.agentPrompt,
      agentTemplate: deck.agentTemplate,
    );
  }

  /// Uma requisição à DeepSeek, devolvendo o texto da resposta.
  Future<String> _complete({
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    required String fallback,
    bool jsonMode = false,
  }) async {
    final apiKey = _readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const BackendException(
        'Cadastre sua chave da DeepSeek para usar os recursos de IA.',
        code: 'missing_api_key',
      );
    }

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'temperature': temperature,
              'max_tokens': maxTokens,
              if (jsonMode) 'response_format': {'type': 'json_object'},
              'messages': messages,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const BackendException(
        'A IA demorou demais para responder. Tente novamente.',
        code: BackendException.codeAiTimeout,
      );
    } on http.ClientException catch (error) {
      throw BackendException(
        'Não foi possível falar com a DeepSeek: ${error.message}',
        code: 'network_error',
      );
    }

    if (response.statusCode != 200) {
      throw BackendException(
        deepSeekErrorMessage(response.statusCode, fallback: fallback),
        code: deepSeekErrorCode(response.statusCode),
      );
    }

    final Object? decoded;
    try {
      // A DeepSeek responde em UTF-8, e `response.body` assume latin-1 quando
      // o header não traz o charset — sem isto os acentos voltam quebrados.
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const BackendException(
        'A IA retornou uma resposta em formato inválido.',
        code: 'invalid_ai_json',
      );
    }

    final content = _contentOf(decoded);
    if (content == null || content.trim().isEmpty) {
      throw const BackendException(
        'A IA retornou uma resposta vazia.',
        code: 'empty_ai_response',
      );
    }

    return content.trim();
  }

  String? _contentOf(Object? decoded) {
    if (decoded is! Map) {
      return null;
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }
    final first = choices.first;
    if (first is! Map) {
      return null;
    }
    final message = first['message'];
    if (message is! Map) {
      return null;
    }
    final content = message['content'];
    return content is String ? content : null;
  }

  /// Repete uma vez o que tem chance de ser transitório: falha de rede, 5xx e
  /// resposta que não deu para interpretar.
  ///
  /// Não repete 401/402 (não melhora), 429 nem timeout — esses dois o
  /// `GenerateRepository` já repete, com espera antes.
  Future<T> _withOneRetry<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on BackendException catch (error) {
      if (!_isRetryable(error)) {
        rethrow;
      }
      return operation();
    }
  }

  bool _isRetryable(BackendException error) {
    const retryableCodes = {
      'network_error',
      'invalid_ai_json',
      'invalid_ai_cards',
      'empty_ai_cards',
      'empty_ai_response',
    };

    if (retryableCodes.contains(error.code)) {
      return true;
    }

    final status = int.tryParse(error.code?.split('_').last ?? '');
    return status != null && status >= 500;
  }
}
