# Lançamento do Memora v1 — checklist operacional

> **Decisão:** o v1 vai para a loja em **modo local** (`kAppMode = AppMode.local`).
> Sem contas, sem servidor, sem sync. O adaptador Supabase continua no
> repositório, pronto, reservado para o v2 — ver a seção v2 no fim deste
> arquivo.
>
> Este arquivo é a lista completa do que falta para publicar, na ordem em que
> faz sentido executar. Marcação de responsável:
> **[você]** = exige conta, cartão, aparelho ou decisão pessoal ·
> **[código]** = dá para eu fazer.

---

## Estado atual

O aplicativo está funcionalmente completo no modo local: onboarding, decks,
cards, geração por IA (texto e PDF), estudo com repetição espaçada, chat com o
agente, insights, estatísticas e backup export/import. 172 testes passando,
`flutter analyze` limpo, CI verde.

**Nada disso jamais rodou num aparelho físico, e nenhum build de release foi
gerado até hoje.** É o maior risco em aberto e a razão da Fase 1 vir antes de
tudo.

---

## Fase 0 — Concluído

- [x] Bundle ID definitivo: `app.memora.mobile`, aplicado em Android, iOS e no
      `kAuthRedirectUrl`
- [x] Assinatura de release lendo `android/key.properties`, com aviso no build
      quando o arquivo não existe
- [x] Backup automático do Android desativado (`allowBackup="false"` +
      `data_extraction_rules.xml`)
- [x] `android:label` corrigido para "Memora"
- [x] Política de privacidade escrita (`docs/politica-de-privacidade.md`)
- [x] GitHub Pages configurado no repositório (`docs/_config.yml`, `docs/index.md`)
- [x] Licença MIT + ressalva sobre o `syncfusion_flutter_pdf` no README
- [x] README reescrito
- [x] `orbit-config.json` removido do rastreamento

---

## Fase 1 — Primeiro build de release e teste em aparelho

**Faça isto antes de qualquer trabalho de loja.** Tudo o que vem depois
depende do resultado, e é aqui que aparecem os problemas que teste nenhum
pega: minificação, permissões de release, memória real, permissões de
armazenamento, motor de voz do sistema.

- [ ] **[código]** Gerar o primeiro build de release
      (`flutter build apk --release`). Sem `key.properties` ele assina com a
      chave de debug e avisa — o que serve perfeitamente para instalar e testar.
- [ ] **[código]** Corrigir o que quebrar no build. Suspeito principal: regras
      de ProGuard/R8 para o `syncfusion_flutter_pdf`, que usa reflexão.
- [ ] **[você]** Instalar num Android físico e percorrer os cinco caminhos que
      nunca foram exercitados fora do emulador de testes:
  - [ ] Cadastrar a chave da DeepSeek e gerar cards a partir de texto
        (valida a permissão de INTERNET, que só existe no manifest de release)
  - [ ] Gerar cards a partir de um PDF grande, perto do limite de 100 páginas /
        20 MB (valida o isolate de extração com a memória de um celular real).
        Se travar, baixar `kMaxPdfSizeMb`/`kMaxPdfPages` para 10/50 em
        `app_constants.dart`
  - [ ] **Exportar** um backup e conferir onde o arquivo foi parar
  - [ ] **Importar** esse backup (permissão de armazenamento no Android 13+)
  - [ ] Ouvir um card em voz alta (motor de TTS real do sistema)
- [ ] **[você]** Testar com a chave da DeepSeek **inválida** e **sem saldo**:
      as mensagens existem em `deepseek_ai_gateway.dart`, mas nenhuma foi vista
      por um usuário de verdade

---

## Fase 2 — Identidade do aplicativo

- [ ] **[você]** **Ícone.** Hoje ainda é o padrão do Flutter, e não existe
      `mipmap-anydpi-v26/` — ou seja, não há ícone adaptativo, obrigatório
      desde o Android 8. Um app com o logotipo do Flutter é reprovado como "não
      pronto para produção". Precisa de um PNG 1024×1024 e das camadas do
      adaptativo (fundo + primeiro plano).
- [ ] **[código]** Gerar todas as densidades a partir do 1024×1024
      (`flutter_launcher_icons` resolve Android e iOS de uma vez)
- [ ] **[você]** Splash screen light/dark
- [ ] **[código]** `CFBundleName` no `ios/Runner/Info.plist` ainda é `memora`
      minúsculo
- [ ] **[você]** **Gerar o keystore de upload.** Sem ele não existe artefato
      publicável:

      keytool -genkey -v -keystore ~/memora-upload.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload

      Depois copie `android/key.properties.example` para
      `android/key.properties` e preencha.
- [ ] **[você]** **Guardar o keystore e as senhas fora desta máquina e fora do
      GitHub.** Perder = nunca mais conseguir atualizar o app publicado; a
      única saída seria lançar um app novo, do zero, sem os usuários. Faça o
      backup no mesmo dia em que gerar.

---

## Fase 3 — Jurídico e privacidade

- [ ] **[você]** **Ligar o GitHub Pages**: Settings → Pages → Deploy from a
      branch → `main` → `/docs`. Confirmar que
      `https://matheusz-nied.github.io/Memora/politica-de-privacidade` abre.
      As lojas pedem uma URL viva no momento da submissão, e trocá-la depois
      exige reenviar o app para revisão.
- [ ] **[você]** Conferir o nome do controlador na política (seções 1 e 16).
      Está como "Matheus Nied", derivado do handle do GitHub — identificação
      errada do controlador é falha formal de LGPD.
- [ ] **[você]** **Registrar a Community License da Syncfusion.** O
      `syncfusion_flutter_pdf` é o extrator de PDF do modo local, portanto
      obrigatório, e não é open source. Gratuita para receita anual abaixo de
      US$ 1 mi com menos de 5 desenvolvedores, mas exige registro. Publicar sem
      ela, ou sem a licença comercial, é uso indevido.
- [ ] **[código ou você]** **Empacotar a fonte Inter.** Hoje o `google_fonts`
      a baixa de `fonts.gstatic.com` no primeiro launch: entrega o IP do
      usuário ao Google, obriga a declarar isso no Data Safety e quebra a
      primeira abertura de quem instalou offline. Empacotar resolve os três e
      permite apagar a seção 3.2 da política.
- [ ] **[você]** Preencher o **Play Data Safety** e as **Apple Privacy
      Nutrition Labels**. No modo local a declaração é curta: o app não coleta
      nada; o conteúdo enviado à IA vai para a DeepSeek com a chave do próprio
      usuário. Se a fonte não for empacotada, declarar também a requisição ao
      Google.
- [ ] **[código]** Links para a política no onboarding e no perfil, com aceite
      registrado no primeiro uso

Os **termos de uso** não são bloqueio: o Google exige apenas a política de
privacidade, e a Apple aplica o EULA padrão dela quando você não fornece um
próprio. Escreva depois, se quiser.

---

## Fase 4 — Qualidade mínima de lançamento

- [ ] **[código]** **Remover a tela de login no modo local.** `login_screen.dart`
      continua alcançável pelo roteador e mostra `SocialAuthButtons` com Google
      e Apple sem handler nenhum. No modo local não existe conta para entrar:
      é tela morta que um revisor pode encontrar.
- [ ] **[código + você]** **Crash reporting (Sentry).** Sem servidor, um crash
      no aparelho do usuário é literalmente invisível para você — é a única
      telemetria que sobra no modo local. Exige criar a conta e o DSN.
- [ ] **[código]** **Lembrar o usuário de exportar o backup.** No modo local o
      backup é a única rede de proteção: perder o aparelho é perder tudo. A
      tela existe e ninguém a visita sozinho; um aviso no perfil depois de N
      dias sem exportar é o mínimo.
- [ ] **[código]** Disclaimer de conteúdo gerado por IA visível no app (a
      seção 14 da política cobre o texto; falta a superfície na interface) e um
      caminho para reportar conteúdo problemático

---

## Fase 5 — Material de loja

- [ ] **[você]** **Screenshots** a partir de telas reais rodando:
      6.7" / 6.5" / 5.5" no iOS, telefone + tablet no Android
- [ ] **[você]** Ícone da ficha da loja, descrição curta e descrição longa
- [ ] **[você]** Categoria, classificação indicativa, país de distribuição
- [ ] **[você]** Conta de teste para os revisores — **só se sobrar tela de
      login**. Removendo-a na Fase 4, este item deixa de existir; mantendo-a,
      a Apple reprova sem ela.

---

## Fase 6 — Submissão

- [ ] **[você]** Conta Google Play Console (US$ 25, pagamento único)
- [ ] **[você]** Apple Developer Program (US$ 99/ano) **e um Mac para
      compilar**. Sem os dois, lançar só no Android é um caminho legítimo e
      corta metade deste arquivo.
- [ ] **[código]** `flutter build appbundle --release` com o keystore real
- [ ] **[você]** Subir em teste interno primeiro, instalar a partir da loja e
      repetir os caminhos da Fase 1 — o artefato da loja passa por
      reassinatura e otimização e não é byte a byte o que você testou
- [ ] **[você]** Só então promover para produção

---

## Depois do lançamento

- [ ] **[você]** Acompanhar crashes diariamente nas primeiras semanas
- [ ] **[você]** Alerta de gasto no painel da DeepSeek — a chave é do usuário,
      mas você vai querer a sua para suporte e reprodução de bugs
- [ ] **[código]** `flutter pub outdated` periodicamente
- [ ] **[você]** Guardar o keystore num segundo lugar, se ainda não guardou

---

## Depois do v1 — o que deixamos de fora de propósito

- **Notificações locais.** Um app de repetição espaçada sem lembrete é
  instalado, usado uma vez e esquecido. No modo local não existe e-mail nem
  push: ou é notificação local, ou não é nada. Não bloqueia publicar; bloqueia
  o lançamento dar em alguma coisa. É o item de maior retorno da lista inteira,
  e a primeira coisa que eu faria depois do v1 no ar.
- **Analytics de produto.** Sem saber quantos completam a primeira sessão de
  estudo, qualquer trabalho de retenção é chute.
- **Fallback de IA.** O `AGENTS.md` promete Gemini 1.5 Flash e não existe
  implementação. Se a DeepSeek cair, o app perde geração, chat e insight de uma
  vez.

---

## Dívidas conhecidas — não bloqueiam

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

---

## v2 — quando ligar o modo nuvem

Nada aqui bloqueia o v1. É a lista que existia antes da decisão de lançar
local, preservada para quando `kAppMode` virar `AppMode.cloud`.

### Deploy

- [ ] `supabase db push` — 2 migrations (`ai_usage_quota`, `reviews_and_repetitions`)
- [ ] `supabase functions deploy` — inclui `delete-account` e `extract-pdf-text`
- [ ] Conferir que `SUPABASE_SERVICE_ROLE_KEY` chega nas functions (o Supabase
      injeta sozinho, mas sem ela o `withQuota` quebra nas 5 — a
      `extract-pdf-text` passou a cobrar quota também)
- [ ] Definir `ALLOWED_ORIGIN` com o domínio do app web

### SMTP

- [ ] **Plugar um SMTP próprio** (Resend, Postmark, SendGrid). O servidor
      embutido do Supabase é limitado a poucos e-mails por hora e marcado como
      "só desenvolvimento" — com 20 pessoas num beta, a maioria não recebe nada.

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

- [ ] **`deno check supabase/functions/*/index.ts`** — a rede do ambiente de
      desenvolvimento bloqueava o download do Deno, então as Edge Functions
      nunca foram type-checked. O job `edge-functions` na CI está como
      `continue-on-error` por isso. Rode local, limpe `deno fmt`/`lint`, e
      então remova o `continue-on-error` para torná-lo bloqueante.
- [ ] **Migrations num Supabase real.** Validadas contra um Postgres 16 local
      com scaffolding equivalente (teto mensal exato, rate limit sem cobrar o
      barrado, estorno cruzado recusado), nunca contra o Supabase de verdade.

### Produto

- [ ] **Monetização** (RevenueCat). Atenção ao vão: o beta fechado vem antes do
      paywall, então quem estourar a quota fica travado sem saída.
- [ ] **Plano Supabase.** O free não tem backup nenhum e pausa o projeto após
      7 dias de inatividade.
- [ ] **Login social: remover ou implementar.** Implementar Google obriga Sign
      in with Apple junto, que exige conta paga e configuração de Services ID.

---

## Comandos de referência

```bash
# Verificação local, na mesma ordem da CI
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test

# Build de teste (assina com a chave de debug se não houver key.properties)
flutter build apk --release

# Build de publicação (exige android/key.properties preenchido)
flutter build appbundle --release

# Depois de mexer em tabela do Drift
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```
