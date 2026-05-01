# AGENTS.md — Memora

Leia este arquivo por completo antes de escrever qualquer código.

## Projeto

Memora — plataforma de aprendizado personalizado com IA. Decks de flashcards, geração de cards via IA (texto/PDF), estudo com avaliação de desempenho, insights de IA por card e chat com agente configurável por deck.

**Plataformas:** Web, Android, iOS (Flutter) | **Backend:** Supabase | **IA:** DeepSeek-chat (fallback: Gemini 1.5 Flash)

## Stack

Flutter, go_router, flutter_riverpod, google_fonts (Inter), flutter_dotenv, flutter_tts, file_picker, pdfx, shimmer, drift, drift_flutter, shared_preferences (somente flag de onboarding), connectivity_plus, Supabase (Auth, Postgres, Storage, Edge Functions/Deno)

**Dev dependencies:** drift_dev, build_runner

## Estrutura de pastas

- `lib/core/constants/` — app_constants, route_constants, supabase_constants
- `lib/core/theme/` — app_theme, app_colors, app_typography, app_dimensions
- `lib/core/utils/` — responsive, validators, connectivity_service
- `lib/core/widgets/` — app_button, app_input, app_card, empty_state, error_state, loading_state, offline_banner
- `lib/core/database/` — app_database, app_database.g (gerado), tables/decks_table, tables/cards_table, daos/decks_dao, daos/cards_dao
- `lib/features/onboarding/` — onboarding_screen (PageView com 4 páginas), onboarding_page_model
- `lib/features/auth/` — auth_repository, login/register/forgot_password screens
- `lib/features/decks/` — deck_model, deck_repository, home_screen, deck_screen, deck_card, deck_form_modal
- `lib/features/cards/` — card_model, card_repository, card_list_item, card_form_modal
- `lib/features/generate/` — generate_repository, import_content_screen, review_cards_screen
- `lib/features/agent/` — agent_templates, agent_repository, chat_screen, agent_config_screen
- `lib/features/study/` — study_screen, card_rating_model, study_session_model, widgets/insight_screen
- `supabase/functions/` — generate-cards/index.ts, chat/index.ts

## Regras invioláveis

1. **Nunca hardcodar valores visuais** — usar `AppColors`, `AppTypography`, `AppDimensions`
2. **Nunca hardcodar strings** — usar `RouteConstants` e `SupabaseConstants`
3. **Toda tela com dados do Supabase deve ter 3 estados:** loading → error → data
4. **Responsividade obrigatória** — conteúdo centralizado com `maxWidth: kContentMaxWidth` acima de 640px; usar `Responsive.isMobile/isTablet/isDesktop`
5. **Inputs com `fontSize: 16`** (evita zoom no iOS)
6. **Touch targets mínimos de 48px**
7. **Widgets > 100 linhas** → extrair para `widgets/` da feature
8. **Offline-first:** toda escrita vai primeiro no banco Drift local; sync com Supabase é secundário. Nunca bloquear UX por falta de rede.
9. **Nunca gerar código Drift manualmente** — usar `flutter pub run build_runner build` para gerar os arquivos `.g.dart`.

## Constantes

| Constante | Valor |
|---|---|
| `kMaxTextInput` | 4000 |
| `kMaxPdfSizeMb` | 5 |
| `kMaxPdfPages` | 10 |
| `kCardQuantityOptions` | [5, 10, 15] |
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

## Banco de dados

**decks:** id uuid PK, user_id FK→auth.users, title NOT NULL, description, agent_name DEFAULT 'Tutor', agent_prompt, agent_template DEFAULT 'general', agent_language DEFAULT 'português', agent_level DEFAULT 'intermediário', created_at, updated_at

**cards:** id uuid PK, deck_id FK→decks(cascade), front NOT NULL, back NOT NULL, ease_factor REAL DEFAULT 2.5, interval_days INT DEFAULT 1, due_date DATE DEFAULT now(), created_at, updated_at

**chat_messages:** id uuid PK, deck_id FK→decks(cascade), user_id FK→auth.users(cascade), role CHECK('user'|'assistant'), content NOT NULL, created_at

**RLS ativo em todas as tabelas.** Acesso restrito a `user_id = auth.uid()`. Para cards/chat_messages, via join com decks. Nunca desativar RLS.

## Edge Functions

**generate-cards:** entrada `{text, quantity, deckId}` | validações: text 100-4000 chars, quantity [5,10,15], JWT válido | saída `{cards: [{front, back}]}` ou `{error}`

**chat:** entrada `{deckId, messages, userMessage}` | busca deck + últimos 20 cards → substitui `{name}`, `{deck_title}`, `{deck_context}`, `{language}`, `{level}` no agent_prompt → chama IA → retorna `{reply}`

**card-insight:** entrada `{front, back, deckId}` | busca configurações do agente do deck → gera explicação aprofundada sobre o card → retorna `{insight}`. Requer conectividade.

## Rotas

`/onboarding`, `/login`, `/register`, `/forgot-password`, `/home`, `/deck/:deckId`, `/deck/:deckId/study`, `/deck/:deckId/study/insight`, `/deck/:deckId/generate`, `/deck/:deckId/generate/review`, `/deck/:deckId/chat`, `/deck/:deckId/agent-config`

**Redirecionamento:**
- Primeiro acesso (sem flag `onboarding_complete`) → `/onboarding`
- Não autenticado → rota protegida → `/login`
- Autenticado → `/login` ou `/register` → `/home`

## Templates de agente

Definidos em `agent_templates.dart`: `general` (Tutor Geral), `english` (Professor de Inglês), `programming` (Mentor de Programação), `science` (Professor de Ciências), `exam` (Modo Exame), `custom` (Personalizado). Variáveis: `{name}`, `{deck_title}`, `{deck_context}`, `{language}`, `{level}`

## Comportamento por feature

- **Onboarding:** 4 páginas em PageView (proposta de valor + features); controlado por flag `kOnboardingKey` no `shared_preferences` (único uso de shared_preferences no app); skip disponível na página 1-3; último slide tem botão "Começar" → `/login`
- **Auth:** sessão persiste, erros legíveis, logout → `/login`
- **Decks:** lista atualiza via Stream do Drift (`watchAllDecks()`); sync com Supabase quando online; delete em cascade; grid 2 colunas ≥600px
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
  - Botão "Ver Insight" disponível após revelar o verso (requer conexão)
- **Insights:** tela separada (`/deck/:deckId/study/insight`) exibe análise aprofundada da IA sobre o card atual; mostra loading state, trata erro offline com mensagem clara; usa Edge Function `card-insight`

## Algoritmo de avaliação (offline-first, simplificado)

Não implementar SRS completo. Usar lógica simples baseada em 4 botões:

| Botão | Ação |
|---|---|
| **Não sei** | `interval_days = 1`, `ease_factor -= 0.2` (min 1.3) |
| **Difícil** | `interval_days = max(1, interval_days - 1)`, `ease_factor -= 0.15` |
| **Bom** | `interval_days = round(interval_days * ease_factor)` |
| **Fácil** | `interval_days = round(interval_days * ease_factor * 1.3)`, `ease_factor += 0.1` |

- `due_date = today + interval_days`
- Salvar no banco Drift local imediatamente via `cardsDao.updateProgress(cardId, easeFactor, intervalDays, dueDate)`
- Marcar o card com `syncPending = true` no Drift
- Sincronizar com Supabase (`cards.ease_factor`, `cards.interval_days`, `cards.due_date`) quando online; após sync, setar `syncPending = false`
- Colunas `ease_factor`, `interval_days`, `due_date` devem existir tanto na tabela Drift quanto na tabela Supabase `cards`

## Offline-first — Estratégia geral

| Dado | Armazenamento local | Sync |
|---|---|---|
| Decks | Drift (`decks` table) | Ao abrir app com conexão |
| Cards | Drift (`cards` table) | Ao abrir deck com conexão |
| Progresso de estudo | Drift (`cards.syncPending = true`) | Background ao recuperar conexão |
| Onboarding flag | `shared_preferences` | Nunca (local only) |
| Chat messages | Não persiste offline | Online only |
| Insights | Não persiste offline | Online only |

## Banco Drift local — Schema

**DecksTable:** id (TEXT PK), userId (TEXT), title (TEXT), description (TEXT nullable), agentName (TEXT), agentPrompt (TEXT nullable), agentTemplate (TEXT), agentLanguage (TEXT), agentLevel (TEXT), createdAt (INTEGER — epoch ms), updatedAt (INTEGER)

**CardsTable:** id (TEXT PK), deckId (TEXT — FK lógico para DecksTable), front (TEXT), back (TEXT), easeFactor (REAL DEFAULT 2.5), intervalDays (INTEGER DEFAULT 1), dueDate (INTEGER — epoch ms), syncPending (BOOLEAN DEFAULT false), createdAt (INTEGER), updatedAt (INTEGER)

**Regras do banco Drift:**
- Nunca modificar arquivos `.g.dart` manualmente
- Rodar `flutter pub run build_runner build --delete-conflicting-outputs` após qualquer alteração nas tabelas
- DAOs devem retornar `Stream<>` para listas (uso com `StreamBuilder` ou `ref.watch`)
- DAOs devem retornar `Future<>` para operações pontuais (insert, update, delete)

- Usar `connectivity_plus` exposto via `ConnectivityService` (Riverpod provider)
- Exibir `OfflineBanner` quando offline
- Funcionalidades que requerem rede (chat, insight, geração) mostram aviso claro e desabilitam o botão correspondente

## O que não fazer

- Não salve API keys no código Flutter (ficam nas Edge Functions)
- Não crie arquivos de tema fora de `core/theme/`
- Não use `BuildContext` fora da árvore de widgets
- Não chame Supabase diretamente nas telas — use repositórios
- Não crie providers globais para estado local de tela
- Não avance sem checkpoint aprovado pelo desenvolvedor
- Não bloqueie a tela de estudo por falta de conexão
- Não implemente SRS completo — usar o algoritmo simplificado dos 4 botões