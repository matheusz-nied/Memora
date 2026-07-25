/// Única superfície das Edge Functions que conhece o runtime.
///
/// Todo o resto — validação, prompts, quota, chamadas à IA — é TypeScript
/// comum sobre `Request`/`Response`, que são padrão da plataforma web. Portar
/// as functions para Node, Bun ou Cloudflare Workers significa reescrever
/// este arquivo e nada mais.
///
/// Mantenha assim: `Deno.*` não deve aparecer em nenhum outro arquivo.
/// `test/architecture` do lado Flutter e a CI cobram essa fronteira.

export type RequestHandler = (request: Request) => Promise<Response>;

export function getEnv(name: string): string | undefined {
  return Deno.env.get(name);
}

export function serve(handler: RequestHandler): void {
  Deno.serve(handler);
}
