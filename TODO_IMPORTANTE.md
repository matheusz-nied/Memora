# TODO Importante — Memora

> Só o que exige **ação sua**. O código das fases 0, 2 e 3 já está feito e
> testado (ver `PLANO_LANCAMENTO.md` para a análise e o estado de cada fase).
>
> Ordenado por urgência real, não por ordem do plano.

---

## 🔴 Nunca perca — sem desfazer

Três coisas que, se perdidas, não têm recuperação. Guarde tudo fora da máquina
de desenvolvimento e fora do GitHub.

- [ ] **Chave privada `age` do backup** (`memora-backup.key`)
      Perder = todos os backups viram lixo ilegível.
      Vazar = todos os backups viram dado pessoal exposto.
      → cofre de senhas ou armazenamento offline.

- [ ] **Keystore de assinatura do Android** (`.jks` + senhas)
      Perder = **nunca mais** conseguir atualizar o app na Play Store. A conta
      publicada fica órfã e você precisa lançar um app novo, do zero, sem os
      usuários. Faça backup no dia em que gerar.

- [ ] **Bundle ID definitivo** — decisão, não arquivo
      Hoje é `com.example.memora`, rejeitado nas duas lojas. Depois de
      publicado é impossível mudar. Ex.: `app.memora.mobile`.
      Ao decidir, altere nos 8 pontos:
      1. `android/app/build.gradle.kts` — `namespace` e `applicationId`
      2. mover `android/app/src/main/kotlin/com/example/memora/` + `package` do `MainActivity.kt`
      3. `AndroidManifest.xml` — `<data android:scheme="...">` do intent-filter
      4. iOS: `PRODUCT_BUNDLE_IDENTIFIER` nos 3 targets do `project.pbxproj`
      5. `ios/Runner/Info.plist` — `CFBundleURLSchemes`
      6. `lib/core/constants/backend_constants.dart` — `kAuthRedirectUrl`
      7. Supabase → Authentication → URL Configuration → **adicionar** o novo
         Redirect URL (mantenha o antigo por alguns dias: e-mails já enviados
         apontam para o scheme velho)
      8. testar ponta a ponta em device físico: cadastro → e-mail → deep link

- [ ] **Enquanto o bundle ID atual valer**, o Redirect URL precisa estar
      cadastrado no Supabase Dashboard (Authentication → URL Configuration):
      `com.example.memora://auth-callback`
      O link de confirmação de e-mail só funciona para links **gerados depois**
      dessa configuração — os já enviados continuam quebrados.

---

## 🟠 Antes de qualquer usuário real

### Deploy — nada do que foi construído está no ar

**A quota de IA não protege nada até isto acontecer.** Hoje sua conta da
DeepSeek continua tão exposta quanto antes.

- [ ] `supabase db push` — 2 migrations novas (`ai_usage_quota`, `reviews_and_repetitions`)
- [ ] `supabase functions deploy` — inclui a nova `delete-account`
- [ ] Conferir que `SUPABASE_SERVICE_ROLE_KEY` chega nas functions
      (o Supabase injeta sozinho, mas sem ela o `withQuota` quebra nas 4)
- [ ] Definir `ALLOWED_ORIGIN` com o domínio do app web
- [ ] Alerta de gasto no painel da DeepSeek

### SMTP — bloqueia o beta, não só o lançamento

- [ ] **Plugar um SMTP próprio** (Resend, Postmark, SendGrid)
      O servidor de e-mail embutido do Supabase é limitado a poucos e-mails
      por hora e é marcado como "só desenvolvimento". Seu cadastro depende de
      confirmação por e-mail + deep link — com 20 pessoas no beta, a maioria
      simplesmente não recebe nada.

### Backup

- [ ] `age-keygen -o memora-backup.key` (ver 🔴 acima)
- [ ] Secrets no GitHub: `BACKUP_DATABASE_URL` (conexão **direta**, porta
      5432, não o pooler) e `BACKUP_AGE_PUBLIC_KEY`
- [ ] Rodar Actions → backup → Run workflow uma vez, à mão
- [ ] Opcional: bucket S3-compatível (R2/B2) em vez do artifact do GitHub

Runbook completo: `tool/backup/README.md`.

---

## 🟡 Não verificado — rode antes de confiar

Coisas que escrevi mas **não consegui testar** neste ambiente. Cada uma pode
esconder um erro.

- [ ] **`deno check supabase/functions/*/index.ts`**
      A rede do ambiente bloqueava o download do Deno, então as 5 Edge
      Functions nunca foram type-checked. O job `edge-functions` na CI está
      como `continue-on-error` por isso — rode local, limpe `deno fmt`/`lint`,
      e então remova o `continue-on-error` para torná-lo bloqueante.

- [ ] **Migrations num Supabase real**
      Foram validadas contra um Postgres 16 local com scaffolding equivalente
      (aplicam limpo, e a lógica de quota foi exercitada: teto mensal exato,
      rate limit sem cobrar o barrado, estorno cruzado recusado). Mas nunca
      rodaram contra o Supabase de verdade.

- [ ] **Teste em device físico** — Android e iOS. Nada foi testado em device.

- [ ] **PDF grande no limite** (100 páginas / 20 MB)
      Edge Functions têm teto de **CPU**, mais apertado que o de tempo. A
      extração saiu da geração: `extract-pdf-text` só roda `pdf-parse` e a
      chamada à DeepSeek acontece em outra invocação, uma por lote. Falta
      medir um PDF real no limite novo — se o `pdf-parse` estourar sozinho,
      o plano B é baixar as constantes para 10 MB / 50 páginas
      (`app_constants.dart` e `extract-pdf-text/index.ts`).

---

## 🟡 Bloqueadores de loja

- [ ] **Política de privacidade + termos**, em URL pública e estável.
      Precisa dizer explicitamente que o conteúdo do usuário é processado pela
      **DeepSeek**, com servidores fora do Brasil (LGPD/GDPR).
- [ ] Links no onboarding e no perfil; aceite registrado no cadastro
- [ ] Play Data Safety + Apple Privacy Nutrition Labels
- [ ] **Conta de teste para os revisores** — a Apple reprova app com login sem
      isso. Custa 5 minutos e derruba uma submissão inteira.
- [ ] **Disclaimer de conteúdo gerado por IA + mecanismo de report**
      Causa comum de rejeição em app generativo. Não estava no plano original.
- [ ] Ícone 1024×1024 (adaptive no Android), splash light/dark
- [ ] Screenshots: 6.7"/6.5"/5.5" iOS, phone + tablet Android
- [ ] `README.md` — ainda é o template do Flutter

---

## 🔵 Decisões pendentes

- [ ] **Login social: remover ou implementar.**
      `SocialAuthButtons` renderiza Google e Apple sem handler nenhum.
      Recomendação: **remover no v1** — implementar Google obriga Sign in with
      Apple junto, que exige conta paga e configuração de Services ID.

- [ ] **Fallback de IA: implementar ou tirar da doc.**
      O `AGENTS.md` promete "fallback: Gemini 1.5 Flash" e **não existe
      implementação**. Se a DeepSeek cair ou ficar sem saldo, o app perde
      geração, chat e insight de uma vez.

- [ ] **Monetização** (RevenueCat). A IA custa por uso; sem plano pago,
      crescimento = prejuízo. Atenção ao vão: o beta fechado vem **antes** do
      paywall, então quem estourar 30 créditos fica travado sem saída. Suba a
      quota durante o beta ou coloque um "fale com a gente" na tela de limite.

- [ ] **Plano Supabase.** O free não tem backup nenhum e pausa o projeto após
      7 dias de inatividade. Lembrando: sua conta da DeepSeek provavelmente vai
      custar mais que os ~$25 do Pro.

---

## 🟢 Recorrente

- [ ] **Drill de restauração, mensal.** Baixe o backup mais recente e restaure
      num banco descartável. Cinco minutos. É a única coisa que prova que a
      corrente inteira funciona — dump legível, cifragem reversível, chave
      certa, schema compatível.
      **Backup que nunca foi restaurado é uma suposição, não um backup.**
      É manual de propósito: automatizar exigiria a chave privada nos secrets,
      que é o que a cifragem por chave pública evita.

- [ ] Monitorar Sentry/crashes diariamente durante o beta
- [ ] `flutter pub outdated` de tempos em tempos

---

## ⚪ Dívidas conhecidas — não bloqueiam

- **PDFs nunca são apagados.** O `StorageGateway` só tem `uploadPdf`. O arquivo
  é lido uma única vez (extrair texto → gerar cards) e depois nunca mais. Com
  1 GB grátis e PDF de até 5 MB, isso te dá ~200 gerações em toda a vida do
  app. Uma linha de código resolve.

- **`updateCardProgress` e `updateCardInsight` do `RemoteDatabaseGateway` são
  código morto** — o sync usa `upsertCard`. Pior: `updateCardProgress` hoje
  ignoraria `repetitions` em silêncio se alguém a usasse. Remover ou completar.

- **`fetchChatMessages` não pagina.** Mesmo padrão do bug de perda de dados que
  foi corrigido, mas impacto menor porque o chat é limitado a 40 mensagens.

- **`_ttsLanguage` decide idioma por stopwords.** Uma única palavra como "the"
  num card força `en-US`. Barulhento no uso real.

- **Sem tombstones no sync.** Deleção remota ainda é inferida por ausência. A
  paginação removeu a perda de dados silenciosa, mas a solução correta é
  tombstones (Fase 5.1).

- **Conflito entre dispositivos é last-write-wins implícito.** A tabela
  `reviews` já dá o material para resolver direito: reproduza as revisões em
  ordem cronológica em vez de comparar relógios.

- **Estatísticas reais** (Fase 3.5) — agora é direto, `reviews` já grava e
  sincroniza. Revisões/dia, taxa de acerto, heatmap, carga dos próximos 7 dias.

- **Retenção** (Fase 4): notificações locais e streak. Um app de repetição
  espaçada sem lembrete é instalado, usado uma vez e esquecido.

- **Sem analytics de produto.** Sem saber quantos completam a primeira sessão
  de estudo, a Fase 4 inteira é chute. Cinco eventos resolvem.

- **Sem exportação de dados.** LGPD art. 18 dá direito à portabilidade, e é
  retenção: quem sabe que pode exportar tem menos medo de investir tempo.
