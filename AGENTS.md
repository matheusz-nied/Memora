# AGENTS.md — Memora

Você é um desenvolvedor Flutter sênior. Vamos construir juntos o **Memora**, uma plataforma de aprendizado personalizado com IA. O usuário passa por um onboarding, cria decks de flashcards, gera cards com IA a partir de texto ou PDF, estuda os cards com auto-avaliação de desempenho, consulta insights de IA por card e conversa com um agente de IA configurável por deck para praticar qualquer tema — inglês, biologia, programação, etc.

O app funciona em **web, Android e iOS**. É totalmente responsivo e **offline-first** para a funcionalidade de estudo. Siga cada etapa com precisão. **Não avance para a próxima etapa sem minha confirmação explícita de que a atual está funcionando.**

## Projeto

Memora — plataforma de aprendizado personalizado com IA. Decks de flashcards, geração de cards via IA (texto/PDF), estudo com avaliação de desempenho, insights de IA por card e chat com agente configurável por deck.

**Plataformas:** Web, Android, iOS (Flutter) | **Backend:** nenhum — tudo no aparelho | **IA:** DeepSeek-chat, chamada direto do app com a chave do próprio usuário

## Referência visual

Existe um design inicial feito no Stitch em `memora_view_design/`, com imagens e HTML de cada view. As telas Flutter não precisam copiar o design literalmente, mas devem manter a direção visual, hierarquia, espaçamentos, componentes e intenção de UX dessa referência. Melhorias são permitidas quando deixarem a experiência mais consistente, responsiva, acessível ou alinhada ao design system do projeto.

## Stack

Flutter, go_router, flutter_riverpod, Inter empacotada nos assets, flutter_tts, file_picker, pdfx, shimmer, drift, drift_flutter, shared_preferences, connectivity_plus, http (chamada à DeepSeek), syncfusion_flutter_pdf (extração de texto de PDF no aparelho), url_launcher

**Não há SDK de nuvem.** O app não tem contas, não sincroniza e não fala com servidor nenhum além da API da DeepSeek. `test/architecture/backend_boundary_test.dart` falha se um SDK de nuvem voltar ao projeto.

**Dev dependencies:** drift_dev, build_runner

## Estrutura de pastas

- `lib/core/constants/` — app_constants, route_constants
- `lib/core/backend/` — gateway_providers, contracts/ai_gateway, contracts/pdf_text_gateway, models neutros, local/ com as implementações (DeepSeek e extrator de PDF)
- `lib/core/identity/` — device_user_id (o UUID do aparelho, criado no bootstrap)
- `lib/core/theme/` — app_theme, app_colors, app_typography, app_dimensions
- `lib/core/utils/` — responsive, validators, connectivity_service
- `lib/core/widgets/` — app_button, app_input, app_card, empty_state, error_state, loading_state, offline_banner
- `lib/core/database/` — app_database, app_database.g (gerado), tables/decks_table, tables/cards_table, daos/decks_dao, daos/cards_dao
- `lib/features/onboarding/` — onboarding_screen (PageView com 4 páginas), onboarding_page_model
- `lib/features/profile/` — profile_text (o perfil em si é a aba `ProfileTab`)
- `lib/features/decks/` — deck_model, deck_repository, home_screen, deck_screen, deck_card, deck_form_modal
- `lib/features/cards/` — card_model, card_repository, card_list_item, card_form_modal
- `lib/features/generate/` — generate_repository, import_content_screen, review_cards_screen
- `lib/features/agent/` — agent_templates, agent_repository, chat_screen, agent_config_screen
- `lib/features/study/` — study_screen, card_rating_model, study_session_model, widgets/insight_widget
- `lib/features/backup/` — backup_repository, backup_data, backup_screen (exportar/importar JSON)

## Regras invioláveis

1. **Nunca hardcodar valores visuais** — usar `AppColors`, `AppTypography`, `AppDimensions`
2. **Nunca hardcodar strings** — usar `RouteConstants` e as classes de texto por feature
3. **Toda tela com dados remotos deve ter 3 estados:** loading → error → data
4. **Responsividade obrigatória** — conteúdo centralizado com `maxWidth: kContentMaxWidth` acima de 640px; usar `Responsive.isMobile/isTablet/isDesktop`
5. **Inputs com `fontSize: 16`** (evita zoom no iOS)
6. **Touch targets mínimos de 48px**
7. **Widgets > 100 linhas** → extrair para `widgets/` da feature
8. **Local-first:** o Drift é a fonte da verdade, não um cache. Nunca bloquear UX por falta de rede — só as três funções de IA (gerar cards, chat, insight) precisam dela, e cada uma avisa por conta própria.
9. **Nunca gerar código Drift manualmente** — usar `dart run build_runner build --delete-conflicting-outputs` para gerar os arquivos `.g.dart`. Os `.g.dart` de `lib/core/database/` são versionados e a CI falha se estiverem desatualizados.
9a. **Toda mudança de tabela Drift exige os 4 passos**, na ordem:
   1. incrementar `AppDatabase.latestSchemaVersion`
   2. adicionar o passo incremental em `AppDatabase.migration.onUpgrade`
   3. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
   4. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift/generated/`

   `test/core/database/migration_test.dart` falha se algum passo for esquecido. A partir do primeiro build distribuído, pular isso corrompe o banco de quem já instalou. Cada passo em `onUpgrade` é guardado por `from` **e** `to`: sem o `to`, uma migração 1→2 roda também os passos seguintes.
10. **Serviço externo desacoplado:** nenhuma tela, widget ou repository de feature conhece a DeepSeek. Só `lib/core/backend/local/` implementa os contratos, e só `gateway_providers.dart` escolhe a implementação ativa. `test/architecture/backend_boundary_test.dart` falha se a regra for violada, então ela se sustenta sozinha.
11. **Sem nuvem:** o app não tem contas, sync, telemetria nem servidor. Voltar a depender de um backend é decisão de produto, não consequência de um import — o mesmo teste de arquitetura barra SDKs de nuvem.

## Serviços externos desacoplados

A DeepSeek é a implementação atual, não uma dependência direta do app. As features dependem de contratos internos:

```text
UI → Feature Repository → Core Backend Contracts → Gateway concreto → API externa
```

Contratos:
- `AiGateway` cobre gerar cards (em lotes), chat e insight
- `PdfTextGateway` cobre extrair texto de um PDF, a partir dos bytes

`aiGatewayProvider` e `pdfTextGatewayProvider`, em `lib/core/backend/gateway_providers.dart`, são o único ponto que escolhe a implementação. Telas, widgets, DAOs e repositories não devem saber qual fornecedor está em uso — é o que permite trocar a DeepSeek por outro provedor mexendo num arquivo.

Tudo o mais é local:

| | Onde vive |
|---|---|
| Identidade | UUID do aparelho (`DeviceUserId`), criado no bootstrap e guardado em `shared_preferences` |
| Decks, cards, revisões, conversas | Drift, no aparelho |
| Chave da IA | `shared_preferences`, cadastrada pelo usuário (`DeepSeekKeyNotifier`) |
| Sobrevivência a perder o aparelho | exportar/importar JSON (`BackupRepository`) |

O `userId` continua em `decks` mesmo sem contas: é ele que impede um backup importado de outra instalação de se misturar aos decks de quem importou.

## Constantes

| Constante | Valor |
|---|---|
| `kMinTextInput` | 50 |
| `kMaxTextInput` | 4000 |
| `kMaxPdfSizeMb` | 20 |
| `kMaxPdfPages` | 100 |
| `kCardQuantityOptions` | [5, 10, 15, 25, 50] |
| `kMaxCardsPerBatch` | 15 |
| `kChunkTargetChars` | 3500 |
| `kChunkMinChars` | 800 |
| `kMaxAvoidFronts` | 60 |
| `kMaxCardFront` | 300 |
| `kMaxCardBack` | 600 |
| `kMaxDeckTitle` | 60 |
| `kMaxDeckDescription` | 200 |
| `kMaxChatMessages` | 40 |
| `kContentMaxWidth` | 640.0 |
| `kOnboardingKey` | `'onboarding_complete'` |

**Cores:** primária `#135BEC`, hover `#0F4BB3`, light `#F6F6F8` (background), dark `#101622` (background-dark), surface dark `#1A212E`. Neutros light/dark e semânticas (success, error, warning, info com respectivos Bg) definidos em `AppColors` baseados no Tailwind Slate/Emerald.

**Tipografia (Inter):** displayLarge 32/800, headingLarge 24/700, headingMedium 18/600, bodyLarge 16/400, bodyMedium 14/500, bodySmall 12/500, labelMedium 14/600, labelSmall 10/500

**Dimensões:** xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32, huge=48. Raios: sm=8, md=12, lg=16, xl=20, 2xl=24, 3xl=32, full=999.

**Breakpoints:** mobile <600, tablet 600-1023, desktop ≥1024

## Chamadas de IA

Não há servidor no meio: o `DeepSeekAiGateway` fala direto com `https://api.deepseek.com/chat/completions`, com a chave que o usuário cadastrou. Os prompts vivem num lugar só, `lib/core/ai/deepseek_prompts.dart`.

**Nunca chamar a DeepSeek sem `max_tokens`** e sem teto no tamanho da entrada. O histórico de chat é limitado por `boundedChatHistory` antes de virar prompt.

**Geração de cards:** o gateway resolve **um lote**. Quem pede 25 ou 50 cards é o `GenerateRepository`, que quebra o pedido em lotes de no máximo `kMaxCardsPerBatch`, chama o gateway uma vez por lote e manda em `avoidFronts` as frentes já geradas para o lote seguinte não repeti-las. Um lote que falha não perde o que já saiu: o resultado é parcial e a tela mostra o que veio. Timeout de 90s para geração e 45s para chat e insight, com uma retentativa para falha de rede, 5xx e resposta ilegível — nunca para 401/402/429 nem para o próprio timeout.

**Extração de PDF:** roda no aparelho, num isolate (`LocalPdfTextGateway`). Limites: `kMaxPdfSizeMb`, `kMaxPdfPages`, mínimo de 50 chars extraídos. Códigos de erro distintos (`pdf_no_text`, `pdf_parse_failed`, `pdf_too_large`, `pdf_too_many_pages`) porque "não foi possível extrair texto" para todos os casos mandava o usuário procurar arquivo maior quando o problema era PDF escaneado. **Nunca rejeitar PDF por ter texto demais** — texto excedente é truncado. A extração acontece uma vez por PDF e alimenta todos os lotes.

**Insight:** gerado uma vez e salvo na coluna `insight` do card, para nunca mais ser pedido. Requer conexão.

**Sem quota.** Quem limita é o saldo da conta DeepSeek do usuário; o app não conta nem cobra nada.

## Rotas

`/onboarding`, `/home`, `/settings/api-key`, `/settings/backup`, `/deck/:deckId`, `/deck/:deckId/study`, `/deck/:deckId/card/:cardId/insight`, `/deck/:deckId/generate`, `/deck/:deckId/generate/review`, `/deck/:deckId/chat`, `/deck/:deckId/agent-config`

**Redirecionamento:** o onboarding é o único portão.
- Primeiro acesso (sem flag `onboarding_complete`) → `/onboarding`
- Onboarding concluído abrindo `/onboarding` → `/home`

Não há login: a identidade nasce no bootstrap e nunca some.

## Templates de agente

Definidos em `agent_templates.dart`: `general` (Tutor Geral), `english` (Professor de Inglês), `programming` (Mentor de Programação), `science` (Professor de Ciências), `exam` (Modo Exame), `custom` (Personalizado). Variáveis: `{name}`, `{deck_title}`, `{deck_context}`, `{language}`, `{level}`

## Comportamento por feature

- **Onboarding:** 4 páginas em PageView; controlado por flag `kOnboardingKey` no `shared_preferences`; skip disponível na página 1-3; o último slide leva ao cadastro da chave da DeepSeek, com saída ("Depois, quero só criar cards") — cadastrar a chave não pode ser obrigatório, porque criar e estudar cards à mão funciona sem IA nenhuma
- **Perfil:** é a terceira aba da home (`ProfileTab`), não uma rota. Mostra o que existe sem conta: quantos decks, se está online, a chave da IA, o backup e a política de privacidade
- **Decks:** lista atualiza via Stream do Drift (`watchAllDecks()`); delete por tombstone (`deletedAt`); grid 2 colunas ≥600px
- **Backup:** exportar/importar JSON. Existe porque não há nuvem: perder o aparelho apagaria meses de histórico. Importar **soma**, nunca apaga; em conflito de `id` vence o `updatedAt` mais recente, e a comparação enxerga tombstones para não ressuscitar o que foi apagado
- **Geração:** cards só salvos após revisão; erros de PDF específicos; requer conexão (aviso explícito offline)
- **Chat:** máximo `kMaxChatMessages` por sessão, aviso + "Nova conversa" no limite, indicador de digitação; requer conexão (aviso explícito offline)
- **Estudo (offline-first):**
  - Cards carregados do cache local se offline
  - Cards embaralhados por padrão; ordenados por `due_date` se online
  - Flip animado em 350ms
  - Após revelar o verso: botões de auto-avaliação (Não sei / Difícil / Bom / Fácil)
  - Avaliação salva localmente com algoritmo simplificado (ver abaixo)
  - TTS no idioma do agente do deck
  - Tela de conclusão com resumo (acertos, erros, cards a revisar)
  - **Insight inline:** após revelar o verso, a área de insight aparece na mesma tela (`insight_widget`)
    - Se `card.insight != null` → exibe o insight imediatamente (sem chamada à IA)
    - Se `card.insight == null` → exibe botão "Gerar Insight" (desabilitado com tooltip se offline)
    - Ao gerar: mostra shimmer/loading → salva o insight na coluna `insight` do card → exibe o conteúdo
    - O insight gerado persiste para sempre; o usuário nunca precisa gerá-lo novamente
- **Insights:** exibidos inline na tela de resposta do flashcard via `insight_widget.dart`; sem rota separada; persistidos na coluna `insight` do card

## Algoritmo de avaliação (offline-first, simplificado)

Não implementar SRS completo. Usar lógica simples baseada em 4 botões:

| Botão | Ação |
|---|---|
| **Não sei** | `interval_days = 1`, `ease_factor -= 0.2` (min 1.3) |
| **Difícil** | `interval_days = max(1, interval_days - 1)`, `ease_factor -= 0.15` |
| **Bom** | `interval_days = round(interval_days * ease_factor)` |
| **Fácil** | `interval_days = round(interval_days * ease_factor * 1.3)`, `ease_factor += 0.1` |

- `due_date = today + interval_days`
- Salvar no Drift imediatamente via `cardsDao.updateProgress(...)`
- A revisão vai para `reviews` na **mesma transação** do card: sem isso o histórico diverge do agendamento se o app morrer entre as duas escritas

## Onde cada dado vive

Tudo no aparelho. Não há sync: o Drift é a fonte da verdade, não um cache.

| Dado | Armazenamento |
|---|---|
| Decks, cards | Drift (`decks`, `cards`) |
| Histórico de estudo | Drift (`reviews`), append-only |
| Conversas com o agente | Drift (`chat_messages`) |
| Insights gerados | Drift (`cards.insight`) — gerado uma vez, persiste para sempre |
| Identidade do aparelho | `shared_preferences` (`local_user_id`) |
| Chave da DeepSeek | `shared_preferences` (`deepseek_api_key`), em texto plano |
| Flag de onboarding, consentimento, lembrete de backup | `shared_preferences` |
| Cópia fora do aparelho | só o JSON que o usuário exportar |

## Banco Drift local — Schema

**DecksTable:** id (TEXT PK), userId (TEXT), title (TEXT), description (TEXT nullable), agentName (TEXT), agentPrompt (TEXT nullable), agentTemplate (TEXT), agentLanguage (TEXT), agentLevel (TEXT), createdAt (INTEGER — epoch ms), updatedAt (INTEGER)

**CardsTable:** id (TEXT PK), deckId (TEXT — FK lógico para DecksTable), front (TEXT), back (TEXT), easeFactor (REAL DEFAULT 2.5), intervalDays (INTEGER DEFAULT 1), repetitions (INTEGER DEFAULT 0), dueDate (INTEGER — epoch ms), insight (TEXT nullable), deletedAt (INTEGER nullable), createdAt (INTEGER), updatedAt (INTEGER)

**ReviewsTable:** id (TEXT PK), cardId (TEXT), deckId (TEXT), rating (INTEGER), easeBefore/easeAfter (REAL), intervalBefore/intervalAfter (INTEGER), reviewedAt (INTEGER). Append-only: reescrever uma revisão falsificaria o histórico.

**ChatMessagesTable:** id (TEXT PK), deckId (TEXT), role (TEXT — `user` ou `assistant`), content (TEXT), createdAt (INTEGER). Some junto com o deck, sem tombstone: o backup não exporta conversa.

`deletedAt` em `decks` e `cards` é soft-delete de verdade, não resto de sync: é ele que impede um backup antigo de ressuscitar o que o usuário apagou depois de exportar.

**Regras do banco Drift:**
- Nunca modificar arquivos `.g.dart` manualmente
- Rodar `flutter pub run build_runner build --delete-conflicting-outputs` após qualquer alteração nas tabelas
- DAOs devem retornar `Stream<>` para listas (uso com `StreamBuilder` ou `ref.watch`)
- DAOs devem retornar `Future<>` para operações pontuais (insert, update, delete)

- Usar `connectivity_plus` exposto via `ConnectivityService` (Riverpod provider)
- Exibir `OfflineBanner` quando offline
- Funcionalidades que requerem rede (chat, geração de cards, gerar insight) mostram aviso claro e desabilitam o botão correspondente
- O botão "Gerar Insight" fica desabilitado com tooltip se offline; se o insight já foi gerado, é exibido normalmente mesmo offline

## O que não fazer

- Não coloque API key no código nem em asset: a única chave que existe é a da DeepSeek, cadastrada pelo usuário e guardada em `shared_preferences`
- Não crie arquivos de tema fora de `core/theme/`
- Não use `BuildContext` fora da árvore de widgets
- Não chame SDK de backend diretamente nas telas — use repositórios
- Não traga SDK de nuvem, telemetria ou analytics de volta — o teste de arquitetura barra, e a política de privacidade promete o contrário
- Não crie providers globais para estado local de tela
- Não avance sem checkpoint aprovado pelo desenvolvedor
- Não bloqueie a tela de estudo por falta de conexão
- Não implemente SRS completo — usar o algoritmo simplificado dos 4 botões
