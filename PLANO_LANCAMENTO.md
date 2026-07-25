# Memora — Plano de Lançamento (revisado)

> Revisão do plano original a partir de uma leitura do código.
> O que mudou: correções de fatos errados, uma inversão de dependência,
> itens que faltavam e um bug de perda de dados que não estava mapeado.
>
> Ações pendentes, ordenadas por urgência:
> [`TODO_IMPORTANTE.md`](TODO_IMPORTANTE.md).

---

## Parte 1 — O que o plano original acertou

Vale registrar, porque a maior parte se sustenta:

- **A ordem geral está certa.** Fundação → conformidade → custo → produto →
  retenção → lançamento é a sequência correta.
- **"Fase 2 é inegociável antes do beta"** é a avaliação mais importante do
  documento e estava certa.
- **Adicionar `reviews` cedo** porque histórico não se reconstrói: certo, e é
  o tipo de decisão que só fica óbvia depois que é tarde.
- **Não deixar refactor grande antes da Fase 0**: certo.
- **O caminho mínimo de 4 semanas** é um corte honesto.

---

## Parte 2 — O que estava errado

### 2.1 A CI proposta nasceria vermelha

Três motivos, todos verificados rodando:

1. **`flutter test` falha sem `.env`.** O `pubspec.yaml` declara `.env` como
   asset, então o build do bundle de teste quebra com
   `No file or variants found for asset: .env`. O workflow precisa criar o
   arquivo antes.
2. **`flutter analyze --fatal-infos` acusava 85 issues** — 81 `withOpacity`
   e 4 outras deprecações. A CI reprovaria todo PR desde o primeiro dia.
3. **Os `.g.dart` do Drift são versionados** (o `.gitignore` abre exceção para
   `lib/core/database/**`). Rodar `build_runner` na CI sem comparar com o que
   está commitado não verifica nada; e rodar `dart format` depois pode
   conflitar com o gerado.

> Corrigido: o workflow cria o `.env`, o analyze está limpo em 0 issues, e a
> CI falha explicitamente se o código gerado estiver desatualizado.

### 2.2 `beforeOpen` com `PRAGMA foreign_keys = ON` não faz nada aqui

O plano incluía esse pragma na `MigrationStrategy`. As tabelas Drift do projeto
**não declaram foreign keys** — `CardsTable.deckId` é um `text()` puro, sem
`references`. O pragma é inócuo hoje e perigoso amanhã: se as FKs forem
declaradas sem `onDelete: KeyAction.cascade`, `deleteCardsForDeckPermanently`
passa a violar constraint.

O que realmente faltava não era o pragma, era o **snapshot versionado + teste de
migração**, que é o que detecta "mudei a tabela e esqueci de bumpar a versão".

### 2.3 O guard de quota tinha uma corrida

```
const { count } = await admin.from("ai_usage").select(...)   // lê
if (count + cost > LIMIT) throw                              // decide
// ... chamada à IA ...                                      // usa
```

Entre o `select` e o uso não há nada segurando o saldo. N requisições
simultâneas leem o mesmo `count` e passam todas. Com rate limit por minuto isso
vira explorável: dispare 50 requisições em paralelo e todas passam.

> Corrigido: `consume_ai_quota` **reserva** dentro de um
> `pg_advisory_xact_lock` por usuário, e estorna se a IA falhar.

### 2.4 O plano deixava o estorno nas mãos do cliente

O plano não dizia quem pode chamar as funções de quota. Se `refund_ai_quota`
for executável pelo `authenticated`, o ataque é trivial: consumir, usar a IA,
estornar. As funções de escrita têm que ser **`service_role` apenas** — e por
isso recebem `p_user_id` explícito em vez de usar `auth.uid()`.

### 2.5 O algoritmo proposto ignorava o bug mais visível

O plano corrigia três coisas reais (`hard` subtraindo dias, ease desatualizado,
falta de learning steps). Mas o defeito que o usuário mais sente ficou de fora:

**"Não sei" não tinha nenhuma consequência dentro da sessão.** O card ia para
`interval = 1` e sumia até o dia seguinte. Numa sessão de 20 cards, errar 8 não
mudava nada do que você via. É o oposto do que qualquer app de flashcard faz.

> Corrigido: `again` recoloca o card no fim da fila da sessão.

Detalhes menores: `easy` durante o aprendizado deveria graduar o card direto
(4 dias, como no Anki) em vez de seguir o learning step; e no código proposto o
branch `CardRating.again => 1` dentro do switch final era inalcançável.

### 2.6 A ordem 3.2 → 3.3 está invertida

O plano lista "3.3 sessão só com cards vencidos" como se fosse independente de
"3.2 corrigir o algoritmo". Não é.

`createCard` grava `dueDate = now`. Ou seja, **todo card novo já nasce
vencido**. Filtrar por `dueDate <= hoje` não separa "novo" de "atrasado": um
deck recém-gerado com 100 cards aparece como 100 vencidos. O limite diário de
cards novos, que o próprio plano pede em 3.3, precisa de um critério para
distinguir — e o único disponível é `repetitions`, que só existe depois de 3.2.

> **3.3 depende de 3.2.** Fazer na ordem do documento produz um limite de novos
> que não consegue identificar o que é novo.

### 2.7 A regra de conflito da Fase 5.2 perde dados de propósito

> "Para progresso de estudo, vencer o **maior** `interval_days`"

Isso descarta sistematicamente o "errei". Dispositivo A: usuário erra, intervalo
vai para 1. Dispositivo B (offline, desatualizado): acerta, intervalo vai para
30. Vencer o maior significa que **o erro nunca aconteceu** — exatamente o dado
mais importante para o SRS.

O correto é vencer a **revisão mais recente**. E a tabela `reviews` da Fase 3.1
já entrega isso de graça: reproduza as revisões em ordem cronológica e o estado
final é determinístico, sem depender de comparar relógios de dispositivos.

### 2.8 A Fase 5.1 esconde um bug ativo de perda de dados

O plano trata sync incremental como otimização de v1.1. Uma parte é otimização.
Outra parte é perda de dados acontecendo agora:

`fetchDecks`/`fetchCards` liam a coleção inteira numa requisição. O PostgREST
corta a resposta no `max-rows` do projeto (**1000 por padrão**) sem sinalizar
truncamento. E `syncCards` trata ausência de linha na resposta como "apagado
remotamente":

```dart
final remotelyDeletedCards = syncedLocalCards.where(
  (card) => !remoteCardIds.contains(card.id) && ...
);
for (final card in remotelyDeletedCards) {
  await _database.cardsDao.deleteCardPermanently(card.id);  // <-- permanente
}
```

Um deck com mais de 1000 cards perde os excedentes do banco local, em silêncio.

> Corrigido e promovido para bloqueante. Tombstones continuam na Fase 5.

---

## Parte 3 — O que faltava no plano

### 3.1 As mensagens de erro da IA nunca chegavam ao usuário

As Edge Functions respondem erro com status ≥ 400. O `functions_client` do
Supabase **lança `FunctionException`** nesses casos em vez de devolver o corpo.
O `_invoke` do `SupabaseAiGateway` só tratava erro dentro de resposta 2xx:

```dart
if (data['error'] != null) { throw BackendException(...); }  // inalcançável
```

Resultado: toda mensagem cuidadosamente escrita em português ("A conta da
DeepSeek está sem saldo", "O PDF deve ter no máximo 10 páginas") era descartada,
e a tela mostrava `FunctionException(status: 402, details: {...})`.

Isso também era pré-requisito da Fase 2: sem o `code` chegando ao cliente, não
dá para tratar `quota_exceeded` de forma diferente de um erro genérico.

> Corrigido.

### 3.2 O histórico de chat não tinha teto no servidor

`kMaxChatMessages = 40` existia **só no cliente**. A Edge Function validava que
`messages` era um array e nada mais. Uma requisição com 500 mensagens de 4000
caracteres cada vira uma chamada de milhões de tokens à DeepSeek — mais cara que
o mês inteiro de quota de um usuário free.

Era o furo de custo mais concreto do app, e não estava no plano.

> Corrigido: teto de 40 mensagens / 24k caracteres no servidor.

### 3.3 Nenhuma chamada à DeepSeek tinha `max_tokens`

As 4 chamadas omitiam `max_tokens`, então o custo de uma única resposta não
tinha teto superior. Quota por operação sem teto por operação é meia proteção.

> Corrigido.

### 3.4 O fallback de IA está na documentação mas não no código

O `AGENTS.md` diz **"IA: DeepSeek-chat (fallback: Gemini 1.5 Flash)"**. Não há
fallback implementado em lugar nenhum. Se a DeepSeek cair ou ficar sem saldo, o
app perde geração, chat e insight de uma vez.

**Decida antes do beta:** implementar o fallback (~1 dia) ou remover da doc.
Documentação que promete o que não existe é pior que ausência de documentação.

### 3.5 Falta exportação de dados

LGPD art. 18 dá direito à portabilidade, e a Apple valoriza. Além da
conformidade, é retenção: quem sabe que pode exportar tem menos medo de
investir tempo montando decks. Exportar deck como JSON/CSV é meio dia.

### 3.6 Falta analytics de produto

Sentry cobre crash. Mas sem saber quantos usuários completam a primeira sessão
de estudo, **a Fase 4 inteira é chute**. Cinco eventos resolvem:
`onboarding_complete`, `deck_created`, `cards_generated`,
`study_session_complete`, `chat_message_sent`. Meio dia, e informa todas as
decisões seguintes.

### 3.7 Falta o requisito de conteúdo gerado por IA da Apple

App que gera conteúdo por IA precisa de filtro de conteúdo, um mecanismo de
report e disclaimer de que o conteúdo é gerado automaticamente e pode conter
erros. Não está no checklist da Fase 1.3 e é causa comum de rejeição.

### 3.8 Existe um vão entre a quota (Fase 2) e o paywall (Fase 6.2)

O beta fechado (6.1) vem **antes** da monetização (6.2). No intervalo o usuário
que estourar 30 créditos fica travado sem nenhuma saída. Suba a quota durante o
beta ou coloque um "fale com a gente" na tela de limite.

### 3.9 Dívidas menores encontradas

- `RemoteDatabaseGateway.updateCardProgress` e `updateCardInsight` **não são
  usadas** — o sync usa `upsertCard`. Código morto no contrato, e
  `updateCardProgress` hoje silenciosamente ignoraria `repetitions`. Remover ou
  completar.
- `fetchChatMessages` não pagina (mesmo padrão do 2.8, menor impacto porque o
  chat é limitado a 40 mensagens).
- `_ttsLanguage` decide idioma por heurística de stopwords: uma única palavra
  como "the" no card força `en-US`. Errar isso é barulhento no uso real.
- As Edge Functions nunca passaram por `deno fmt/lint/check`. O job existe na CI
  como advisory; rode local, limpe e torne bloqueante.

---

## Parte 4 — Plano revisado

Mudanças em relação ao original: 3.1/3.2 sobem antes de 3.3; a paginação do sync
vira bloqueante; entram observabilidade de produto, fallback de IA e exportação.

| Fase | Tema | Estado | Bloqueia lançamento? |
|---|---|---|---|
| 0 | Fundação técnica | ✅ **feito** (CI, migrações, analyze limpo) | — |
| 1 | Identidade e conformidade | 🟡 parcial (exclusão de conta ✅) | ✅ Sim |
| 2 | Controle de custo da IA | ✅ **feito** (falta deploy + alertas) | ✅ Sim |
| 3 | Coração do SRS | ✅ **feito** (falta 3.5 estatísticas) | ✅ Sim |
| 4 | Retenção | ⬜ pendente | ⚠️ Recomendado |
| 5 | Robustez e testes | 🟡 parcial (perda de dados ✅) | Parcial |
| 6 | Beta, monetização, lançamento | ⬜ pendente | ✅ Sim |

### O que sobrou de bloqueante

**Fase 1 — só decisões suas:**

- [ ] **1.1 Bundle ID definitivo.** Único item verdadeiramente irreversível do
      plano. Continua `com.example.memora`, rejeitado nas duas lojas. Precisa da
      sua decisão (ex.: `app.memora.mobile`). Os 7 pontos do plano original
      estão corretos; some o Redirect URL do Supabase.
- [ ] 1.3 Política de privacidade e termos — precisa dizer explicitamente que o
      conteúdo vai para a **DeepSeek**, com servidores fora do Brasil.
- [ ] 1.4 Ícone, splash, screenshots. (`pubspec` já tem `description` real.)
- [ ] 1.5 Decidir o login social. Recomendo **remover** no v1: os botões estão
      renderizados e desabilitados, e implementar Google obriga Sign in with
      Apple junto.
- [ ] **Novo:** disclaimer de conteúdo gerado por IA + mecanismo de report.

**Fase 2 — falta só operação:**

- [ ] Aplicar as migrations e fazer deploy das functions
- [ ] Configurar `SUPABASE_SERVICE_ROLE_KEY` e `ALLOWED_ORIGIN` no ambiente
- [ ] 2.4 Alerta de gasto no painel da DeepSeek
- [ ] Decidir o fallback de IA (3.4) — implementar ou tirar da doc

**Fase 3 — sobrou só o que depende de dados:**

- [ ] 3.5 Estatísticas reais. Agora é direto: a tabela `reviews` já grava e
      sincroniza. Revisões/dia, taxa de acerto, heatmap, carga dos próximos
      7 dias.

**Fase 4 e 6:** como no plano original. Na 4.2, o streak sai derivado de
`reviews` — não crie contador separado, ele dessincroniza.

**Fase 5:** 5.1 (tombstones + incremental) e 5.2 (conflitos, com a regra
corrigida de 2.7) podem ir para v1.1. 5.3 (chat offline) e 5.4 (testes) valem
antes do beta.

---

## Parte 5 — Estado atual do código

Feito e verificado (`flutter analyze`: 0 issues; `flutter test`: 72 passando).

### Fundação
- CI com job Flutter (format, analyze `--fatal-infos`, test, verificação de
  código gerado) e job Deno advisory para as Edge Functions
- `MigrationStrategy` explícita, snapshots v1 e v2 em `drift_schemas/`,
  teste de migração **com integridade de dados** (insere na v1, valida na v2)
- Analyze de 85 → 0 issues

### Custo de IA
- `ai_usage` + `ai_user_tiers` com RLS; escrita só via `security definer`
- Reserva atômica com advisory lock, estorno em falha da IA
- `withQuota` nas 4 functions; teto por minuto e por mês
- Histórico de chat limitado no servidor; `max_tokens` em todas as chamadas
- `BackendException.code` e conversão de `FunctionException`
- Card de consumo no perfil

### SRS
- Algoritmo reescrito: learning steps, `hard` crescendo em vez de encolher,
  ease já ajustado na multiplicação, tetos de ease e intervalo
- Coluna `repetitions`, tabela `reviews` (local + remota) com sync de push
- Sessão só com cards vencidos, limite diário de novos, `again` reenfileirando
- Estudo livre como opção explícita; shuffle offline removido

### Conformidade e robustez
- Exclusão de conta ponta a ponta (Edge Function + UI com dupla confirmação)
- Paginação com contagem exata no sync, eliminando a perda de dados

### Antes de rodar localmente

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Ao mexer em qualquer tabela Drift, os 4 passos do `AGENTS.md` são obrigatórios —
`migration_test.dart` falha se algum for esquecido.
