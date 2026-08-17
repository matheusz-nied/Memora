import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/ai/agent_templates.dart';
import 'package:memora/core/ai/deepseek_prompts.dart';
import 'package:memora/core/backend/models/ai_chat_message.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/backend/models/generated_card.dart';
import 'package:memora/core/constants/app_constants.dart';

/// Cobre a montagem dos prompts e a leitura da resposta da DeepSeek — a parte
/// que dá para exercitar sem rede, e a que quebra em silêncio: um prompt
/// malformado não lança, só devolve card ruim.
void main() {
  const deck = DeckAiContext(
    title: 'Biologia Celular',
    description: 'Organelas e funções',
    language: 'português',
    level: 'iniciante',
    agentName: 'Tutor',
    agentPrompt: null,
    agentTemplate: 'general',
  );

  group('parseGeneratedCards', () {
    test('lê um JSON limpo', () {
      final cards = parseGeneratedCards(
        '{"cards":[{"front":"O que é mitocôndria?","back":"Organela"}]}',
        5,
      );

      expect(cards, hasLength(1));
      expect(cards.single.front, 'O que é mitocôndria?');
      expect(cards.single.back, 'Organela');
    });

    test('remove a cerca de bloco de código', () {
      final cards = parseGeneratedCards(
        '```json\n{"cards":[{"front":"P","back":"R"}]}\n```',
        5,
      );

      expect(cards.single.front, 'P');
    });

    test('ignora prosa em volta do JSON', () {
      // Acontece de verdade mesmo com response_format json_object: descartar
      // aqui jogaria fora um lote que o usuário já pagou.
      final cards = parseGeneratedCards(
        'Claro! Aqui estão os cards:\n'
        '{"cards":[{"front":"P","back":"R"}]}\n'
        'Espero ter ajudado.',
        5,
      );

      expect(cards.single.back, 'R');
    });

    test('trunca frente e verso nos limites do card', () {
      final cards = parseGeneratedCards(
        '{"cards":[{"front":"${'a' * 400}","back":"${'b' * 800}"}]}',
        5,
      );

      expect(cards.single.front, hasLength(AppConstants.kMaxCardFront));
      expect(cards.single.back, hasLength(AppConstants.kMaxCardBack));
    });

    test('descarta cards sem frente ou sem verso', () {
      final cards = parseGeneratedCards(
        '{"cards":['
        '{"front":"","back":"R"},'
        '{"front":"P","back":"  "},'
        '{"front":"P2","back":"R2"}'
        ']}',
        5,
      );

      expect(cards, hasLength(1));
      expect(cards.single.front, 'P2');
    });

    test('respeita a quantidade pedida', () {
      final cards = parseGeneratedCards(
        '{"cards":['
        '{"front":"1","back":"a"},'
        '{"front":"2","back":"b"},'
        '{"front":"3","back":"c"}'
        ']}',
        2,
      );

      expect(cards, hasLength(2));
    });

    test('JSON quebrado vira invalid_ai_json', () {
      expect(
        () => parseGeneratedCards('{"cards":[{"front":', 5),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'invalid_ai_json',
          ),
        ),
      );
    });

    test('resposta sem a lista de cards vira invalid_ai_cards', () {
      expect(
        () => parseGeneratedCards('{"resultado":"ok"}', 5),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'invalid_ai_cards',
          ),
        ),
      );
    });

    test('lista só com cards inválidos vira empty_ai_cards', () {
      expect(
        () => parseGeneratedCards('{"cards":[{"front":"","back":""}]}', 5),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'empty_ai_cards',
          ),
        ),
      );
    });
  });

  group('buildGenerateCardsPrompt', () {
    test('leva quantidade, idioma, nível e contexto do deck', () {
      final prompt = buildGenerateCardsPrompt(
        deck: deck,
        text: 'Conteúdo do material',
        quantity: 7,
      );

      expect(prompt, contains('Gere 7 flashcards em português'));
      expect(prompt, contains('nível iniciante'));
      expect(prompt, contains('Deck: Biologia Celular'));
      expect(prompt, contains('Descrição do deck: Organelas e funções'));
      expect(prompt, contains('Conteúdo do material'));
    });

    test('usa o texto padrão quando o deck não tem descrição', () {
      const withoutDescription = DeckAiContext(
        title: 'T',
        description: '  ',
        language: 'português',
        level: 'iniciante',
        agentName: 'Tutor',
        agentPrompt: null,
        agentTemplate: 'general',
      );

      expect(
        buildGenerateCardsPrompt(
          deck: withoutDescription,
          text: 'material',
          quantity: 5,
        ),
        contains('Descrição do deck: Sem descrição'),
      );
    });

    test('sem avoidFronts não aparece o bloco anti-duplicação', () {
      final prompt = buildGenerateCardsPrompt(
        deck: deck,
        text: 'material',
        quantity: 5,
      );

      expect(prompt, isNot(contains('NÃO repita')));
    });

    test('com avoidFronts lista as frentes já geradas', () {
      final prompt = buildGenerateCardsPrompt(
        deck: deck,
        text: 'material',
        quantity: 5,
        avoidFronts: const ['O que é ATP?', 'O que é ribossomo?'],
      );

      expect(prompt, contains('NÃO repita'));
      expect(prompt, contains('- O que é ATP?'));
      expect(prompt, contains('- O que é ribossomo?'));
    });

    test('marca que o material é um trecho quando veio de PDF', () {
      final prompt = buildGenerateCardsPrompt(
        deck: deck,
        text: 'material',
        quantity: 5,
        isChunk: true,
      );

      expect(prompt, contains('Trecho do material'));
      expect(prompt, contains('somente sobre o que está neste trecho'));
    });
  });

  group('buildChatSystemPrompt', () {
    test('interpola nome, título e cards no template do deck', () {
      final prompt = buildChatSystemPrompt(
        deck: deck,
        cards: const [GeneratedCard(front: 'O que é ATP?', back: 'Energia')],
      );

      expect(prompt, contains('Biologia Celular'));
      expect(prompt, contains('1. Frente: O que é ATP? | Verso: Energia'));
      expect(prompt, isNot(contains('{deck_context}')));
      expect(prompt, isNot(contains('{name}')));
    });

    test('avisa quando o deck ainda não tem cards', () {
      expect(
        buildChatSystemPrompt(deck: deck, cards: const []),
        contains('Sem cards no deck ainda.'),
      );
    });

    test('template custom usa o prompt escrito pelo usuário', () {
      const custom = DeckAiContext(
        title: 'T',
        description: null,
        language: 'português',
        level: 'iniciante',
        agentName: 'Sensei',
        agentPrompt: 'Você é {name} e responde em haicai.',
        agentTemplate: 'custom',
      );

      expect(
        buildChatSystemPrompt(deck: custom, cards: const []),
        'Você é Sensei e responde em haicai.',
      );
    });

    test('custom sem prompt cai no template padrão', () {
      const custom = DeckAiContext(
        title: 'T',
        description: null,
        language: 'português',
        level: 'iniciante',
        agentName: 'Tutor',
        agentPrompt: '   ',
        agentTemplate: 'custom',
      );

      expect(
        buildChatSystemPrompt(deck: custom, cards: const []),
        contains('assistente do deck'),
      );
    });

    test('template desconhecido cai no geral', () {
      const unknown = DeckAiContext(
        title: 'T',
        description: null,
        language: 'português',
        level: 'iniciante',
        agentName: 'Tutor',
        agentPrompt: null,
        agentTemplate: 'inexistente',
      );

      expect(
        buildChatSystemPrompt(deck: unknown, cards: const []),
        contains(
          AgentTemplate.general.defaultPrompt
              .split('\n')
              .first
              .replaceAll('{name}', 'Tutor')
              .replaceAll('{deck_title}', 'T'),
        ),
      );
    });
  });

  group('boundedChatHistory', () {
    AiChatMessage message(String content) =>
        AiChatMessage(role: ChatRole.user, content: content);

    test('mantém apenas as mensagens mais recentes', () {
      final history = List.generate(
        AppConstants.kMaxChatMessages + 10,
        (index) => message('mensagem $index'),
      );

      final bounded = boundedChatHistory(history);

      expect(bounded, hasLength(AppConstants.kMaxChatMessages));
      expect(bounded.last.content, history.last.content);
    });

    test('descarta as mais antigas ao estourar o orçamento de caracteres', () {
      // Abaixo do teto por mensagem, para o corte medido aqui ser o do
      // orçamento total e não o do truncamento individual.
      const size = kMaxChatHistoryChars ~/ 8;
      expect(size, lessThan(kMaxChatMessageChars));

      final history = List.generate(12, (index) => message('x' * size));
      final bounded = boundedChatHistory(history);

      expect(bounded, hasLength(8));
      expect(bounded.length * size, kMaxChatHistoryChars);
    });

    test('trunca uma mensagem longa demais', () {
      final bounded = boundedChatHistory([
        message('y' * (kMaxChatMessageChars + 500)),
      ]);

      expect(bounded.single.content, hasLength(kMaxChatMessageChars));
    });

    test('ignora mensagens vazias', () {
      expect(boundedChatHistory([message('   ')]), isEmpty);
    });
  });

  group('erros da API', () {
    test('429 vira rate_limited para o repositório esperar e repetir', () {
      expect(deepSeekErrorCode(429), BackendException.codeRateLimited);
    });

    test('demais status viram deepseek_<status>', () {
      expect(deepSeekErrorCode(500), 'deepseek_500');
      expect(deepSeekErrorCode(401), 'deepseek_401');
    });

    test('mensagens acionáveis para os erros de conta', () {
      expect(
        deepSeekErrorMessage(401, fallback: 'x'),
        contains('Chave da DeepSeek inválida'),
      );
      expect(deepSeekErrorMessage(402, fallback: 'x'), contains('sem saldo'));
      expect(deepSeekErrorMessage(503, fallback: 'genérico'), 'genérico');
    });
  });
}
