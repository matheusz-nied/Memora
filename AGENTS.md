# AGENTS.md — Memora

Leia este arquivo por completo antes de escrever qualquer código.

## Projeto

Memora — plataforma de aprendizado personalizado com IA. Decks de flashcards, geração de cards via IA (texto/PDF), estudo com flashcards e chat com agente configurável por deck.

**Plataformas:** Web, Android, iOS (Flutter) | **Backend:** Supabase | **IA:** DeepSeek-chat (fallback: Gemini 1.5 Flash)

## Stack

Flutter, go_router, flutter_riverpod, google_fonts (Inter), flutter_dotenv, flutter_tts, file_picker, pdfx, shimmer, Supabase (Auth, Postgres, Storage, Edge Functions/Deno)

## Estrutura de pastas

- `lib/core/constants/` — app_constants, route_constants, supabase_constants
- `lib/core/theme/` — app_theme, app_colors, app_typography, app_dimensions
- `lib/core/utils/` — responsive, validators
- `lib/core/widgets/` — app_button, app_input, app_card, empty_state, error_state, loading_state
- `lib/features/auth/` — auth_repository, login/register/forgot_password screens
- `lib/features/decks/` — deck_model, deck_repository, home_screen, deck_screen, deck_card, deck_form_modal
- `lib/features/cards/` — card_model, card_repository, card_list_item, card_form_modal
- `lib/features/generate/` — generate_repository, import_content_screen, review_cards_screen
- `lib/features/agent/` — agent_templates, agent_repository, chat_screen, agent_config_screen
- `lib/features/study/` — study_screen
- `supabase/functions/` — generate-cards/index.ts, chat/index.ts

## Regras invioláveis

1. **Nunca hardcodar valores visuais** — usar `AppColors`, `AppTypography`, `AppDimensions`
2. **Nunca hardcodar strings** — usar `RouteConstants` e `SupabaseConstants`
3. **Toda tela com dados do Supabase deve ter 3 estados:** loading → error → data
4. **Responsividade obrigatória** — conteúdo centralizado com `maxWidth: kContentMaxWidth` acima de 640px; usar `Responsive.isMobile/isTablet/isDesktop`
5. **Inputs com `fontSize: 16`** (evita zoom no iOS)
6. **Touch targets mínimos de 48px**
7. **Widgets > 100 linhas** → extrair para `widgets/` da feature

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

**Cores:** primária `#6C63FF`, hover `#5A52E0`, light `#EEEDFE`, dark `#3C3489`. Neutros light/dark e semânticas (success, error, warning, info com respectivos Bg) definidos em `AppColors`.

**Tipografia (Inter):** displayLarge 32/700, headingLarge 22/600, headingMedium 18/600, bodyLarge 15/400, bodyMedium 14/400, bodySmall 13/400, labelMedium 14/500, labelSmall 11/500

**Dimensões:** xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32, huge=48. Raios: sm=8, md=12, lg=16, xl=20, full=999.

**Breakpoints:** mobile <600, tablet 600-1023, desktop ≥1024

## Banco de dados

**decks:** id uuid PK, user_id FK→auth.users, title NOT NULL, description, agent_name DEFAULT 'Tutor', agent_prompt, agent_template DEFAULT 'general', agent_language DEFAULT 'português', agent_level DEFAULT 'intermediário', created_at, updated_at

**cards:** id uuid PK, deck_id FK→decks(cascade), front NOT NULL, back NOT NULL, created_at, updated_at

**chat_messages:** id uuid PK, deck_id FK→decks(cascade), user_id FK→auth.users(cascade), role CHECK('user'|'assistant'), content NOT NULL, created_at

**RLS ativo em todas as tabelas.** Acesso restrito a `user_id = auth.uid()`. Para cards/chat_messages, via join com decks. Nunca desativar RLS.

## Edge Functions

**generate-cards:** entrada `{text, quantity, deckId}` | validações: text 100-4000 chars, quantity [5,10,15], JWT válido | saída `{cards: [{front, back}]}` ou `{error}`

**chat:** entrada `{deckId, messages, userMessage}` | busca deck + últimos 20 cards → substitui `{name}`, `{deck_title}`, `{deck_context}`, `{language}`, `{level}` no agent_prompt → chama IA → retorna `{reply}`

## Rotas

`/login`, `/register`, `/forgot-password`, `/home`, `/deck/:deckId`, `/deck/:deckId/study`, `/deck/:deckId/generate`, `/deck/:deckId/generate/review`, `/deck/:deckId/chat`, `/deck/:deckId/agent-config`

**Redirecionamento:** não autenticado → rota protegida → `/login` | autenticado → `/login` ou `/register` → `/home`

## Templates de agente

Definidos em `agent_templates.dart`: `general` (Tutor Geral), `english` (Professor de Inglês), `programming` (Mentor de Programação), `science` (Professor de Ciências), `exam` (Modo Exame), `custom` (Personalizado). Variáveis: `{name}`, `{deck_title}`, `{deck_context}`, `{language}`, `{level}`

## Comportamento por feature

- **Auth:** sessão persiste, erros legíveis, logout → `/login`
- **Decks:** lista real-time via Stream, delete em cascade, grid 2 colunas ≥600px
- **Geração:** cards só salvos após revisão; erros de PDF específicos
- **Chat:** máximo `kMaxChatMessages` por sessão, aviso + "Nova conversa" no limite, indicador de digitação
- **Estudo:** cards embaralhados, flip 350ms, TTS no idioma do agente, tela de conclusão

## O que não fazer

- Não salve API keys no código Flutter (ficam nas Edge Functions)
- Não crie arquivos de tema fora de `core/theme/`
- Não use `BuildContext` fora da árvore de widgets
- Não chame Supabase diretamente nas telas — use repositórios
- Não crie providers globais para estado local de tela
- Não avance sem checkpoint aprovado pelo desenvolvedor