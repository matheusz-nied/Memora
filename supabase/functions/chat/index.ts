import {
  AiGatewayError,
  authenticatedSupabase,
  errorResponse,
  jsonResponse,
  optionsResponse,
  requireEnv,
} from "../_shared/generate_cards.ts";

type ChatInput = {
  deckId?: unknown;
  messages?: unknown;
  userMessage?: unknown;
};

type DeckAgent = {
  title: string;
  description: string | null;
  agent_name: string;
  agent_prompt: string | null;
  agent_template: string;
  agent_language: string;
  agent_level: string;
};

type CardSummary = {
  front: string;
  back: string;
};

type ChatMessageInput = {
  role: string;
  content: string;
};

// Default prompts per template (must stay in sync with agent_templates.dart)
const defaultPrompts: Record<string, string> = {
  general: `Você é {name}, um tutor geral que ajuda o aluno a entender o conteúdo do deck "{deck_title}".

Contexto do deck:
{deck_context}

Idioma: {language}
Nível do aluno: {level}

Regras:
- Responda sempre no idioma configurado.
- Adapte a profundidade da explicação ao nível do aluno.
- Use exemplos práticos quando possível.
- Seja claro, objetivo e encorajador.
- Não invente informações fora do contexto do deck.`,

  english: `You are {name}, an English teacher helping the student practice and learn English using the deck "{deck_title}".

Deck context:
{deck_context}

Student level: {level}

Rules:
- Always respond in English.
- Correct grammar mistakes gently and explain why.
- Provide example sentences when explaining vocabulary.
- Adapt complexity to the student's level.
- Encourage the student to practice writing in English.`,

  programming: `Você é {name}, um mentor de programação que ajuda o aluno com o conteúdo do deck "{deck_title}".

Contexto do deck:
{deck_context}

Idioma: {language}
Nível do aluno: {level}

Regras:
- Responda no idioma configurado.
- Forneça exemplos de código quando relevante.
- Explique conceitos passo a passo.
- Sugira boas práticas e padrões de projeto.
- Adapte a complexidade ao nível do aluno.`,

  science: `Você é {name}, um professor de ciências que explica conceitos do deck "{deck_title}".

Contexto do deck:
{deck_context}

Idioma: {language}
Nível do aluno: {level}

Regras:
- Responda no idioma configurado.
- Use analogias e exemplos do cotidiano.
- Explique processos e mecanismos com clareza.
- Conecte conceitos entre si quando possível.
- Adapte o nível de detalhe ao aluno.`,

  exam: `Você é {name}, um examinador rigoroso que testa o conhecimento do aluno sobre o deck "{deck_title}".

Contexto do deck:
{deck_context}

Idioma: {language}
Nível do aluno: {level}

Regras:
- Responda no idioma configurado.
- Faça perguntas objetivas e desafiadoras.
- Após a resposta do aluno, dê feedback direto.
- Indique a resposta correta quando o aluno errar.
- Não dê a resposta antes que o aluno tente.`,

  custom: `Você é {name}, assistente do deck "{deck_title}".

Contexto do deck:
{deck_context}

Idioma: {language}
Nível do aluno: {level}

Siga as instruções acima e ajude o aluno da melhor forma possível.`,
};

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return optionsResponse();
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "Método não permitido." }, 405);
    }

    const auth = await authenticatedSupabase(req);
    if ("error" in auth) {
      return auth.error;
    }

    const body = (await req.json()) as ChatInput;
    const inputError = validateInput(body);
    if (inputError) {
      return jsonResponse({ error: inputError }, 400);
    }

    const deckId = String(body.deckId);
    const userMessage = String(body.userMessage).trim();
    const messages = (body.messages as ChatMessageInput[]) || [];

    // 1. Fetch deck with agent config
    const { data: deckData, error: deckError } = await auth.supabase
      .from("decks")
      .select(
        "title,description,agent_name,agent_prompt,agent_template,agent_language,agent_level",
      )
      .eq("id", deckId)
      .single();

    if (deckError || !deckData) {
      return jsonResponse({ error: "Deck não encontrado." }, 404);
    }

    const deck = deckData as DeckAgent;

    // 2. Fetch last 20 cards for context
    const { data: cardsData } = await auth.supabase
      .from("cards")
      .select("front,back")
      .eq("deck_id", deckId)
      .order("created_at", { ascending: false })
      .limit(20);

    const cards = (cardsData as CardSummary[] | null) ?? [];

    // 3. Resolve and interpolate prompt
    const systemPrompt = buildSystemPrompt(deck, cards);

    // 4. Build messages array for DeepSeek
    const aiMessages = [
      { role: "system", content: systemPrompt },
      ...messages
        .filter(
          (m) =>
            (m.role === "user" || m.role === "assistant") &&
            typeof m.content === "string" &&
            m.content.trim().length > 0,
        )
        .map((m) => ({ role: m.role, content: m.content })),
      { role: "user", content: userMessage },
    ];

    // 5. Call DeepSeek
    const apiKey = requireEnv("DEEPSEEK_API_KEY");
    const reply = await callDeepSeek(apiKey, aiMessages);

    return jsonResponse({ reply });
  } catch (error) {
    return errorResponse(error, "Não foi possível processar a mensagem.");
  }
});

function validateInput(input: ChatInput): string | null {
  if (!input.deckId || typeof input.deckId !== "string") {
    return "Deck inválido.";
  }

  if (
    typeof input.userMessage !== "string" ||
    input.userMessage.trim().length === 0
  ) {
    return "Mensagem obrigatória.";
  }

  if (input.userMessage.trim().length > 4000) {
    return "A mensagem deve ter no máximo 4000 caracteres.";
  }

  if (input.messages !== undefined && !Array.isArray(input.messages)) {
    return "Histórico de mensagens inválido.";
  }

  return null;
}

function buildSystemPrompt(deck: DeckAgent, cards: CardSummary[]): string {
  // Resolve base prompt
  const basePrompt =
    deck.agent_template === "custom" && deck.agent_prompt
      ? deck.agent_prompt
      : defaultPrompts[deck.agent_template] ?? defaultPrompts["general"]!;

  // Build deck context from cards
  const deckContext =
    cards.length > 0
      ? cards
          .map((c, i) => `${i + 1}. Frente: ${c.front} | Verso: ${c.back}`)
          .join("\n")
      : "Sem cards no deck ainda.";

  // Interpolate variables
  return basePrompt
    .replaceAll("{name}", deck.agent_name)
    .replaceAll("{deck_title}", deck.title)
    .replaceAll("{deck_context}", deckContext)
    .replaceAll("{language}", deck.agent_language)
    .replaceAll("{level}", deck.agent_level);
}

async function callDeepSeek(
  apiKey: string,
  messages: { role: string; content: string }[],
): Promise<string> {
  const response = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      temperature: 0.4,
      messages,
    }),
  });

  if (!response.ok) {
    throw new AiGatewayError(
      deepSeekErrorMessage(response.status),
      response.status >= 500 ? 502 : 400,
      `deepseek_${response.status}`,
    );
  }

  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    throw new AiGatewayError(
      "A IA retornou uma resposta vazia.",
      502,
      "empty_ai_response",
    );
  }

  return content.trim();
}

function deepSeekErrorMessage(status: number): string {
  switch (status) {
    case 400:
      return "A DeepSeek rejeitou o formato da requisição.";
    case 401:
      return "Chave da DeepSeek inválida ou ausente.";
    case 402:
      return "A conta da DeepSeek está sem saldo/crédito.";
    case 429:
      return "Limite de uso da DeepSeek atingido. Tente novamente em instantes.";
    default:
      return "A DeepSeek não conseguiu processar a mensagem agora.";
  }
}
