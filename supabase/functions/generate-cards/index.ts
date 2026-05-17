import {
  authenticatedSupabase,
  errorResponse,
  fetchDeckContext,
  generateCardsWithDeepSeek,
  jsonResponse,
  optionsResponse,
  requireEnv,
  validateGenerateInput,
  validateText,
} from "../_shared/generate_cards.ts";

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

    const body = await req.json();
    const inputError = validateGenerateInput(body);
    if (inputError) {
      return jsonResponse({ error: inputError }, 400);
    }

    const textError = validateText(body.text);
    if (textError) {
      return jsonResponse({ error: textError }, 400);
    }

    const deck = await fetchDeckContext(auth.supabase, body.deckId);
    if (deck instanceof Response) {
      return deck;
    }

    const cards = await generateCardsWithDeepSeek({
      apiKey: requireEnv("DEEPSEEK_API_KEY"),
      text: String(body.text).trim(),
      quantity: body.quantity,
      deck,
    });

    return jsonResponse({ cards });
  } catch (error) {
    return errorResponse(error, "Não foi possível gerar os cards.");
  }
});
