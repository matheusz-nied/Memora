import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  maxBatchQuantity,
  maxChunkChars,
  maxTextChars,
  minTextChars,
  sanitizeAvoidFronts,
  validateGenerateInput,
  validateText,
} from "./generate_cards.ts";

const validInput = { deckId: "deck-1", quantity: 10 };

Deno.test("validateGenerateInput accepts a batch within the limit", () => {
  assertEquals(validateGenerateInput(validInput), null);
  assertEquals(
    validateGenerateInput({ ...validInput, quantity: maxBatchQuantity }),
    null,
  );
});

Deno.test("validateGenerateInput rejects a batch over the limit", () => {
  assertEquals(
    validateGenerateInput({ ...validInput, quantity: maxBatchQuantity + 1 }),
    "Quantidade inválida.",
  );
  assertEquals(
    validateGenerateInput({ ...validInput, quantity: 0 }),
    "Quantidade inválida.",
  );
  assertEquals(
    validateGenerateInput({ ...validInput, quantity: 7.5 }),
    "Quantidade inválida.",
  );
});

Deno.test("validateGenerateInput accepts any quantity the app offers", () => {
  // O app quebra 25 e 50 em lotes, então o servidor só vê valores até o teto.
  for (const quantity of [5, 10, 13, 12, 15]) {
    assertEquals(validateGenerateInput({ ...validInput, quantity }), null);
  }
});

Deno.test("validateGenerateInput checks the source", () => {
  assertEquals(validateGenerateInput({ ...validInput, source: "pdf" }), null);
  assertEquals(validateGenerateInput({ ...validInput, source: "text" }), null);
  assertEquals(
    validateGenerateInput({
      ...validInput,
      source: "audio" as unknown as "pdf",
    }),
    "Origem inválida.",
  );
});

Deno.test("validateText accepts the new minimum of 50 characters", () => {
  assertEquals(validateText("a".repeat(minTextChars), maxTextChars), null);
  assertEquals(
    validateText("a".repeat(minTextChars - 1), maxTextChars),
    `Informe um texto com pelo menos ${minTextChars} caracteres.`,
  );
});

Deno.test("validateText lets a pdf chunk be longer than typed text", () => {
  const chunk = "a".repeat(maxTextChars + 500);

  assertEquals(validateText(chunk, maxChunkChars), null);
  assertEquals(
    validateText(chunk, maxTextChars),
    `O texto deve ter no máximo ${maxTextChars} caracteres.`,
  );
});

Deno.test("validateText rejects empty input", () => {
  assertEquals(validateText("   ", maxTextChars), "Texto obrigatório.");
  assertEquals(validateText(null, maxTextChars), "Texto obrigatório.");
});

Deno.test("sanitizeAvoidFronts keeps the most recent fronts", () => {
  const fronts = Array.from({ length: 80 }, (_, index) => `Front ${index}`);

  const sanitized = sanitizeAvoidFronts(fronts);

  assertEquals(sanitized.length, 60);
  assertEquals(sanitized.at(-1), "Front 79");
});

Deno.test("sanitizeAvoidFronts drops junk instead of failing", () => {
  assertEquals(sanitizeAvoidFronts(["  ok  ", "", 42, null]), ["ok"]);
  assertEquals(sanitizeAvoidFronts("nada disso"), []);
  assertEquals(sanitizeAvoidFronts(undefined), []);
});

Deno.test("sanitizeAvoidFronts truncates a long front", () => {
  const sanitized = sanitizeAvoidFronts(["a".repeat(500)]);

  assertEquals(sanitized.length, 1);
  assertEquals(sanitized[0].length, 300);
});
