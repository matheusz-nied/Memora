import {
  authenticatedSupabase,
  errorResponse,
  fetchDeckContext,
  generateCardsWithDeepSeek,
  jsonResponse,
  maxChunkChars,
  maxTextChars,
  optionsResponse,
  requireEnv,
  sanitizeAvoidFronts,
  validateGenerateInput,
  validateText,
} from "../_shared/generate_cards.ts";
import { withQuota } from "../_shared/quota.ts";
import { serve } from "../_shared/runtime.ts";

serve(async (req) => {
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

    const body = await req.json();
    const inputError = validateGenerateInput(body);
    if (inputError) {
      return jsonResponse({ error: inputError }, 400);
    }

    // Uma fatia de PDF pode ser maior que o texto que cabe na tela, e custa
    // mais crédito porque veio de um documento que já consumiu extração.
    const fromPdf = body.source === "pdf";
    const textError = validateText(
      body.text,
      fromPdf ? maxChunkChars : maxTextChars,
    );
    if (textError) {
      return jsonResponse({ error: textError }, 400);
    }

    const deck = await fetchDeckContext(auth.supabase, body.deckId);
    if (deck instanceof Response) {
      return deck;
    }

    const operation = fromPdf ? "generate_pdf" : "generate_cards";
    const cards = await withQuota(
      auth.user.id,
      operation,
      () =>
        generateCardsWithDeepSeek({
          apiKey: requireEnv("DEEPSEEK_API_KEY"),
          text: String(body.text).trim(),
          quantity: body.quantity,
          deck,
          avoidFronts: sanitizeAvoidFronts(body.avoidFronts),
          isChunk: fromPdf,
        }),
    );

    return jsonResponse({ cards });
  } catch (error) {
    return errorResponse(error, "Não foi possível gerar os cards.");
  }
});
