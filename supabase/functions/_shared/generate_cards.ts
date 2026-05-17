import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.4";

export type GeneratedCard = {
  front: string;
  back: string;
};

export type GenerateInput = {
  deckId: string;
  quantity: number;
};

type DeckContext = {
  title: string;
  description: string | null;
  agent_language: string;
  agent_level: string;
};

type AuthenticatedSupabaseResult =
  | { error: Response }
  | {
    supabase: ReturnType<typeof createClient<any, "public", any>>;
    user: { id: string };
  };

const allowedQuantities = [5, 10, 15];
const maxFrontLength = 300;
const maxBackLength = 600;

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function optionsResponse(): Response {
  return new Response("ok", { headers: corsHeaders });
}

export function validateGenerateInput(input: GenerateInput): string | null {
  if (!input.deckId || typeof input.deckId !== "string") {
    return "Deck inválido.";
  }

  if (!allowedQuantities.includes(input.quantity)) {
    return "Quantidade inválida.";
  }

  return null;
}

export function validateText(text: unknown): string | null {
  if (typeof text !== "string" || text.trim().length === 0) {
    return "Texto obrigatório.";
  }

  const trimmed = text.trim();
  if (trimmed.length < 100) {
    return "Informe um texto com pelo menos 100 caracteres.";
  }

  if (trimmed.length > 4000) {
    return "O texto deve ter no máximo 4000 caracteres.";
  }

  return null;
}

export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new AiGatewayError(
      `Variável de ambiente ausente: ${name}.`,
      500,
      "missing_env",
    );
  }
  return value;
}

export class AiGatewayError extends Error {
  constructor(
    message: string,
    public readonly status = 500,
    public readonly code = "ai_gateway_error",
  ) {
    super(message);
    this.name = "AiGatewayError";
  }
}

export function errorResponse(
  error: unknown,
  fallbackMessage: string,
): Response {
  if (error instanceof AiGatewayError) {
    return jsonResponse(
      { error: error.message, code: error.code },
      error.status,
    );
  }

  console.error(error);
  return jsonResponse({ error: fallbackMessage, code: "unknown_error" }, 500);
}

export async function authenticatedSupabase(
  req: Request,
): Promise<AuthenticatedSupabaseResult> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return { error: jsonResponse({ error: "Não autenticado." }, 401) };
  }

  const supabase = createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_ANON_KEY"),
    {
      global: { headers: { Authorization: authHeader } },
    },
  );

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return { error: jsonResponse({ error: "Sessão inválida." }, 401) };
  }

  return { supabase, user };
}

export async function fetchDeckContext(
  supabase: ReturnType<typeof createClient<any, "public", any>>,
  deckId: string,
): Promise<DeckContext | Response> {
  const { data, error } = await supabase
    .from("decks")
    .select("title,description,agent_language,agent_level")
    .eq("id", deckId)
    .single();

  if (error || !data) {
    return jsonResponse({ error: "Deck não encontrado." }, 404);
  }

  return data as DeckContext;
}

export async function generateCardsWithDeepSeek(params: {
  apiKey: string;
  text: string;
  quantity: number;
  deck: DeckContext;
}): Promise<GeneratedCard[]> {
  const prompt = buildPrompt(params);
  const response = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${params.apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      temperature: 0.3,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content:
            "Você gera flashcards objetivos, claros e fiéis ao material do usuário. Responda somente com JSON válido.",
        },
        { role: "user", content: prompt },
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
      "A IA retornou uma resposta vazia.",
      502,
      "empty_ai_response",
    );
  }

  return parseGeneratedCards(content, params.quantity);
}

function buildPrompt(params: {
  text: string;
  quantity: number;
  deck: DeckContext;
}): string {
  return `
Gere ${params.quantity} flashcards em ${params.deck.agent_language}, nível ${params.deck.agent_level}.

Deck: ${params.deck.title}
Descrição do deck: ${params.deck.description ?? "Sem descrição"}

Material:
${params.text}

Regras:
- Cada card deve ter uma pergunta objetiva em "front".
- Cada resposta deve ser clara e curta em "back".
- Não invente fatos fora do material.
- Evite cards duplicados.
- Responda exclusivamente em JSON válido no formato:
{
  "cards": [
    { "front": "pergunta", "back": "resposta" }
  ]
}
`;
}

function parseGeneratedCards(
  content: string,
  quantity: number,
): GeneratedCard[] {
  const cleaned = content
    .trim()
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/i, "");

  const jsonText = extractJsonObject(cleaned);
  let parsed: unknown;
  try {
    parsed = JSON.parse(jsonText);
  } catch (_) {
    throw new AiGatewayError(
      "A IA retornou uma resposta em formato inválido.",
      502,
      "invalid_ai_json",
    );
  }
  const cards = parsed && typeof parsed === "object" && "cards" in parsed
    ? parsed.cards
    : null;
  if (!Array.isArray(cards)) {
    throw new AiGatewayError(
      "A IA não retornou a lista de cards esperada.",
      502,
      "invalid_ai_cards",
    );
  }

  const normalized = cards
    .map((card) => ({
      front: String(card?.front ?? "").trim().slice(0, maxFrontLength),
      back: String(card?.back ?? "").trim().slice(0, maxBackLength),
    }))
    .filter((card) => card.front.length > 0 && card.back.length > 0)
    .slice(0, quantity);

  if (normalized.length === 0) {
    throw new AiGatewayError(
      "A IA não retornou cards válidos.",
      502,
      "empty_ai_cards",
    );
  }

  return normalized;
}

function extractJsonObject(content: string): string {
  const start = content.indexOf("{");
  const end = content.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    return content;
  }

  return content.substring(start, end + 1);
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
      return "A DeepSeek não conseguiu processar a geração agora.";
  }
}
