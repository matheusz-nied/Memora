import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.4";

import { getEnv } from "./runtime.ts";

export type GeneratedCard = {
  front: string;
  back: string;
};

export type GenerateSource = "text" | "pdf";

export type GenerateInput = {
  deckId: string;
  quantity: number;
  source?: GenerateSource;
  avoidFronts?: unknown;
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

/// Cards por chamada à IA. O cliente quebra pedidos maiores em vários lotes:
/// pedir 50 de uma vez estoura `maxTokens.generateCards` e derruba a qualidade.
export const maxBatchQuantity = 15;

/// Mínimo de material para valer uma geração.
export const minTextChars = 50;

/// Teto do texto colado pelo usuário na tela.
export const maxTextChars = 4000;

/// Teto de uma fatia de PDF. Maior que [maxTextChars] porque o cliente fatia
/// em ~3500 caracteres e a folga absorve variação de quebra de parágrafo.
export const maxChunkChars = 6000;

/// Frentes já geradas aceitas no prompt anti-duplicação.
const maxAvoidFronts = 60;

const maxFrontLength = 300;
const maxBackLength = 600;
const deepSeekTimeoutMs = 60_000;
const deepSeekRetryDelayMs = 1000;

/// Origem permitida no CORS. Defina ALLOWED_ORIGIN com o domínio do app web
/// em produção; `*` só é aceitável em desenvolvimento.
export const corsHeaders = {
  "Access-Control-Allow-Origin": getEnv("ALLOWED_ORIGIN") ?? "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};

/// Teto de tokens por operação. Sem isto a resposta da DeepSeek é ilimitada e
/// o custo de uma única chamada não tem teto.
export const maxTokens = {
  generateCards: 4000,
  chat: 1500,
  insight: 1200,
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

  if (
    !Number.isInteger(input.quantity) ||
    input.quantity < 1 ||
    input.quantity > maxBatchQuantity
  ) {
    return "Quantidade inválida.";
  }

  if (
    input.source !== undefined &&
    input.source !== "text" &&
    input.source !== "pdf"
  ) {
    return "Origem inválida.";
  }

  if (input.avoidFronts !== undefined && !Array.isArray(input.avoidFronts)) {
    return "Lista de cards existentes inválida.";
  }

  return null;
}

/// Normaliza a lista anti-duplicação: entrada do cliente, então trunca em vez
/// de rejeitar — um prompt grande demais é problema nosso, não erro do usuário.
export function sanitizeAvoidFronts(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim().slice(0, maxFrontLength))
    .filter((item) => item.length > 0)
    .slice(-maxAvoidFronts);
}

export function validateText(text: unknown, maxChars: number): string | null {
  if (typeof text !== "string" || text.trim().length === 0) {
    return "Texto obrigatório.";
  }

  const trimmed = text.trim();
  if (trimmed.length < minTextChars) {
    return `Informe um texto com pelo menos ${minTextChars} caracteres.`;
  }

  if (trimmed.length > maxChars) {
    return `O texto deve ter no máximo ${maxChars} caracteres.`;
  }

  return null;
}

export function requireEnv(name: string): string {
  const value = getEnv(name);
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

export type GenerateCardsParams = {
  apiKey: string;
  text: string;
  quantity: number;
  deck: DeckContext;
  /// Frentes já geradas em lotes anteriores do mesmo pedido.
  avoidFronts?: string[];
  /// O material é uma fatia de um documento maior, não o conteúdo completo.
  isChunk?: boolean;
};

export async function generateCardsWithDeepSeek(
  params: GenerateCardsParams,
): Promise<GeneratedCard[]> {
  try {
    return await callDeepSeekOnce(params);
  } catch (error) {
    if (!isRetryable(error)) {
      throw error;
    }
    await delay(deepSeekRetryDelayMs);
    return callDeepSeekOnce(params);
  }
}

/// Só vale repetir o que tem chance de ser transitório: falha de rede, erro
/// 5xx da DeepSeek e resposta que não deu para interpretar (todos mapeados
/// para 502). Repetir 401/402/429 queima tempo de execução para receber o
/// mesmo erro, e repetir um timeout dobraria a espera de quem já esperou 60s.
function isRetryable(error: unknown): boolean {
  if (!(error instanceof AiGatewayError)) {
    return true;
  }

  return error.status >= 500 && error.code !== "deepseek_timeout";
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function callDeepSeekOnce(
  params: GenerateCardsParams,
): Promise<GeneratedCard[]> {
  const prompt = buildPrompt(params);
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), deepSeekTimeoutMs);

  let response: Response;
  try {
    response = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Authorization": `Bearer ${params.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        temperature: 0.3,
        max_tokens: maxTokens.generateCards,
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
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new AiGatewayError(
        "A IA demorou demais para responder. Tente novamente.",
        504,
        "deepseek_timeout",
      );
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }

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

function buildPrompt(params: GenerateCardsParams): string {
  const avoidFronts = params.avoidFronts ?? [];
  const materialLabel = params.isChunk
    ? "Trecho do material (parte de um documento maior)"
    : "Material";

  const chunkRule = params.isChunk
    ? "\n- O material é apenas um trecho do documento. Crie cards somente sobre o que está neste trecho."
    : "";

  const avoidBlock = avoidFronts.length === 0 ? "" : `
Perguntas que JÁ foram geradas para este deck. NÃO repita nenhuma delas, nem variações com as mesmas palavras ou a mesma resposta. Cubra aspectos ainda não abordados:
${avoidFronts.map((front) => `- ${front}`).join("\n")}
`;

  return `
Gere ${params.quantity} flashcards em ${params.deck.agent_language}, nível ${params.deck.agent_level}.

Deck: ${params.deck.title}
Descrição do deck: ${params.deck.description ?? "Sem descrição"}

${materialLabel}:
${params.text}
${avoidBlock}
Regras:
- Cada card deve ter uma pergunta objetiva em "front".
- Cada resposta deve ser clara e curta em "back".
- Não invente fatos fora do material.
- Evite cards duplicados.${chunkRule}
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
