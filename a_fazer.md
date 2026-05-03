# A Fazer

## Supabase Auth Redirect

- [ ] Configurar no Supabase Dashboard em `Authentication -> URL Configuration -> Redirect URLs`:
  - `com.example.memora://auth-callback`
- [ ] Quando a URL/scheme definitivo do app mudar, atualizar em conjunto:
  - Supabase Dashboard `Redirect URLs`
  - `BackendConstants.kAuthRedirectUrl`
  - Android `AndroidManifest.xml`
  - iOS `Info.plist`

Observação: o link de confirmação de e-mail só funciona corretamente para links novos gerados depois dessa configuração.
