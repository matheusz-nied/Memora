# Lançamento do Memora v1 — o que falta

> **Decisão:** o v1 vai para a loja em **modo local** (`kAppMode = AppMode.local`).
> Sem contas, sem servidor, sem sync. O adaptador Supabase continua no
> repositório, pronto, reservado para o v2 — ver a seção no fim deste arquivo.
>
> **Tudo o que estava na mão do código já foi feito** (lista no fim). O que
> sobrou aqui exige conta, cartão, aparelho, arte ou uma decisão sua. Está na
> ordem em que faz sentido executar.

---

## 1. Instale num aparelho e use o app

**Antes de qualquer trabalho de loja.** Nada aqui jamais rodou num celular de
verdade: os 170 testes rodam na VM do Dart, com fakes no lugar do backend. O
APK de release já compila e sai em
`build/app/outputs/flutter-apk/app-release.apk`, assinado com a chave de debug
— serve para instalar e testar.

```bash
flutter build apk --release
```

Percorra os caminhos que só existem fora do emulador:

- [ ] Cadastrar a chave da DeepSeek e gerar cards a partir de texto
      (valida a permissão de INTERNET, que só existe no manifest de release)
- [ ] Gerar cards de um PDF grande, perto de 100 páginas / 20 MB — valida a
      extração num isolate com a memória real de um celular. Se travar, baixe
      `kMaxPdfSizeMb` / `kMaxPdfPages` para 10 / 50 em `app_constants.dart`
- [ ] **Exportar** um backup e ver onde o arquivo foi parar
- [ ] **Importar** esse mesmo backup (permissão de armazenamento no Android 13+)
- [ ] Ouvir um card em voz alta, com o motor de TTS real do sistema
- [ ] Testar com a chave da DeepSeek **inválida** e **sem saldo**: as mensagens
      existem, mas nenhuma foi vista por um usuário de verdade
- [ ] Tocar no link da política, no onboarding e no perfil, e ver se o
      navegador abre

---

## 2. Conferir ícone e splash no aparelho

Ícone e splash estão prontos e gerados. Falta só ver com os próprios olhos,
junto com o item 1 — o ícone adaptativo muda de forma conforme o launcher, e a
splash do Android 12+ usa uma API diferente da dos anteriores.

- [ ] Ícone no launcher, em tema claro e escuro
- [ ] Splash ao abrir, em tema claro e escuro

Se um dia trocar a arte: substitua os arquivos em `assets/icon/` e rode
`dart run flutter_launcher_icons` e `dart run flutter_native_splash:create`.
As regras que a arte precisa respeitar estão em `assets/icon/README.md`.

---

## 3. Keystore

Sem ele não existe artefato publicável. O `bundleRelease` já falha com a
instrução quando o arquivo não está lá.

- [ ] Gerar:

      keytool -genkey -v -keystore ~/memora-upload.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload

- [ ] Copiar `android/key.properties.example` para `android/key.properties` e
      preencher
- [ ] **Guardar o `.jks` e as senhas fora desta máquina e fora do GitHub, no
      mesmo dia em que gerar.** Perder = nunca mais atualizar o app publicado;
      a única saída seria lançar um app novo, do zero, sem os usuários.

---

## 4. Publicar a política de privacidade

O texto está pronto em `docs/politica-de-privacidade.md` e o app já aponta para
a URL abaixo, no onboarding e no perfil — ela precisa existir.

- [ ] Settings → Pages → Deploy from a branch → `main` → `/docs`
- [ ] Conferir que
      `https://matheusz-nied.github.io/Memora/politica-de-privacidade.html` abre.
      As lojas pedem uma URL viva na submissão, e trocá-la depois exige
      reenviar o app para revisão
- [ ] **Conferir o nome do controlador** (seções 1 e 16). Está como "Matheus
      Nied", derivado do handle do GitHub — identificação errada do controlador
      é falha formal de LGPD

---

## 5. Licença da Syncfusion

- [ ] Registrar a **Community License** da Syncfusion. O
      `syncfusion_flutter_pdf` é o extrator de PDF do modo local, portanto
      obrigatório, e não é open source. Gratuita para receita anual abaixo de
      US$ 1 mi com menos de 5 desenvolvedores, mas **exige registro**. Publicar
      sem ela, ou sem a comercial, é uso indevido.

---

## 6. Fichas das lojas

- [ ] **Play Data Safety** e **Apple Privacy Nutrition Labels**. A declaração é
      curta e verdadeira: o app não coleta nada, não tem analytics e não tem
      SDK de terceiro que fale com rede. O único destino é a DeepSeek, com a
      chave do próprio usuário, quando ele aciona uma função de IA.
- [ ] Screenshots a partir de telas reais: 6.7" / 6.5" / 5.5" no iOS,
      telefone + tablet no Android
- [ ] Descrição curta, descrição longa, categoria, classificação indicativa

**Conta de teste para os revisores não é mais necessária** — o modo local não
tem login. Está anotado aqui só para você não procurar por ele.

Os **termos de uso** também não bloqueiam: o Google exige apenas a política de
privacidade, e a Apple aplica o EULA padrão dela quando você não fornece um.

---

## 7. Contas e envio

- [ ] Google Play Console — US$ 25, pagamento único
- [ ] Apple Developer Program — US$ 99/ano **e um Mac para compilar**. Sem os
      dois, lançar só no Android é um caminho legítimo e corta metade desta
      lista
- [ ] `flutter build appbundle --release` (agora com o keystore)
- [ ] Subir em **teste interno** primeiro, instalar a partir da loja e repetir
      os caminhos do item 1: o artefato da loja passa por reassinatura e
      otimização, e não é byte a byte o que você testou
- [ ] Só então promover para produção

---

## 8. Uma decisão que eu não podia tomar por você

**Crash reporting.** Sem servidor, um crash no aparelho do usuário é invisível
para você — não há log, não há métrica; você descobre por avaliação de uma
estrela. O Sentry resolve isso.

Não instalei, de propósito. Adicionar o SDK muda a postura de privacidade do
app: hoje a política afirma, na seção 3.4, que a DeepSeek é o **único** destino
de rede e que, sem chave cadastrada, o app não faz uma requisição sequer. Isso
é verdade agora, e é um argumento forte na ficha da loja. Ligar o Sentry obriga
a reescrever essa seção, declarar o SDK no Data Safety e decidir se o envio é
automático ou opt-in.

É troca de posicionamento, não de código. Se quiser, eu implemento — o caminho
mais coerente com o app seria opt-in, com um botão no perfil.

---

## Depois do v1

- **Notificações locais.** Um app de repetição espaçada sem lembrete é
  instalado, usado uma vez e esquecido. No modo local não existe e-mail nem
  push: ou é notificação local, ou não é nada. Não bloqueia publicar; bloqueia
  o lançamento dar em alguma coisa. É o item de maior retorno da lista inteira.
- **Analytics de produto.** Sem saber quantos completam a primeira sessão de
  estudo, qualquer trabalho de retenção é chute. Mesma ressalva do item 8.
- **Fallback de IA.** O `AGENTS.md` promete Gemini 1.5 Flash e não existe
  implementação. Se a DeepSeek cair, o app perde geração, chat e insight de uma
  vez.
- **Termos de uso** próprios.

---

## Dívidas conhecidas — não bloqueiam

Marcadas com ☁️ as que só existem no modo nuvem.

- **`_ttsLanguage` decide idioma por stopwords.** Uma única palavra como "the"
  num card força `en-US`. Barulhento no uso real.
- **`fetchChatMessages` não pagina.** Impacto pequeno: o chat é limitado a 40
  mensagens.
- ☁️ **`updateCardProgress` e `updateCardInsight` do `RemoteDatabaseGateway`
  são código morto** — o sync usa `upsertCard`. Pior: `updateCardProgress`
  ignoraria `repetitions` em silêncio se alguém a usasse.
- ☁️ **Sem tombstones no sync.** Deleção remota ainda é inferida por ausência.
- ☁️ **Conflito entre dispositivos é last-write-wins implícito.** A tabela
  `reviews` já dá o material para resolver direito: reproduza as revisões em
  ordem cronológica em vez de comparar relógios.
- ☁️ **PDFs no Storage** — a `extract-pdf-text` já remove o arquivo depois de
  ler; confirmar antes de ligar a nuvem.

---

## v2 — quando ligar o modo nuvem

Nada aqui bloqueia o v1.

### Deploy

- [ ] `supabase db push` — 2 migrations (`ai_usage_quota`, `reviews_and_repetitions`)
- [ ] `supabase functions deploy` — inclui `delete-account` e `extract-pdf-text`
- [ ] Conferir que `SUPABASE_SERVICE_ROLE_KEY` chega nas functions (o Supabase
      injeta sozinho, mas sem ela o `withQuota` quebra nas 5 — a
      `extract-pdf-text` passou a cobrar quota também)
- [ ] Definir `ALLOWED_ORIGIN` com o domínio do app web

### SMTP

- [ ] **SMTP próprio** (Resend, Postmark, SendGrid). O servidor embutido do
      Supabase é limitado a poucos e-mails por hora e marcado como "só
      desenvolvimento" — com 20 pessoas num beta, a maioria não recebe nada.

### Deep link

- [ ] Cadastrar `app.memora.mobile://auth-callback` no Supabase Dashboard
      (Authentication → URL Configuration). O link de confirmação só funciona
      para e-mails **gerados depois** dessa configuração.
- [ ] Testar ponta a ponta em device: cadastro → e-mail → deep link

### Backup do Postgres

- [ ] **Chave privada `age`** (`memora-backup.key`) — perder = backups viram
      lixo ilegível; vazar = backups viram dado pessoal exposto
- [ ] `age-keygen -o memora-backup.key`
- [ ] Secrets no GitHub: `BACKUP_DATABASE_URL` (conexão **direta**, porta 5432,
      não o pooler) e `BACKUP_AGE_PUBLIC_KEY`
- [ ] Rodar Actions → backup → Run workflow uma vez, à mão
- [ ] **Drill de restauração mensal.** Backup que nunca foi restaurado é uma
      suposição, não um backup. Runbook: `tool/backup/README.md`.

### Edge Functions

- [ ] **`deno check supabase/functions/*/index.ts`** — nunca foram
      type-checked; o job `edge-functions` na CI está como `continue-on-error`
      por isso. Rode local, limpe `deno fmt`/`lint`, e torne o job bloqueante.
- [ ] **Migrations num Supabase real.** Validadas contra um Postgres 16 local
      com scaffolding equivalente, nunca contra o Supabase de verdade.

### Produto

- [ ] **Monetização** (RevenueCat). Atenção ao vão: o beta vem antes do paywall,
      então quem estourar a quota fica travado sem saída.
- [ ] **Plano Supabase.** O free não tem backup nenhum e pausa o projeto após
      7 dias de inatividade.
- [ ] **Login social: remover ou implementar.** As telas de conta hoje só são
      compiladas no modo nuvem. Implementar Google obriga Sign in with Apple
      junto, que exige conta paga e Services ID.

---

## Feito

Registro do que saiu do caminho, para não ser refeito.

**Identidade e build**
- Splash em claro e escuro, com as cores do `AppTheme`. Duas versões, porque o
  Android 12+ ignora a splash clássica e usa a API própria do sistema, que
  recorta a arte num círculo e só garante os 2/3 centrais
- Ícone gerado em todas as densidades, Android e iOS, a partir de
  `assets/icon/`. O `icon.png` foi recortado para tirar os cantos arredondados
  em branco — as duas plataformas aplicam a própria máscara, e os cantos
  desenhados virariam lascas brancas. O fundo do ícone adaptativo é um
  gradiente do azul da arte, e não o branco chapado do config inicial
- Bundle ID `app.memora.mobile` em Android, iOS e no `kAuthRedirectUrl`
- Assinatura de release por `android/key.properties`; o `bundleRelease` falha
  com instrução quando ele não existe, e o `assembleRelease` segue com a chave
  de debug para teste em aparelho
- `android:label` e `CFBundleName` como "Memora"
- Primeiro build de release gerado e verificado

**Privacidade**
- Política escrita e preenchida em `docs/`, com o GitHub Pages configurado no
  repositório
- Backup automático do Android desligado (`allowBackup="false"` +
  `data_extraction_rules.xml`), que mandava a chave da DeepSeek para o Google
  Drive do usuário
- Fonte Inter empacotada e `google_fonts` removido: o app não fala mais com
  nenhum servidor de terceiro além da DeepSeek
- Link para a política no onboarding e no perfil, com o aceite **registrado** e
  versionado

**Conteúdo gerado por IA**
- Aviso visível na revisão dos cards gerados, no insight e no chat
- Canal de report por e-mail, no perfil e junto do aviso

**Modo local**
- Telas de login, cadastro e recuperação de senha saem do binário local, junto
  com os botões de login social sem handler
- Lembrete de backup no dashboard depois de 30 dias sem exportar, ou para quem
  nunca exportou

**Repositório**
- Licença MIT, com a ressalva do Syncfusion no README
- README reescrito
- `orbit-config.json` fora do rastreamento

---

## Comandos

```bash
# O que a CI cobra, na ordem
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test

# APK de teste em aparelho (assina com a chave de debug)
flutter build apk --release

# .aab de publicação (exige android/key.properties)
flutter build appbundle --release

# Ícones, depois de colocar a arte em assets/icon/
dart run flutter_launcher_icons

# Depois de mexer em tabela do Drift
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```
