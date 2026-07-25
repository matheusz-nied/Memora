# A Fazer

> Ver `PLANO_LANCAMENTO.md` para o plano completo até o lançamento.

## Supabase Auth Redirect

- [ ] Configurar no Supabase Dashboard em `Authentication -> URL Configuration -> Redirect URLs`:
  - `com.example.memora://auth-callback`
- [ ] Quando a URL/scheme definitivo do app mudar, atualizar em conjunto:
  - Supabase Dashboard `Redirect URLs`
  - `BackendConstants.kAuthRedirectUrl`
  - Android `AndroidManifest.xml`
  - iOS `Info.plist`

Observação: o link de confirmação de e-mail só funciona corretamente para links novos gerados depois dessa configuração.

## Deploy da Fase 2 (quotas de IA)

- [ ] Aplicar as migrations `20260725000000_ai_usage_quota.sql` e
      `20260725000100_reviews_and_repetitions.sql`
- [ ] Deploy das Edge Functions, incluindo a nova `delete-account`
- [ ] Confirmar `SUPABASE_SERVICE_ROLE_KEY` disponível nas functions
      (o Supabase injeta automaticamente, mas vale verificar)
- [ ] Definir `ALLOWED_ORIGIN` com o domínio do app web
- [ ] Configurar alerta de gasto no painel da DeepSeek
