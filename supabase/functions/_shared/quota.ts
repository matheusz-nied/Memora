import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.4";

import { AiGatewayError, requireEnv } from "./generate_cards.ts";

export type AiOperation =
  | "generate_cards"
  | "generate_pdf"
  | "chat"
  | "insight";

/// Unidades de custo por operação, relativas ao gasto real de tokens.
/// O teto mensal por tier vive no Postgres (`ai_quota_limit`).
export const operationCost: Record<AiOperation, number> = {
  chat: 1,
  insight: 1,
  generate_cards: 2,
  generate_pdf: 3,
};

export type QuotaReservation = {
  usageId: string;
  used: number;
  quota: number;
};

type ConsumeRow = {
  usage_id: string | null;
  allowed: boolean;
  reason: string | null;
  used: number;
  quota: number;
};

let cachedAdmin: ReturnType<typeof createClient<any, "public", any>> | null =
  null;

/// As funções de quota são `security definer` e só o service_role pode
/// executá-las: se o cliente pudesse chamar `refund_ai_quota`, bastaria
/// consumir, usar a IA e estornar em seguida.
function adminClient() {
  cachedAdmin ??= createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  return cachedAdmin;
}

/// Reserva o custo da operação antes de chamar a IA. Lança 429 se o usuário
/// estourou o teto mensal ou está disparando rápido demais.
export async function reserveQuota(
  userId: string,
  operation: AiOperation,
): Promise<QuotaReservation> {
  const { data, error } = await adminClient().rpc("consume_ai_quota", {
    p_user_id: userId,
    p_operation: operation,
    p_cost_units: operationCost[operation],
  });

  if (error) {
    console.error("consume_ai_quota failed", error);
    throw new AiGatewayError(
      "Não foi possível validar seu limite de uso agora.",
      500,
      "quota_check_failed",
    );
  }

  const row = (Array.isArray(data) ? data[0] : data) as ConsumeRow | undefined;
  if (!row) {
    throw new AiGatewayError(
      "Não foi possível validar seu limite de uso agora.",
      500,
      "quota_check_failed",
    );
  }

  if (!row.allowed) {
    if (row.reason === "rate_limited") {
      throw new AiGatewayError(
        "Muitas requisições seguidas. Aguarde alguns segundos e tente de novo.",
        429,
        "rate_limited",
      );
    }

    throw new AiGatewayError(
      `Você já usou ${row.used} de ${row.quota} créditos de IA deste mês.`,
      429,
      "quota_exceeded",
    );
  }

  return {
    usageId: row.usage_id!,
    used: row.used,
    quota: row.quota,
  };
}

/// Estorna a reserva quando a IA falha: o usuário não paga por erro do provedor.
export async function refundQuota(
  userId: string,
  reservation: QuotaReservation,
): Promise<void> {
  try {
    const { error } = await adminClient().rpc("refund_ai_quota", {
      p_usage_id: reservation.usageId,
      p_user_id: userId,
    });
    if (error) {
      console.error("refund_ai_quota failed", error);
    }
  } catch (error) {
    // Nunca mascarar o erro original da IA por causa de uma falha no estorno.
    console.error("refund_ai_quota threw", error);
  }
}

/// Reserva, executa e estorna em caso de falha.
///
/// Chame o mais tarde possível — depois de validar a entrada e carregar o deck —
/// para não reservar crédito de requisição que ia falhar de qualquer forma.
export async function withQuota<T>(
  userId: string,
  operation: AiOperation,
  run: () => Promise<T>,
): Promise<T> {
  const reservation = await reserveQuota(userId, operation);

  try {
    return await run();
  } catch (error) {
    await refundQuota(userId, reservation);
    throw error;
  }
}
