import 'dart:convert';

import '../backend/models/ai_chat_message.dart';
import '../backend/models/backend_chat_message.dart';
import '../backend/models/backend_exception.dart';
import '../backend/models/generated_card.dart';
import '../constants/app_constants.dart';
import 'agent_templates.dart';

/// Prompts e parsing da DeepSeek, sem nenhum I/O.
///
/// É a porta em Dart do que as Edge Functions fazem em TypeScript
/// (`supabase/functions/_shared/generate_cards.ts`, `chat/index.ts` e
/// `card-insight/index.ts`). As duas cópias precisam andar juntas: mexeu em um
/// prompt de um lado, replique no outro. Não há gerador — são três prompts, e
/// um gerador custaria mais do que a duplicação.
///
/// Separado do gateway de propósito: aqui tudo é função pura, então dá para
/// testar a montagem do prompt e a leitura da resposta sem rede.

/// Contexto do deck que alimenta os prompts.
///
/// No modo nuvem isto vem do Postgres; no modo local, da tabela `decks` do
/// Drift. Os campos são os mesmos nos dois casos.
class DeckAiContext {
  const DeckAiContext({
    required this.title,
    required this.description,
    required this.language,
    required this.level,
    required this.agentName,
    required this.agentPrompt,
    required this.agentTemplate,
  });

  final String title;
  final String? description;
  final String language;
  final String level;
  final String agentName;
  final String? agentPrompt;
  final String agentTemplate;

  String get descriptionOrFallback {
    final value = description?.trim();
    return value == null || value.isEmpty ? 'Sem descrição' : value;
  }
}

// ---------------------------------------------------------------------------
// Geração de cards
// ---------------------------------------------------------------------------

/// Monta o prompt de um lote de cards.
///
/// [isChunk] avisa que o material é uma fatia de um documento maior — sem
/// isso a IA tenta resumir "o texto todo" e inventa o que não está ali.
String buildGenerateCardsPrompt({
  required DeckAiContext deck,
  required String text,
  required int quantity,
  List<String> avoidFronts = const [],
  bool isChunk = false,
}) {
  final materialLabel = isChunk
      ? 'Trecho do material (parte de um documento maior)'
      : 'Material';

  final chunkRule = isChunk
      ? '\n- O material é apenas um trecho do documento. Crie cards somente '
            'sobre o que está neste trecho.'
      : '';

  final avoidBlock = avoidFronts.isEmpty
      ? ''
      : '\n'
            'Perguntas que JÁ foram geradas para este deck. NÃO repita nenhuma '
            'delas, nem variações com as mesmas palavras ou a mesma resposta. '
            'Cubra aspectos ainda não abordados:\n'
            '${avoidFronts.map((front) => '- $front').join('\n')}\n';

  return '''

Gere $quantity flashcards em ${deck.language}, nível ${deck.level}.

Deck: ${deck.title}
Descrição do deck: ${deck.descriptionOrFallback}

$materialLabel:
$text
${avoidBlock}Regras:
- Cada card deve ter uma pergunta objetiva em "front".
- Cada resposta deve ser clara e curta em "back".
- Não invente fatos fora do material.
- Evite cards duplicados.$chunkRule
- Responda exclusivamente em JSON válido no formato:
{
  "cards": [
    { "front": "pergunta", "back": "resposta" }
  ]
}
''';
}

/// Lê os cards da resposta da IA.
///
/// Tolerante de propósito: mesmo com `response_format: json_object` a DeepSeek
/// às vezes devolve o JSON cercado por ``` ou com texto em volta. Rejeitar
/// nesses casos jogaria fora um lote pago que estava correto.
List<GeneratedCard> parseGeneratedCards(String content, int quantity) {
  final cleaned = content
      .trim()
      .replaceFirst(RegExp(r'^```json\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^```\s*'), '')
      .replaceFirst(RegExp(r'\s*```$'), '');

  final Object? parsed;
  try {
    parsed = jsonDecode(_extractJsonObject(cleaned));
  } on FormatException {
    throw const BackendException(
      'A IA retornou uma resposta em formato inválido.',
      code: 'invalid_ai_json',
    );
  }

  final cards = parsed is Map ? parsed['cards'] : null;
  if (cards is! List) {
    throw const BackendException(
      'A IA não retornou a lista de cards esperada.',
      code: 'invalid_ai_cards',
    );
  }

  final normalized = <GeneratedCard>[];
  for (final card in cards) {
    if (normalized.length == quantity) {
      break;
    }
    if (card is! Map) {
      continue;
    }

    final front = _truncate(card['front'], AppConstants.kMaxCardFront);
    final back = _truncate(card['back'], AppConstants.kMaxCardBack);
    if (front.isEmpty || back.isEmpty) {
      continue;
    }

    normalized.add(GeneratedCard(front: front, back: back));
  }

  if (normalized.isEmpty) {
    throw const BackendException(
      'A IA não retornou cards válidos.',
      code: 'empty_ai_cards',
    );
  }

  return normalized;
}

String _truncate(Object? value, int maxLength) {
  final text = (value ?? '').toString().trim();
  return text.length <= maxLength ? text : text.substring(0, maxLength);
}

/// Recorta do primeiro `{` ao último `}`, descartando qualquer prosa em volta.
String _extractJsonObject(String content) {
  final start = content.indexOf('{');
  final end = content.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    return content;
  }
  return content.substring(start, end + 1);
}

// ---------------------------------------------------------------------------
// Insight
// ---------------------------------------------------------------------------

String buildInsightPrompt({
  required DeckAiContext deck,
  required String front,
  required String back,
}) {
  return '''

Explique de forma aprofundada o seguinte flashcard, trazendo exemplos, contexto, dicas de memorização e conexões com outros conceitos.

Idioma: ${deck.language}
Nível: ${deck.level}
Deck: ${deck.title}
Descrição do deck: ${deck.descriptionOrFallback}

Frente: $front
Verso: $back

Regras:
- Seja claro e útil para revisão.
- Não invente fatos que contradigam o card.
- Não use JSON.
- Não inclua markdown pesado; texto simples é suficiente.
''';
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

/// Monta o prompt de sistema do agente do deck.
///
/// Os templates vêm de [AgentTemplate], que é a fonte original — a cópia em
/// `supabase/functions/chat/index.ts` é que segue este arquivo.
String buildChatSystemPrompt({
  required DeckAiContext deck,
  required List<GeneratedCard> cards,
}) {
  final agentPrompt = deck.agentPrompt?.trim();
  final basePrompt =
      deck.agentTemplate == AgentTemplate.custom.id &&
          agentPrompt != null &&
          agentPrompt.isNotEmpty
      ? agentPrompt
      : AgentTemplate.fromId(deck.agentTemplate).defaultPrompt;

  final deckContext = cards.isEmpty
      ? 'Sem cards no deck ainda.'
      : cards.indexed
            .map(
              (entry) =>
                  '${entry.$1 + 1}. Frente: ${entry.$2.front} | '
                  'Verso: ${entry.$2.back}',
            )
            .join('\n');

  return interpolatePrompt(
    basePrompt,
    name: deck.agentName,
    deckTitle: deck.title,
    deckContext: deckContext,
    language: deck.language,
    level: deck.level,
  );
}

/// Teto adicional de caracteres do histórico, cortando as mensagens mais
/// antigas. Protege contra [AppConstants.kMaxChatMessages] no tamanho máximo.
const int kMaxChatHistoryChars = 24000;

/// Teto de caracteres de uma única mensagem.
const int kMaxChatMessageChars = 4000;

/// Mantém apenas as mensagens válidas mais recentes, dentro do teto de
/// quantidade e de caracteres. Descarta as mais antigas primeiro.
///
/// O cliente já limita o tamanho da conversa, mas o histórico chega como
/// argumento: sem teto aqui, uma conversa longa vira uma chamada de milhões
/// de tokens paga pela chave do usuário.
List<AiChatMessage> boundedChatHistory(List<AiChatMessage> messages) {
  final valid = messages
      .where((message) => message.content.trim().isNotEmpty)
      .map(
        (message) => AiChatMessage(
          role: message.role,
          content: message.content.length <= kMaxChatMessageChars
              ? message.content
              : message.content.substring(0, kMaxChatMessageChars),
        ),
      )
      .toList();

  final recent = valid.length <= AppConstants.kMaxChatMessages
      ? valid
      : valid.sublist(valid.length - AppConstants.kMaxChatMessages);

  var budget = kMaxChatHistoryChars;
  final kept = <AiChatMessage>[];
  for (var index = recent.length - 1; index >= 0; index--) {
    budget -= recent[index].content.length;
    if (budget < 0) {
      break;
    }
    kept.insert(0, recent[index]);
  }

  return kept;
}

String chatRoleName(BackendChatRole role) => role.name;

// ---------------------------------------------------------------------------
// Erros da API
// ---------------------------------------------------------------------------

/// Traduz o status HTTP da DeepSeek para uma mensagem que o usuário entenda.
///
/// No modo local a chave é dele, então 401 e 402 são acionáveis: dizer
/// "erro 402" mandaria a pessoa procurar no Google o que fazer.
String deepSeekErrorMessage(int status, {required String fallback}) {
  return switch (status) {
    400 => 'A DeepSeek rejeitou o formato da requisição.',
    401 => 'Chave da DeepSeek inválida ou ausente.',
    402 => 'A conta da DeepSeek está sem saldo/crédito.',
    429 => 'Limite de uso da DeepSeek atingido. Tente novamente em instantes.',
    _ => fallback,
  };
}

/// Código estável para o status HTTP.
///
/// O 429 vira [BackendException.codeRateLimited] porque é o que faz o
/// `GenerateRepository` esperar e repetir o lote — que é exatamente o
/// tratamento certo para um limite por minuto.
String deepSeekErrorCode(int status) {
  return status == 429 ? BackendException.codeRateLimited : 'deepseek_$status';
}
