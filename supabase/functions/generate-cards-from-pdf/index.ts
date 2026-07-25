import pdfParse from "npm:pdf-parse@1.1.1";

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
import { withQuota } from "../_shared/quota.ts";

const maxPdfSizeBytes = 5 * 1024 * 1024;
const maxPdfPages = 10;

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

    if (typeof body.pdfPath !== "string" || body.pdfPath.trim().length === 0) {
      return jsonResponse({ error: "PDF inválido." }, 400);
    }

    if (!body.pdfPath.startsWith(`${auth.user.id}/`)) {
      return jsonResponse({ error: "PDF não pertence ao usuário." }, 403);
    }

    const deck = await fetchDeckContext(auth.supabase, body.deckId);
    if (deck instanceof Response) {
      return deck;
    }

    const { data, error } = await auth.supabase.storage
      .from("pdfs")
      .download(body.pdfPath);

    if (error || !data) {
      return jsonResponse({ error: "PDF não encontrado." }, 404);
    }

    const bytes = new Uint8Array(await data.arrayBuffer());
    if (bytes.length > maxPdfSizeBytes) {
      return jsonResponse({ error: "O PDF deve ter no máximo 5 MB." }, 400);
    }

    const parsed = await pdfParse(bytes);
    if (parsed.numpages > maxPdfPages) {
      return jsonResponse(
        { error: "O PDF deve ter no máximo 10 páginas." },
        400,
      );
    }

    const text = parsed.text.trim();
    const textError = validateText(text);
    if (textError) {
      return jsonResponse(
        { error: "Não foi possível extrair texto suficiente deste PDF." },
        400,
      );
    }

    const cards = await withQuota(auth.user.id, "generate_pdf", () =>
      generateCardsWithDeepSeek({
        apiKey: requireEnv("DEEPSEEK_API_KEY"),
        text,
        quantity: body.quantity,
        deck,
      }));

    return jsonResponse({ cards });
  } catch (error) {
    return errorResponse(
      error,
      "Não foi possível gerar cards a partir do PDF.",
    );
  }
});
