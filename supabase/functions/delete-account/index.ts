import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.4";

import {
  authenticatedSupabase,
  errorResponse,
  jsonResponse,
  optionsResponse,
  requireEnv,
} from "../_shared/generate_cards.ts";

/// Exclusão de conta iniciada pelo usuário.
///
/// Exigida pela App Store (guideline 5.1.1(v)): app que cria conta precisa
/// permitir excluí-la de dentro do app. Também é a resposta ao direito de
/// eliminação da LGPD (art. 18, VI).
///
/// `on delete cascade` das FKs cuida de decks, cards, chat_messages, reviews e
/// ai_usage. O que o banco não alcança é o bucket de PDFs, removido aqui.
Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return optionsResponse();
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "Método não permitido." }, 405);
    }

    // Valida o JWT com a chave anon antes de escalar para service role.
    const auth = await authenticatedSupabase(req);
    if ("error" in auth) {
      return auth.error;
    }

    const userId = auth.user.id;

    const admin = createClient(
      requireEnv("SUPABASE_URL"),
      requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );

    await removeStoredPdfs(admin, userId);

    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) {
      console.error("deleteUser failed", error);
      return jsonResponse(
        { error: "Não foi possível excluir a conta agora.", code: "delete_failed" },
        500,
      );
    }

    return jsonResponse({ deleted: true });
  } catch (error) {
    return errorResponse(error, "Não foi possível excluir a conta agora.");
  }
});

/// Remove `pdfs/{userId}/`. Falha aqui não bloqueia a exclusão da conta: é
/// melhor deixar um arquivo órfão do que recusar apagar os dados do usuário.
async function removeStoredPdfs(
  admin: ReturnType<typeof createClient<any, "public", any>>,
  userId: string,
): Promise<void> {
  try {
    const { data, error } = await admin.storage.from("pdfs").list(userId, {
      limit: 1000,
    });

    if (error) {
      console.error("list pdfs failed", error);
      return;
    }

    const paths = (data ?? []).map((file) => `${userId}/${file.name}`);
    if (paths.length === 0) {
      return;
    }

    const { error: removeError } = await admin.storage
      .from("pdfs")
      .remove(paths);

    if (removeError) {
      console.error("remove pdfs failed", removeError);
    }
  } catch (error) {
    console.error("removeStoredPdfs threw", error);
  }
}
