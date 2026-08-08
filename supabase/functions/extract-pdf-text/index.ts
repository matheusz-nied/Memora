import pdfParse from "npm:pdf-parse@1.1.1";

import {
  authenticatedSupabase,
  errorResponse,
  jsonResponse,
  minTextChars,
  optionsResponse,
} from "../_shared/generate_cards.ts";
import { refundQuota, reserveQuota } from "../_shared/quota.ts";
import { serve } from "../_shared/runtime.ts";

const maxPdfSizeBytes = 20 * 1024 * 1024;
const maxPdfPages = 100;

/// Teto do que volta para o app. Um PDF de 100 páginas rende ~250 mil
/// caracteres; acima disso o payload pesa mais do que rende em cards, então
/// truncamos — nunca rejeitamos por excesso de texto.
const maxReturnedChars = 500_000;

/// Extrai o texto de um PDF já enviado ao bucket e devolve ao app, que fatia o
/// material e gera os cards em lotes pela function `generate-cards`.
///
/// Separado da geração de propósito: `pdf-parse` é trabalho de CPU e a chamada
/// à IA é espera de rede. Juntos numa invocação só, um PDF grande estourava o
/// limite de execução da Edge Function. Aqui o PDF é lido uma vez e o custo
/// não se repete a cada lote.
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
    if (typeof body.pdfPath !== "string" || body.pdfPath.trim().length === 0) {
      return jsonResponse({ error: "PDF inválido." }, 400);
    }

    if (!body.pdfPath.startsWith(`${auth.user.id}/`)) {
      return jsonResponse({ error: "PDF não pertence ao usuário." }, 403);
    }

    const { data, error } = await auth.supabase.storage
      .from("pdfs")
      .download(body.pdfPath);

    if (error || !data) {
      return jsonResponse(
        { error: "PDF não encontrado.", code: "pdf_not_found" },
        404,
      );
    }

    const bytes = new Uint8Array(await data.arrayBuffer());

    // O arquivo já está em memória: a partir daqui ele não serve para mais
    // nada no bucket, e deixá-lo lá acumula storage pago por PDF que o usuário
    // enviou uma vez.
    try {
      return await meteredExtraction(auth.user.id, bytes);
    } finally {
      await removeStoredPdf(auth.supabase, body.pdfPath);
    }
  } catch (error) {
    return errorResponse(error, "Não foi possível ler este PDF.");
  }
});

/// Cobra a extração antes de rodar o `pdf-parse`.
///
/// Sem isto o trecho caro do fluxo de PDF sai de graça: a geração em lotes é
/// cobrada pela function `generate-cards`, mas nada impediria reenviar o mesmo
/// arquivo de 100 páginas indefinidamente só para queimar CPU.
///
/// O estorno cobre também a resposta de erro — `extractResponse` devolve 4xx em
/// vez de lançar, e PDF escaneado ou corrompido não é uso, é tentativa.
async function meteredExtraction(
  userId: string,
  bytes: Uint8Array,
): Promise<Response> {
  const reservation = await reserveQuota(userId, "generate_pdf");

  let response: Response;
  try {
    response = await extractResponse(bytes);
  } catch (error) {
    await refundQuota(userId, reservation);
    throw error;
  }

  if (!response.ok) {
    await refundQuota(userId, reservation);
  }
  return response;
}

async function extractResponse(bytes: Uint8Array): Promise<Response> {
  if (bytes.length > maxPdfSizeBytes) {
    return jsonResponse(
      {
        error: `O PDF deve ter no máximo ${maxPdfSizeBytes / 1024 / 1024} MB.`,
        code: "pdf_too_large",
      },
      400,
    );
  }

  let parsed: { text: string; numpages: number };
  try {
    parsed = await pdfParse(bytes);
  } catch (error) {
    console.error("pdf-parse failed", error);
    return jsonResponse(
      {
        error:
          "Não foi possível ler este PDF. Verifique se o arquivo não está corrompido ou protegido por senha.",
        code: "pdf_parse_failed",
      },
      422,
    );
  }

  if (parsed.numpages > maxPdfPages) {
    return jsonResponse(
      {
        error: `O PDF deve ter no máximo ${maxPdfPages} páginas.`,
        code: "pdf_too_many_pages",
      },
      400,
    );
  }

  const text = parsed.text.trim();

  // `pdf-parse` não faz OCR: PDF escaneado devolve string vazia. A mensagem
  // precisa dizer isso, porque "texto insuficiente" leva o usuário a procurar
  // um arquivo maior — que também não vai funcionar.
  if (text.length < minTextChars) {
    return jsonResponse(
      {
        error:
          "Este PDF parece ser escaneado ou não tem texto selecionável. Envie outro arquivo ou cole o conteúdo como texto.",
        code: "pdf_no_text",
      },
      422,
    );
  }

  return jsonResponse({
    text: text.slice(0, maxReturnedChars),
    pages: parsed.numpages,
  });
}

/// Só o que a limpeza precisa do client, para este arquivo não depender do
/// tipo completo do SDK.
type PdfBucket = {
  storage: {
    from: (bucket: string) => {
      remove: (paths: string[]) => Promise<{ error: unknown }>;
    };
  };
};

async function removeStoredPdf(
  supabase: PdfBucket,
  path: string,
): Promise<void> {
  try {
    const { error } = await supabase.storage.from("pdfs").remove([path]);
    if (error) {
      console.error("pdf cleanup failed", error);
    }
  } catch (error) {
    // Limpeza é higiene, não parte do resultado: nunca mascarar a resposta.
    console.error("pdf cleanup threw", error);
  }
}
