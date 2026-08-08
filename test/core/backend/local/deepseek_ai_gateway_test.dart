import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memora/core/backend/local/deepseek_ai_gateway.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_chat_message.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 8, 7).millisecondsSinceEpoch;

    await database.decksDao.upsertDeck(
      DecksTableCompanion.insert(
        id: 'deck-1',
        userId: 'local-user',
        title: 'Biologia Celular',
        description: const Value('Organelas'),
        agentName: const Value('Sensei'),
        agentTemplate: const Value('general'),
        agentLanguage: const Value('português'),
        agentLevel: const Value('iniciante'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async => database.close());

  /// Corpo no formato da API de chat completions.
  String completionBody(String content) {
    return jsonEncode({
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    });
  }

  /// Resposta completa, com o mesmo `content-type` que a DeepSeek devolve.
  http.Response completion(String content) {
    return http.Response(
      completionBody(content),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  DeepSeekAiGateway gateway(MockClient client, {String? apiKey = 'sk-teste'}) {
    return DeepSeekAiGateway(
      database: database,
      readApiKey: () => apiKey,
      httpClient: client,
    );
  }

  test('gera cards a partir do contexto do deck no Drift', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return completion(
        '{"cards":[{"front":"O que é ATP?","back":"Energia"}]}',
      );
    });

    final cards = await gateway(
      client,
    ).generateCards(text: 'material de estudo', quantity: 5, deckId: 'deck-1');

    expect(cards.single.front, 'O que é ATP?');

    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['model'], 'deepseek-chat');
    expect(body['response_format'], {'type': 'json_object'});
    expect(sent.headers['Authorization'], 'Bearer sk-teste');

    // O prompt precisa carregar o deck: é o que separa um card fiel ao
    // material de um card genérico.
    final messages = body['messages'] as List<dynamic>;
    expect(messages.last['content'], contains('Biologia Celular'));
    expect(messages.last['content'], contains('material de estudo'));
  });

  test('sem chave cadastrada nem chega a fazer requisição', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return completion('{}');
    });

    await expectLater(
      gateway(
        client,
        apiKey: null,
      ).generateCards(text: 'material', quantity: 5, deckId: 'deck-1'),
      throwsA(
        isA<BackendException>().having(
          (error) => error.code,
          'code',
          'missing_api_key',
        ),
      ),
    );
    expect(calls, 0);
  });

  test('429 vira rate_limited e não é repetido aqui', () async {
    // Quem repete o lote com espera é o GenerateRepository: repetir na hora
    // só gastaria a segunda tentativa contra o mesmo limite.
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('{"error":"slow down"}', 429);
    });

    await expectLater(
      gateway(
        client,
      ).generateCards(text: 'material', quantity: 5, deckId: 'deck-1'),
      throwsA(
        isA<BackendException>().having(
          (error) => error.code,
          'code',
          BackendException.codeRateLimited,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('401 explica que a chave está inválida, sem repetir', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('{"error":"unauthorized"}', 401);
    });

    await expectLater(
      gateway(
        client,
      ).generateCards(text: 'material', quantity: 5, deckId: 'deck-1'),
      throwsA(
        isA<BackendException>().having(
          (error) => error.message,
          'message',
          contains('Chave da DeepSeek inválida'),
        ),
      ),
    );
    expect(calls, 1);
  });

  test('5xx é repetido uma vez', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response('{"error":"boom"}', 503);
      }
      return completion('{"cards":[{"front":"P","back":"R"}]}');
    });

    final cards = await gateway(
      client,
    ).generateCards(text: 'material', quantity: 5, deckId: 'deck-1');

    expect(calls, 2);
    expect(cards.single.front, 'P');
  });

  test('deck inexistente falha antes de gastar uma chamada', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return completion('{}');
    });

    await expectLater(
      gateway(
        client,
      ).generateCards(text: 'material', quantity: 5, deckId: 'deck-fantasma'),
      throwsA(
        isA<BackendException>().having(
          (error) => error.code,
          'code',
          'deck_not_found',
        ),
      ),
    );
    expect(calls, 0);
  });

  test('quota não se aplica e lança em vez de devolver zeros', () async {
    // Um status zerado faria `GenerateRepository._ensureQuotaFor` ler
    // "sem créditos" e bloquear toda geração. A exceção ele engole.
    final client = MockClient((request) async => http.Response('{}', 200));

    expect(
      () => gateway(client).fetchQuotaStatus(),
      throwsA(isA<BackendException>()),
    );
  });

  test('o chat monta o prompt de sistema com o agente do deck', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return completion('Claro, vamos lá!');
    });

    final reply = await gateway(client).chat(
      deckId: 'deck-1',
      messages: const [
        AiChatMessage(role: BackendChatRole.user, content: 'oi'),
        AiChatMessage(role: BackendChatRole.assistant, content: 'olá'),
      ],
      userMessage: 'me explique organelas',
    );

    expect(reply, 'Claro, vamos lá!');

    final messages =
        (jsonDecode(sent.body) as Map<String, dynamic>)['messages']
            as List<dynamic>;
    expect(messages.first['role'], 'system');
    expect(messages.first['content'], contains('Sensei'));
    expect(messages.last, {'role': 'user', 'content': 'me explique organelas'});
    // sistema + histórico (2) + mensagem atual
    expect(messages, hasLength(4));
  });

  test('acentos voltam íntegros mesmo sem charset no header', () async {
    final client = MockClient((request) async {
      return http.Response.bytes(
        utf8.encode(completionBody('Explicação sobre mitocôndrias')),
        200,
      );
    });

    final insight = await gateway(
      client,
    ).generateCardInsight(deckId: 'deck-1', front: 'P', back: 'R');

    expect(insight, 'Explicação sobre mitocôndrias');
  });
}
