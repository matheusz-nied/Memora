import {
  AiGatewayError,
  authenticatedSupabase,
  errorResponse,
  fetchDeckContext,
  jsonResponse,
  optionsResponse,
  requireEnv,
} from "../_shared/generate_cards.ts";

type CardInsightInput = {
  deckId?: unknown;
  front?: unknown;
  back?: unknown;
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

    const body = await req.json() as CardInsightInput;
    const inputError = validateInput(body);
    if (inputError) {
      return jsonResponse({ error: inputError }, 400);
    }

    const deck = await fetchDeckContext(auth.supabase, String(body.deckId));
    if (deck instanceof Response) {
      return deck;
    }

    const insight = await generateInsightWithDeepSeek({
      apiKey: requireEnv("DEEPSEEK_API_KEY"),
      front: String(body.front).trim(),
      back: String(body.back).trim(),
      deck,
    });

    return jsonResponse({ insight });
  } catch (error) {
    return errorResponse(error, "Não foi possível gerar o insight.");
  }
});

function validateInput(input: CardInsightInput): string | null {
  if (!input.deckId || typeof input.deckId !== "string") {
    return "Deck inválido.";
  }

  if (typeof input.front !== "string" || input.front.trim().length === 0) {
    return "Frente do card obrigatória.";
  }

  if (typeof input.back !== "string" || input.back.trim().length === 0) {
    return "Verso do card obrigatório.";
  }

  if (input.front.trim().length > 300) {
    return "A frente do card deve ter no máximo 300 caracteres.";
  }

  if (input.back.trim().length > 600) {
    return "O verso do card deve ter no máximo 600 caracteres.";
  }

  return null;
}

async function generateInsightWithDeepSeek(params: {
  apiKey: string;
  front: string;
  back: string;
  deck: {
    title: string;
    description: string | null;
    agent_language: string;
    agent_level: string;
  };
}): Promise<string> {
  const response = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${params.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      temperature: 0.35,
      messages: [
        {
          role: "system",
          content:
            "Você é um tutor que explica flashcards com clareza, exemplos e dicas de memorização. Responda somente com o insight em texto simples.",
        },
        { role: "user", content: buildPrompt(params) },
      ],
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
      "A IA retornou um insight vazio.",
      502,
      "empty_ai_response",
    );
  }

  return content.trim();
}

function buildPrompt(params: {
  front: string;
  back: string;
  deck: {
    title: string;
    description: string | null;
    agent_language: string;
    agent_level: string;
  };
}): string {
  return `
Explique de forma aprofundada o seguinte flashcard, trazendo exemplos, contexto, dicas de memorização e conexões com outros conceitos.

Idioma: ${params.deck.agent_language}
Nível: ${params.deck.agent_level}
Deck: ${params.deck.title}
Descrição do deck: ${params.deck.description ?? "Sem descrição"}

Frente: ${params.front}
Verso: ${params.back}

Regras:
- Seja claro e útil para revisão.
- Não invente fatos que contradigam o card.
- Não use JSON.
- Não inclua markdown pesado; texto simples é suficiente.
`;
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
      return "A DeepSeek não conseguiu gerar o insight agora.";
  }
}
