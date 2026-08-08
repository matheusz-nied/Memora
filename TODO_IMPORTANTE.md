# TODO Importante — Memora

> Só o que exige **ação sua**. O código das fases 0, 2 e 3 já está feito e
> testado (ver `PLANO_LANCAMENTO.md` para a análise e o estado de cada fase).
>
> Ordenado por urgência real, não por ordem do plano.

## Decisão de lançamento: **v1 é o modo local**

`lib/core/config/app_mode.dart` está em `AppMode.local` e é assim que o app vai
para a loja. Sem contas, sem servidor, sem sync: identidade no aparelho, dados
no Drift e a chave da DeepSeek cadastrada pelo próprio usuário.

Isso tira do caminho crítico tudo que dependia da nuvem — SMTP, deploy do
Supabase, quota de IA, plano pago, backup do Postgres, monetização e o deep
link de confirmação de e-mail. **Esses itens não sumiram: foram para a seção
v2, no fim do arquivo.** O adaptador Supabase e as Edge Functions continuam no
repositório, prontos e testados; `kAppMode` é `const`, então nada disso entra
no binário local.

O que continua valendo do que era "nuvem": a **política de privacidade**. O
texto que o usuário cola vai para a DeepSeek, com servidores fora do Brasil.
Some a exigência de conta e sync, não a de LGPD.

---

## 🔴 Nunca perca — sem desfazer

- [ ] **Keystore de assinatura do Android** (`.jks` + senhas)
      Perder = **nunca mais** conseguir atualizar o app na Play Store. A conta
      publicada fica órfã e você precisa lançar um app novo, do zero, sem os
      usuários. Faça backup no dia em que gerar.
      O build já está preparado: gere o keystore, copie
      `android/key.properties.example` para `android/key.properties` e
      preencha. Sem esse arquivo o release é assinado com a chave de debug e o
      `assembleRelease` avisa em voz alta.

- [x] **Bundle ID definitivo** — `app.memora.mobile`
      Aplicado nos pontos que existem no modo local: `build.gradle.kts`
      (`namespace` e `applicationId`), pasta e `package` do `MainActivity.kt`,
      `scheme` do intent-filter, `PRODUCT_BUNDLE_IDENTIFIER` nos 3 targets do
      iOS, `CFBundleURLSchemes` e `kAuthRedirectUrl`. Publicado, não muda mais.

---

## 🟠 Antes de qualquer usuário real

### Assinatura e identidade do app

- [ ] Gerar o keystore (ver 🔴) e rodar um `flutter build appbundle` de verdade
- [ ] Ícone 1024×1024 (adaptive no Android), splash light/dark —
      hoje ainda é o ícone padrão do Flutter
- [ ] `CFBundleName` no `ios/Runner/Info.plist` ainda é `memora` minúsculo

### Durabilidade — no modo local, o backup é a única rede de proteção

Na nuvem, perder o aparelho custava a sincronização pendente. Aqui custa tudo.

- [ ] **Testar export e import em device físico**, Android e iOS. É o caminho
      com mais superfície de erro fora do código: permissão de armazenamento
      no Android 13+, o app de Arquivos no iOS, e o `saveFile` que só grava
      quando recebe os bytes.
- [ ] **Lembrar o usuário de exportar.** A tela existe e ninguém a visita
      sozinho. Um aviso no perfil depois de N dias sem export é o mínimo.

### Observabilidade

- [ ] **Crash reporting (Sentry).** No modo local não existe log de servidor:
      um crash no aparelho do usuário é literalmente invisível para você. É a
      única telemetria que sobra, e meia hora de trabalho.

---

## 🟡 Não verificado — rode antes de confiar

- [ ] **Teste em device físico** — Android e iOS. Nada foi testado em device.
- [ ] **PDF grande no limite** (100 páginas / 20 MB)
      No modo local o `syncfusion_flutter_pdf` roda num isolate do próprio
      aparelho: sem teto de CPU de Edge Function, mas com a memória de um
      celular e num device barato. Se travar, o plano B é baixar
      `kMaxPdfSizeMb` / `kMaxPdfPages` em `app_constants.dart` para 10 / 50.
- [ ] **Chave da DeepSeek inválida ou sem saldo** — as mensagens existem
      (`deepseek_ai_gateway.dart`), mas nenhuma foi vista por um usuário real.

---

## 🟡 Bloqueadores de loja

- [x] **Política de privacidade** escrita e preenchida em
      `docs/politica-de-privacidade.md`. Cobre o envio à DeepSeek, a
      transferência internacional, a chave do usuário, o backup, os direitos da
      LGPD e o disclaimer de conteúdo gerado por IA.
- [ ] **Ligar o GitHub Pages**: Settings → Pages → Deploy from a branch →
      `main` → `/docs`. A URL vira
      `https://matheusz-nied.github.io/Memora/politica-de-privacidade`.
      Confirme que ela abre **antes** de colar nos formulários das lojas: uma
      vez submetida, mudar a URL significa reenviar o app para revisão.
- [ ] **Conferir o nome no controlador.** A política assina "Matheus Nied",
      derivado do handle do GitHub. Se o nome civil for outro, corrija nas
      seções 1 e 16 — identificação errada do controlador é falha de LGPD.
- [ ] **Termos de uso** — ainda não escritos. Nada impede publicar a política
      antes; a Apple e o Google exigem os dois.
- [ ] **Empacotar a fonte Inter** e remover a seção 3.2 da política.
      `google_fonts` baixa a fonte de `fonts.gstatic.com` no primeiro launch:
      entrega o IP do usuário ao Google, precisa entrar no Data Safety, e
      quebra a primeira abertura de quem instalou o app offline. Baixar o
      `.ttf`, declarar em `fonts:` no `pubspec.yaml` e trocar `GoogleFonts.inter`
      por `TextStyle(fontFamily: 'Inter')` em `app_typography.dart` resolve os
      três de uma vez.
- [ ] Links no onboarding e no perfil; aceite registrado no primeiro uso
- [ ] Play Data Safety + Apple Privacy Nutrition Labels. No modo local a
      declaração fica curta e honesta: nada é coletado pelo app; o texto que o
      usuário envia à IA vai para a DeepSeek com a chave dele.
- [ ] **Disclaimer de conteúdo gerado por IA + mecanismo de report**
      Causa comum de rejeição em app generativo.
- [ ] **Licença do Syncfusion.** `syncfusion_flutter_pdf` — o extrator de PDF
      do modo local, e portanto obrigatório — **não é open source**. Só pode
      ser usado sob a Community License (grátis, mas exige registro no site da
      Syncfusion e receita anual abaixo de US$ 1 mi com menos de 5
      desenvolvedores) ou sob licença comercial. Publicar sem uma das duas é
      uso indevido. Registre antes de submeter, ou troque o extrator.
      A ressalva já está no `README.md`, para quem clonar o repositório — mas
      o registro em si continua sendo seu.

- [ ] Screenshots: 6.7"/6.5"/5.5" iOS, phone + tablet Android
- [ ] **Conta de teste para os revisores** — só se sobrar tela de login. No
      modo local não há login, o que também elimina esse item (ver 🔵).

---

## 🔵 Decisões pendentes

- [ ] **Tela de login no modo local: remover.**
      `login_screen.dart` continua alcançável pelo roteador e mostra
      `SocialAuthButtons` com Google e Apple sem handler nenhum. No modo local
      não existe conta para entrar — é tela morta que um revisor pode achar.

- [ ] **Fallback de IA: implementar ou tirar da doc.**
      O `AGENTS.md` promete "fallback: Gemini 1.5 Flash" e **não existe
      implementação**. No modo local o impacto é menor (a chave é do usuário,
      não sua), mas se a DeepSeek cair o app perde geração, chat e insight de
      uma vez.

- [ ] **Notificações locais.** Um app de repetição espaçada sem lembrete é
      instalado, usado uma vez e esquecido. No modo local não existe e-mail,
      push nem qualquer outro canal para trazer o usuário de volta: ou é
      notificação local, ou não é nada. Não bloqueia publicar; bloqueia o
      lançamento dar em alguma coisa.

---

## 🟢 Recorrente

- [ ] Monitorar crashes diariamente durante o beta
- [ ] `flutter pub outdated` de tempos em tempos

---

## ⚪ Dívidas conhecidas — não bloqueiam

Marcadas com ☁️ as que só existem no modo nuvem.

- **`_ttsLanguage` decide idioma por stopwords.** Uma única palavra como "the"
  num card força `en-US`. Barulhento no uso real.

- **`fetchChatMessages` não pagina.** Impacto pequeno: o chat é limitado a 40
  mensagens.

- ☁️ **PDFs nunca são apagados** pelo `StorageGateway` — mas a
  `extract-pdf-text` já remove o arquivo depois de ler. Confirmar antes de
  ligar a nuvem.

- ☁️ **`updateCardProgress` e `updateCardInsight` do `RemoteDatabaseGateway`
  são código morto** — o sync usa `upsertCard`. Pior: `updateCardProgress`
  ignoraria `repetitions` em silêncio se alguém a usasse.

- ☁️ **Sem tombstones no sync.** Deleção remota ainda é inferida por ausência.

- ☁️ **Conflito entre dispositivos é last-write-wins implícito.** A tabela
  `reviews` já dá o material para resolver direito: reproduza as revisões em
  ordem cronológica em vez de comparar relógios.

- **Sem analytics de produto.** Sem saber quantos completam a primeira sessão
  de estudo, qualquer trabalho de retenção é chute.

---

## 📦 v2 — quando ligar o modo nuvem

Nada aqui bloqueia o v1. É a lista que estava no topo deste arquivo antes da
decisão de lançar local, preservada para quando `kAppMode` virar
`AppMode.cloud`.

### Deploy

- [ ] `supabase db push` — 2 migrations (`ai_usage_quota`, `reviews_and_repetitions`)
- [ ] `supabase functions deploy` — inclui `delete-account` e `extract-pdf-text`
- [ ] Conferir que `SUPABASE_SERVICE_ROLE_KEY` chega nas functions
      (o Supabase injeta sozinho, mas sem ela o `withQuota` quebra nas 5 —
      a `extract-pdf-text` passou a cobrar quota também)
- [ ] Definir `ALLOWED_ORIGIN` com o domínio do app web
- [ ] Alerta de gasto no painel da DeepSeek

### SMTP

- [ ] **Plugar um SMTP próprio** (Resend, Postmark, SendGrid). O servidor
      embutido do Supabase é limitado a poucos e-mails por hora e marcado como
      "só desenvolvimento".

### Deep link

- [ ] Cadastrar `app.memora.mobile://auth-callback` no Supabase Dashboard
      (Authentication → URL Configuration). O link de confirmação só funciona
      para e-mails **gerados depois** dessa configuração.
- [ ] Testar ponta a ponta em device físico: cadastro → e-mail → deep link

### Backup do Postgres

- [ ] **Chave privada `age`** (`memora-backup.key`) — perder = backups viram
      lixo ilegível; vazar = backups viram dado pessoal exposto. Cofre de
      senhas ou armazenamento offline.
- [ ] `age-keygen -o memora-backup.key`
- [ ] Secrets no GitHub: `BACKUP_DATABASE_URL` (conexão **direta**, porta 5432,
      não o pooler) e `BACKUP_AGE_PUBLIC_KEY`
- [ ] Rodar Actions → backup → Run workflow uma vez, à mão
- [ ] **Drill de restauração mensal.** Backup que nunca foi restaurado é uma
      suposição, não um backup. Manual de propósito: automatizar exigiria a
      chave privada nos secrets, que é o que a cifragem por chave pública
      evita. Runbook: `tool/backup/README.md`.

### Edge Functions

- [ ] **`deno check supabase/functions/*/index.ts`** — a rede do ambiente
      bloqueava o download do Deno, então as Edge Functions nunca foram
      type-checked. O job `edge-functions` na CI está como `continue-on-error`
      por isso. Rode local, limpe `deno fmt`/`lint`, e então remova o
      `continue-on-error`.
- [ ] **Migrations num Supabase real.** Validadas contra um Postgres 16 local
      com scaffolding equivalente (teto mensal exato, rate limit sem cobrar o
      barrado, estorno cruzado recusado), nunca contra o Supabase de verdade.

### Produto

- [ ] **Monetização** (RevenueCat). Atenção ao vão: o beta fechado vem **antes**
      do paywall, então quem estourar a quota fica travado sem saída.
- [ ] **Plano Supabase.** O free não tem backup nenhum e pausa o projeto após
      7 dias de inatividade.
- [ ] **Login social: remover ou implementar.** Implementar Google obriga Sign
      in with Apple junto, que exige conta paga e configuração de Services ID.
