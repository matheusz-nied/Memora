# Lançamento do Memora v1 — o que falta

> **Decisão:** o Memora é um app **local**. Sem contas, sem servidor, sem sync.
> O caminho de nuvem que existia no repositório foi removido; ele continua no
> histórico do git se um dia a decisão mudar.
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

## 5. Licenças das dependências

- [x] **Nada a registrar.** O extrator de PDF é próprio
      (`lib/core/backend/local/pdf/`), e todas as dependências de runtime são
      livres. Foi o `syncfusion_flutter_pdf` que criou este item: exigia
      registro na Community License para publicar. Ao trocá-lo por código
      próprio, a obrigação deixou de existir — não é preciso registrar nada
      nem acompanhar mudança de limite de receita.

---

## 6. Fichas das lojas

- [ ] **Play Data Safety** e **Apple Privacy Nutrition Labels**. A declaração é
      curta e verdadeira: o app não coleta nada, não tem analytics e não tem
      SDK de terceiro que fale com rede. O único destino é a DeepSeek, com a
      chave do próprio usuário, quando ele aciona uma função de IA.
- [ ] Screenshots a partir de telas reais: 6.7" / 6.5" / 5.5" no iOS,
      telefone + tablet no Android
- [ ] Descrição curta, descrição longa, categoria, classificação indicativa

**Conta de teste para os revisores não é necessária** — o app não tem login.
Está anotado aqui só para você não procurar por ele.

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
  instalado, usado uma vez e esquecido. Sem servidor não existe e-mail nem
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

- **`_ttsLanguage` decide idioma por stopwords.** Uma única palavra como "the"
  num card força `en-US`. Barulhento no uso real.
- **`fetchChatHistory` não pagina.** Impacto pequeno: o chat é limitado a 40
  mensagens.
- **A chave da DeepSeek fica em texto plano** no `shared_preferences`. É a
  chave do usuário, contra a conta dele, e o armazenamento é privado do app —
  o custo de um cofre nativo não se paga. O backup automático do Android já
  está desligado justamente por causa dela.
- **Sem fallback de IA.** Se a DeepSeek cair, geração, chat e insight caem
  juntos.

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
- Bundle ID `app.memora.mobile` em Android e iOS
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

**Local, de vez**
- Todo o caminho de nuvem removido: SDK do Supabase, adaptador, Edge Functions,
  migrations SQL, motor de sync, telas de conta, quota de IA, o `.env` que ia
  embarcado no APK e o deep link `auth-callback` do Android e do iOS
- Identidade passou a ser um UUID do aparelho (`DeviceUserId`), sem a ficção de
  sessão em volta
- Schema do Drift na v4: `sync_pending` derrubada das três tabelas, com
  migração e teste de integridade de dados
- Lembrete de backup no dashboard depois de 30 dias sem exportar, ou para quem
  nunca exportou

**Repositório**
- Licença MIT, sem ressalva: as dependências de runtime são todas livres
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
dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift/generated/
```
