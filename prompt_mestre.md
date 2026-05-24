# Memora — Prompt Mestre

Você é um desenvolvedor Flutter sênior. Vamos construir juntos o **Memora**, uma plataforma de aprendizado personalizado com IA. O usuário passa por um onboarding, cria decks de flashcards, gera cards com IA a partir de texto ou PDF, estuda os cards com auto-avaliação de desempenho, consulta insights de IA por card e conversa com um agente de IA configurável por deck para praticar qualquer tema — inglês, biologia, programação, etc.

O app funciona em **web, Android e iOS**. É totalmente responsivo e **offline-first** para a funcionalidade de estudo. Siga cada etapa com precisão. **Não avance para a próxima etapa sem minha confirmação explícita de que a atual está funcionando.**

---

## Etapas de Execução

### Concluído: Etapa 1 — Base do projeto

Implementar a base técnica do app seguindo as seções:
- [Stack Tecnológica](#stack-tecnológica)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Padrão de Código](#padrão-de-código)

Checkpoint: validar que o projeto Flutter está estruturado, dependências configuradas e padrões globais respeitados antes de avançar.

### Concluído: Etapa 2 — Constantes, tema e responsividade

Implementar constantes, rotas, design system e helpers responsivos seguindo as seções:
- [Constantes Globais](#constantes-globais)
- [Tema e Design System](#tema-e-design-system)
- [Rotas](#rotas)

Checkpoint: validar que cores, tipografia, dimensões, rotas, tabelas e buckets usam constantes, sem valores hardcodados.

### Concluído: Etapa 3 — Banco de dados e offline-first

Implementar a camada de backend desacoplada, Supabase como implementação remota inicial, Drift local, schemas, DAOs, RLS e estratégia de sincronização seguindo as seções:
- [Backend Desacoplado](#backend-desacoplado)
- [Banco de Dados](#banco-de-dados)
- [Offline-first — Estratégia Geral](#offline-first--estratégia-geral)

Checkpoint: validar contratos de backend, provider central, tabelas, banco local, geração Drift e sincronização base antes de avançar.

### Concluído: Etapa 4 — Onboarding, autenticação e redirecionamento

Implementar fluxo inicial, autenticação e regras de navegação seguindo as seções:
- [Rotas](#rotas)
- [Onboarding](#onboarding)
- [Auth](#auth)

Checkpoint: validar primeiro acesso, flag de onboarding, login, cadastro, recuperação de senha, persistência de sessão e redirects.

### Concluído: Etapa 5 — Decks e cards

Implementar listagem, criação, edição, exclusão, cache local e sync de decks/cards seguindo as seções:
- [Decks](#decks)
- [Banco de Dados](#banco-de-dados)
- [Offline-first — Estratégia Geral](#offline-first--estratégia-geral)

Checkpoint: validar streams Drift, sync via backend remoto quando online, delete em cascade e responsividade da grid.

### Concluído: Etapa 6 — Geração de cards com IA

Implementar importação de texto/PDF, revisão de cards e geração via `AiGateway` seguindo as seções:
- [Geração de Cards](#geração-de-cards)
- [Edge Functions — implementação inicial do AiGateway](#edge-functions--implementação-inicial-do-aigateway)

Checkpoint: validar geração online, erros específicos de PDF, revisão antes de salvar e bloqueio adequado quando offline.

### Concluído: Etapa 7 — Estudo offline-first

Implementar modo estudo, flip, TTS, avaliação, progresso local e sync em background seguindo as seções:
- [Estudo (offline-first)](#estudo-offline-first)
- [Algoritmo de avaliação (simplificado)](#algoritmo-de-avaliação-simplificado)
- [Offline-first — Estratégia Geral](#offline-first--estratégia-geral)

Checkpoint: validar estudo funcionando offline, cálculo dos 4 botões, persistência local imediata e sync posterior.

### Concluido: Etapa 8 — Insights de IA inline

Implementar insight persistente por card e geração via `AiGateway` seguindo as seções:
- [Insights de IA (inline, persistentes)](#insights-de-ia-inline-persistentes)
- [Edge Functions — implementação inicial do AiGateway](#edge-functions--implementação-inicial-do-aigateway)

Checkpoint: validar que insight já salvo aparece offline, insight novo exige conexão, salva em Drift + backend remoto e nunca é gerado novamente para o mesmo card.

### Concluido: Etapa 9 — Chat e agente configurável

Implementar templates, configuração do agente, chat online e envio via `AiGateway` seguindo as seções:
- [Templates de Agente](#templates-de-agente)
- [Chat](#chat)
- [Edge Functions — implementação inicial do AiGateway](#edge-functions--implementação-inicial-do-aigateway)

Checkpoint: validar interpolação de variáveis, limite de mensagens, indicador de digitação, nova conversa e bloqueio quando offline.

### Etapa 10 — Revisão final

Revisar todo o app contra:
- [Padrão de Código](#padrão-de-código)
- [Offline-first — Estratégia Geral](#offline-first--estratégia-geral)
- [Comportamento por Feature](#comportamento-por-feature)

Checkpoint: validar loading/error/data, responsividade, touch targets, inputs com fonte 16, ausência de secrets no Flutter, ausência de imports diretos do SDK de backend fora da infraestrutura e geração correta dos arquivos Drift.

---

## Stack Tecnológica

### Frontend

| Tecnologia | Uso |
|---|---|
| Flutter (web + Android + iOS) | Framework principal |
| `go_router` | Roteamento declarativo |
| `flutter_riverpod` | Gerenciamento de estado |
| `google_fonts` | Tipografia (Inter) |
| `flutter_dotenv` | Variáveis de ambiente |
| `flutter_tts` | Text-to-speech (modo estudo) |
| `file_picker` | Upload de PDF |
| `pdfx` | Extração de texto de PDF |
| `shimmer` | Loading states |
| `drift` + `drift_flutter` | Banco SQLite local type-safe (offline-first) |
| `shared_preferences` | Somente flag de onboarding |
| `connectivity_plus` | Detecção de estado de rede |

**Dev dependencies:** `drift_dev`, `build_runner`

### Backend remoto inicial

| Tecnologia | Uso |
|---|---|
| Supabase Auth | Implementação inicial de autenticação por trás de `AuthGateway` |
| Supabase Postgres | Implementação inicial do banco remoto por trás de `RemoteDatabaseGateway` |
| Supabase Storage | Implementação inicial de armazenamento por trás de `StorageGateway` |
| Supabase Edge Functions (Deno) | Implementação inicial de IA por trás de `AiGateway` |

> Supabase é a infraestrutura remota inicial, não uma dependência direta das telas ou features. O app Flutter depende de contratos internos em `core/backend/`. Para trocar por backend próprio no futuro, substituir a implementação fornecida pelo provider/factory central de `BackendClient`.

### IA

| Modelo | Uso |
|---|---|
| DeepSeek-chat | Geração de cards, chat e insights |
| Gemini 1.5 Flash | Fallback |

---

## Estrutura de Pastas

```
lib/
├── main.dart
├── app.dart                        ← MaterialApp + GoRouter
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      ← limites, configs globais
│   │   ├── route_constants.dart    ← nomes das rotas
│   │   └── backend_constants.dart  ← nomes neutros de recursos remotos
│   ├── backend/
│   │   ├── backend_client.dart     ← contrato agregado do backend remoto
│   │   ├── backend_provider.dart   ← provider/factory central de BackendClient
│   │   ├── contracts/
│   │   │   ├── auth_gateway.dart
│   │   │   ├── remote_database_gateway.dart
│   │   │   ├── storage_gateway.dart
│   │   │   └── ai_gateway.dart
│   │   ├── models/                ← DTOs remotos neutros
│   │   └── supabase/              ← implementação inicial com Supabase SDK
│   │       ├── supabase_backend_client.dart
│   │       ├── supabase_auth_gateway.dart
│   │       ├── supabase_remote_database_gateway.dart
│   │       ├── supabase_storage_gateway.dart
│   │       ├── supabase_ai_gateway.dart
│   │       └── supabase_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart          ← ThemeData light e dark
│   │   ├── app_colors.dart         ← paleta de cores centralizada
│   │   ├── app_typography.dart     ← estilos de texto
│   │   └── app_dimensions.dart     ← espaçamentos e tamanhos
│   ├── utils/
│   │   ├── responsive.dart         ← helpers de breakpoint
│   │   ├── validators.dart         ← validações de formulário
│   │   └── connectivity_service.dart ← stream de estado de rede
│   └── widgets/
│       ├── app_button.dart         ← botão padrão reutilizável
│       ├── app_input.dart          ← input padrão reutilizável
│       ├── app_card.dart           ← card container reutilizável
│       ├── empty_state.dart        ← widget de estado vazio
│       ├── error_state.dart        ← widget de erro
│       ├── loading_state.dart      ← widget de loading
│       └── offline_banner.dart     ← banner de status offline
│
├── features/
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── onboarding_screen.dart   ← PageView com 4 páginas
│   │       └── widgets/
│   │           └── onboarding_page.dart ← widget de página individual
│   │
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── forgot_password_screen.dart
│   │
│   ├── decks/
│   │   ├── data/
│   │   │   ├── deck_model.dart
│   │   │   └── deck_repository.dart    ← cache local + sync remoto via contratos
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── deck_screen.dart
│   │       └── widgets/
│   │           ├── deck_card.dart
│   │           └── deck_form_modal.dart
│   │
│   ├── cards/
│   │   ├── data/
│   │   │   ├── card_model.dart         ← inclui ease_factor, interval_days, due_date
│   │   │   └── card_repository.dart    ← cache local + sync remoto via contratos
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── card_list_item.dart
│   │           └── card_form_modal.dart
│   │
│   ├── generate/
│   │   ├── data/
│   │   │   └── generate_repository.dart
│   │   └── presentation/
│   │       ├── import_content_screen.dart
│   │       └── review_cards_screen.dart
│   │
│   ├── agent/
│   │   ├── data/
│   │   │   ├── agent_templates.dart
│   │   │   └── agent_repository.dart
│   │   └── presentation/
│   │       ├── chat_screen.dart
│   │       └── agent_config_screen.dart
│   │
│   └── study/
│       ├── data/
│       │   ├── card_rating_model.dart   ← enum: doesNotKnow, hard, good, easy
│       │   ├── study_session_model.dart ← progresso da sessão atual
│       │   └── study_repository.dart   ← lógica offline de rating + sync
│       └── presentation/
│           ├── study_screen.dart
│           ├── insight_widget.dart     ← widget inline de insight (na tela de resposta)
│           └── widgets/
│               ├── study_card_widget.dart  ← card com flip animado
│               └── rating_buttons.dart    ← Não sei / Difícil / Bom / Fácil
│
supabase/
└── functions/
    ├── generate-cards/
    │   └── index.ts
    ├── chat/
    │   └── index.ts
    └── card-insight/
        └── index.ts
```

---

## Backend Desacoplado

O Flutter nunca deve depender diretamente do Supabase fora de `lib/core/backend/supabase/`. Supabase é apenas a implementação remota inicial. O restante do app usa contratos neutros e repositories de feature.

**Fluxo obrigatório:**

```text
UI
→ Feature Repository
→ Core Backend Contracts
→ BackendClient atual
→ SDK/API da infraestrutura remota
```

**Troca futura de backend:**

```text
UI
→ Feature Repository
→ Core Backend Contracts
→ CustomBackendClient
→ API própria
```

### Contratos mínimos

```dart
abstract interface class BackendClient {
  AuthGateway get auth;
  RemoteDatabaseGateway get database;
  StorageGateway get storage;
  AiGateway get ai;
}
```

```dart
abstract interface class AuthGateway {
  Stream<AuthSession?> watchSession();
  Future<AuthSession?> currentSession();
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
```

```dart
abstract interface class RemoteDatabaseGateway {
  Future<List<RemoteDeck>> fetchDecks();
  Future<void> upsertDeck(RemoteDeck deck);
  Future<void> deleteDeck(String deckId);

  Future<List<RemoteCard>> fetchCards(String deckId);
  Future<void> upsertCards(List<RemoteCard> cards);
  Future<void> updateCardProgress(CardProgressSyncPayload payload);
  Future<void> updateCardInsight(String cardId, String insight);
}
```

```dart
abstract interface class AiGateway {
  Future<List<GeneratedCardPayload>> generateCards(GenerateCardsRequest request);
  Future<String> sendChatMessage(ChatRequest request);
  Future<String> generateCardInsight(CardInsightRequest request);
}
```

```dart
abstract interface class StorageGateway {
  Future<StoredFile> uploadPdf(PdfUploadRequest request);
}
```

`backendClientProvider` é o único ponto que escolhe a implementação ativa. Inicialmente ele retorna `SupabaseBackendClient`. Para migrar para backend próprio, trocar esse provider/factory para retornar `CustomBackendClient`, mantendo telas, widgets, DAOs e repositories de feature sem saber qual infraestrutura remota está em uso.

---

## Rotas

| Rota | Tela |
|---|---|
| `/onboarding` | Onboarding (4 páginas) |
| `/login` | Login |
| `/register` | Cadastro |
| `/forgot-password` | Recuperar senha |
| `/home` | Home com lista de decks |
| `/deck/:deckId` | Tela do deck |
| `/deck/:deckId/study` | Modo estudo |
| `/deck/:deckId/study` | Modo estudo (inclui estado de resposta com insight inline) |
| `/deck/:deckId/generate` | Importar conteúdo |
| `/deck/:deckId/generate/review` | Revisar cards gerados |
| `/deck/:deckId/chat` | Chat com agente |
| `/deck/:deckId/agent-config` | Configurar agente |

**Redirecionamento:**
- Primeiro acesso (sem flag `kOnboardingKey` no SharedPreferences) → `/onboarding`
- Não autenticado acessando rota protegida → `/login`
- Autenticado acessando `/login` ou `/register` → `/home`

---

## Banco de Dados

As tabelas abaixo descrevem o schema remoto inicial no Supabase. O domínio do app e os repositories devem usar modelos neutros; Supabase Postgres é apenas o destino remoto atual do sync via `RemoteDatabaseGateway`.

### Tabela remota inicial: `decks`

| Coluna | Tipo | Flags |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → auth.users |
| `title` | text | NOT NULL |
| `description` | text | |
| `agent_name` | text | DEFAULT 'Tutor' |
| `agent_prompt` | text | |
| `agent_template` | text | DEFAULT 'general' |
| `agent_language` | text | DEFAULT 'português' |
| `agent_level` | text | DEFAULT 'intermediário' |
| `created_at` | timestamptz | DEFAULT now() |
| `updated_at` | timestamptz | DEFAULT now() |

### Tabela remota inicial: `cards`

| Coluna | Tipo | Flags |
|---|---|---|
| `id` | uuid | PK |
| `deck_id` | uuid | FK → decks (cascade) |
| `front` | text | NOT NULL |
| `back` | text | NOT NULL |
| `ease_factor` | real | DEFAULT 2.5 |
| `interval_days` | integer | DEFAULT 1 |
| `due_date` | date | DEFAULT now() |
| `insight` | text | nullable |
| `created_at` | timestamptz | DEFAULT now() |
| `updated_at` | timestamptz | DEFAULT now() |

### Banco Drift local — Schema

**DecksTable:** id (TEXT PK), userId (TEXT), title (TEXT), description (TEXT nullable), agentName (TEXT), agentPrompt (TEXT nullable), agentTemplate (TEXT), agentLanguage (TEXT), agentLevel (TEXT), createdAt (INTEGER — epoch ms), updatedAt (INTEGER)

**CardsTable:** id (TEXT PK), deckId (TEXT), front (TEXT), back (TEXT), easeFactor (REAL DEFAULT 2.5), intervalDays (INTEGER DEFAULT 1), dueDate (INTEGER — epoch ms), syncPending (BOOLEAN DEFAULT false), insight (TEXT nullable), createdAt (INTEGER), updatedAt (INTEGER)

> `syncPending = true` indica que o progresso de avaliação foi salvo localmente mas ainda não foi enviado ao backend remoto. O sync ocorre em background quando a conexão é restaurada. O campo `insight` é sincronizado para o backend remoto após a geração e nunca é apagado.

### Tabela remota inicial: `chat_messages`

| Coluna | Tipo | Flags |
|---|---|---|
| `id` | uuid | PK |
| `deck_id` | uuid | FK → decks |
| `user_id` | uuid | FK → auth.users |
| `role` | text | CHECK IN ('user', 'assistant') |
| `content` | text | NOT NULL |
| `created_at` | timestamptz | DEFAULT now() |

> **RLS:** Na implementação Supabase, todas as tabelas têm Row Level Security ativo. Acesso restrito a registros onde `user_id = auth.uid()`. Para `cards` e `chat_messages`, verificado via join com `decks`. Nunca desativar RLS nem criar políticas permissivas demais. Em backend próprio futuro, manter isolamento equivalente por usuário no servidor.

---

## Constantes Globais

### `app_constants.dart`

| Constante | Valor | Descrição |
|---|---|---|
| `kMaxTextInput` | 4000 | Limite de texto para geração |
| `kMaxPdfSizeMb` | 5 | Limite de PDF em MB |
| `kMaxPdfPages` | 10 | Limite de páginas do PDF |
| `kCardQuantityOptions` | [5, 10, 15] | Opções de quantidade de cards |
| `kMaxCardFront` | 300 | Limite da frente do card |
| `kMaxCardBack` | 600 | Limite do verso do card |
| `kMaxDeckTitle` | 60 | Limite do título do deck |
| `kMaxDeckDescription` | 200 | Limite da descrição do deck |
| `kMaxChatMessages` | 40 | Histórico máximo por sessão |
| `kContentMaxWidth` | 640.0 | Largura máxima do conteúdo web |
| `kOnboardingKey` | `'onboarding_complete'` | Flag de onboarding no SharedPreferences (único uso) |

### `backend_constants.dart`

| Constante | Valor |
|---|---|
| `kTableDecks` | `'decks'` |
| `kTableCards` | `'cards'` |
| `kTableChatMessages` | `'chat_messages'` |
| `kBucketPdfs` | `'pdfs'` |

> Constantes específicas do Supabase ficam em `lib/core/backend/supabase/supabase_constants.dart` e não devem ser importadas por telas, widgets ou repositories de feature.

### `route_constants.dart`

| Constante | Valor |
|---|---|
| `kRouteOnboarding` | `'/onboarding'` |
| `kRouteLogin` | `'/login'` |
| `kRouteRegister` | `'/register'` |
| `kRouteForgotPass` | `'/forgot-password'` |
| `kRouteHome` | `'/home'` |
| `kRouteDeck` | `'/deck/:deckId'` |
| `kRouteStudy` | `'/deck/:deckId/study'` |
| `kRouteGenerate` | `'/deck/:deckId/generate'` |
| `kRouteReview` | `'/deck/:deckId/generate/review'` |
| `kRouteChat` | `'/deck/:deckId/chat'` |
| `kRouteAgentConfig` | `'/deck/:deckId/agent-config'` |

---

## Tema e Design System

### `app_colors.dart` — todas as cores como `static const`

**Primária (Azul)**

| Nome | Valor |
|---|---|
| `primary` | `Color(0xFF135BEC)` |
| `primaryHover` | `Color(0xFF0F4BB3)` |
| `primaryLight` | `Color(0xFFD0E1FB)` |
| `primaryDark` | `Color(0xFF07245E)` |

**Neutros Light**

| Nome | Valor |
|---|---|
| `background` | `Color(0xFFF6F6F8)` |
| `surface` | `Color(0xFFFFFFFF)` |
| `border` | `Color(0xFFE2E8F0)` |
| `textPrimary` | `Color(0xFF0F172A)` |
| `textSecondary` | `Color(0xFF64748B)` |
| `textTertiary` | `Color(0xFF94A3B8)` |

**Neutros Dark**

| Nome | Valor |
|---|---|
| `backgroundDark` | `Color(0xFF101622)` |
| `surfaceDark` | `Color(0xFF1A212E)` |
| `borderDark` | `Color(0xFF1E293B)` |
| `textPrimaryDark` | `Color(0xFFFFFFFF)` |
| `textSecDark` | `Color(0xFF94A3B8)` |
| `textTertDark` | `Color(0xFF64748B)` |

**Semânticas**

| Nome | Valor | Fundo |
|---|---|---|
| `success` | `Color(0xFF10B981)` | `successBg` → `Color(0xFFECFDF5)` |
| `error` | `Color(0xFFEF4444)` | `errorBg` → `Color(0xFFFEF2F2)` |
| `warning` | `Color(0xFFF59E0B)` | `warningBg` → `Color(0xFFFFFBEB)` |
| `info` | `Color(0xFF135BEC)` | `infoBg` → `Color(0xFFEFF6FF)` |

### `app_typography.dart` — TextStyles centralizados

| Estilo | Fonte | Tamanho | Peso |
|---|---|---|---|
| `displayLarge` | Inter | 32px | w800 |
| `headingLarge` | Inter | 24px | w700 |
| `headingMedium` | Inter | 18px | w600 |
| `bodyLarge` | Inter | 16px | w400 |
| `bodyMedium` | Inter | 14px | w500 |
| `bodySmall` | Inter | 12px | w500 |
| `labelMedium` | Inter | 14px | w600 |
| `labelSmall` | Inter | 10px | w500 |

### `app_dimensions.dart` — constantes de espaçamento

| Constante | Valor |
|---|---|
| `xs` | 4.0 |
| `sm` | 8.0 |
| `md` | 12.0 |
| `lg` | 16.0 |
| `xl` | 20.0 |
| `xxl` | 24.0 |
| `xxxl` | 32.0 |
| `huge` | 48.0 |
| `radiusSm` | 8.0 |
| `radiusMd` | 12.0 |
| `radiusLg` | 16.0 |
| `radiusXl` | 20.0 |
| `radius2Xl` | 24.0 |
| `radius3Xl` | 32.0 |
| `radiusFull` | 999.0 |

### `responsive.dart` — helpers de breakpoint

| Helper | Condição |
|---|---|
| `isMobile(context)` | largura < 600px |
| `isTablet(context)` | 600px ≤ largura < 1024px |
| `isDesktop(context)` | largura ≥ 1024px |
| `contentPadding(context)` | 16px mobile / 24px tablet / 32px desktop |

---

## Edge Functions — implementação inicial do AiGateway

As Edge Functions abaixo são a implementação inicial do `AiGateway` no adaptador Supabase. Telas e repositories de feature não chamam Edge Functions diretamente; eles chamam `AiGateway`.

### `generate-cards`

**Entrada:**

```json
{
  "text": "string",
  "quantity": 5,
  "deckId": "uuid"
}
```

**Validações:**
- `text`: entre 100 e 4000 caracteres
- `quantity`: pertence a `[5, 10, 15]`
- JWT válido no header `Authorization`

**Saída (sucesso):**

```json
{
  "cards": [
    { "front": "string", "back": "string" }
  ]
}
```

**Saída (erro):**

```json
{
  "error": "string"
}
```

### `chat`

**Entrada:**

```json
{
  "deckId": "uuid",
  "messages": [
    { "role": "user" | "assistant", "content": "string" }
  ],
  "userMessage": "string"
}
```

**Processo:**
1. Buscar deck pelo `deckId`
2. Buscar últimos 20 cards do deck para contexto
3. Substituir variáveis no `agent_prompt`: `{name}`, `{deck_title}`, `{deck_context}`, `{language}`, `{level}`
4. Chamar a IA com system + histórico + nova mensagem
5. Retornar `{ "reply": "string" }`

### `card-insight`

**Entrada:**

```json
{
  "front": "string",
  "back": "string",
  "deckId": "uuid"
}
```

**Processo:**
1. Buscar deck pelo `deckId` para obter configurações do agente (idioma, nível, contexto)
2. Montar prompt: "Explique de forma aprofundada o seguinte flashcard, trazendo exemplos, contexto histórico, dicas de memorização e conexões com outros conceitos. Idioma: {language}. Nível: {level}. Frente: {front}. Verso: {back}."
3. Chamar IA e retornar `{ "insight": "string" }`

**Saída (erro):**

```json
{
  "error": "string"
}
```

---

## Templates de Agente

| Chave | Nome | Descrição |
|---|---|---|
| `general` | Tutor Geral | Reforça conteúdo com perguntas |
| `english` | Professor de Inglês | Pratica inglês e corrige erros |
| `programming` | Mentor de Programação | Revisa código e explica conceitos |
| `science` | Professor de Ciências | Usa analogias e método socrático |
| `exam` | Modo Exame | Simula prova oral sem dar dicas |
| `custom` | Personalizado | Prompt livre definido pelo usuário |

**Variáveis interpoláveis no prompt:**

| Variável | Substituição |
|---|---|
| `{name}` | Nome do agente configurado |
| `{deck_title}` | Título do deck |
| `{deck_context}` | Cards do deck em formato texto |
| `{language}` | Idioma de resposta |
| `{level}` | Nível de dificuldade |

---

## Comportamento por Feature

### Onboarding

- 4 páginas em `PageView` com indicador de progresso (dots)
- Conteúdo sugerido: (1) Boas-vindas + proposta de valor, (2) Crie seus decks, (3) Estude com IA, (4) Converse com seu tutor
- Botão "Pular" disponível nas páginas 1–3
- Última página tem botão "Começar" → salva `kOnboardingKey = true` no SharedPreferences → navega para `/login`
- Não exibido após o primeiro acesso completo

### Auth
- Sessão persiste após fechar o app
- Erros de auth exibem mensagem legível (não o erro raw)
- Logout redireciona imediatamente para `/login`
- Não autenticado acessando rota protegida → `/login`
- Autenticado acessando `/login` ou `/register` → `/home`

### Decks
- Lista atualiza via `Stream` do Drift (`decksDao.watchAllDecks()`)
- Ao abrir o app com conexão: busca decks via `RemoteDatabaseGateway` e faz upsert no banco Drift local
- Deletar deck apaga cards locais via `cardsDao.deleteByDeckId(deckId)` antes de deletar no backend remoto
- Grid 2 colunas em telas ≥ 600px

### Geração de Cards
- Nenhum card é salvo antes da revisão do usuário
- O usuário pode editar, remover e adicionar cards na revisão
- Erros de PDF exibem mensagem específica (protegido, escaneado, muito grande, poucas páginas, texto insuficiente)
- Requer conexão — exibir aviso e desabilitar botão quando offline

### Chat
- Histórico máximo de `kMaxChatMessages` (40) por sessão
- Ao atingir o limite: aviso + botão "Nova conversa"
- Indicador de digitação durante loading da resposta
- Mensagens salvas no backend remoto após cada troca
- Requer conexão — exibir aviso e desabilitar input quando offline

### Estudo (offline-first)

- Cards carregados via `cardsDao.watchCardsByDeck(deckId)` (Drift Stream — funciona offline)
- Ao abrir o deck com conexão: sync backend remoto → Drift em background
- Cards ordenados por `dueDate` (Drift); embaralhados se offline e sem dados locais
- Flip animado em 350ms ao tocar no card
- Após revelar o verso, exibir:
  - Botões de auto-avaliação: **Não sei** / **Difícil** / **Bom** / **Fácil**
  - Botão **"Ver Insight"** (desabilitado com tooltip se offline)
- Avaliação calculada localmente → `cardsDao.updateProgress(id, easeFactor, intervalDays, dueDate)` → `syncPending = true`
- Sync com backend remoto em background quando online → `syncPending = false` após confirmação
- TTS usa o idioma do agente do deck
- Tela de conclusão com: total de cards estudados, quantos "Não sei", "Difícil", "Bom" e "Fácil", e próxima data de revisão estimada
- Botão "Estudar novamente" na tela de conclusão

#### Algoritmo de avaliação (simplificado)

| Botão | Ação sobre `interval_days` | Ação sobre `ease_factor` |
|---|---|---|
| **Não sei** | `= 1` | `-= 0.2` (mínimo 1.3) |
| **Difícil** | `= max(1, interval_days - 1)` | `-= 0.15` |
| **Bom** | `= round(interval_days * ease_factor)` | sem alteração |
| **Fácil** | `= round(interval_days * ease_factor * 1.3)` | `+= 0.1` |

`due_date = hoje + interval_days`

### Insights de IA (inline, persistentes)

- Exibidos na **mesma tela de resposta** do flashcard via `insight_widget.dart` (sem navegação separada)
- Comportamento baseado no campo `card.insight`:
  - **`insight != null`** → exibe o conteúdo imediatamente, sem nenhuma chamada à IA
  - **`insight == null`** → exibe botão "Gerar Insight"
    - Se offline: botão desabilitado com `Tooltip('Requer conexão com a internet')`
    - Se online: ao clicar, exibe shimmer/loading → chama `AiGateway.generateCardInsight` → salva o texto retornado em `cards.insight` no Drift (local) e faz sync para o backend remoto → exibe o insight
- O insight é permanente: uma vez gerado, está disponível para sempre, inclusive offline
- O usuário nunca é forçado a gerar o insight; é opt-in
- Usa `AiGateway.generateCardInsight`; na implementação inicial, o adaptador Supabase chama a Edge Function `card-insight`

---

## Offline-first — Estratégia Geral

| Dado | Armazenamento local | Sincronização |
|---|---|---|
| Decks | Drift `decks` table | Ao abrir app com conexão |
| Cards | Drift `cards` table | Ao abrir deck com conexão |
| Progresso de estudo | Drift `cards.syncPending = true` | Background ao recuperar conexão |
| Onboarding flag | `shared_preferences` (único uso) | Nunca (local only) |
| Chat messages | Não persistido | Online only |
| Insights gerados | Drift `cards.insight` + backend remoto | Gerado uma vez, persiste para sempre |

- `connectivity_plus` exposto via `ConnectivityService` (singleton Riverpod provider)
- `offline_banner.dart`: widget global exibido no topo quando offline
- Funcionalidades que requerem rede: botão desabilitado + `Tooltip('Requer conexão com a internet')`

---

## Padrão de Código

1. **Sempre usar constantes** de cores, tipografia e dimensões. Nunca hardcodar valores visuais diretamente nos widgets.

2. **Toda tela deve ter três estados:** `loading` → `error` → `data`.

3. **Toda operação assíncrona** usa `AsyncValue` do Riverpod.

4. **Repositórios** retornam `Either<Failure, T>` ou lançam exceções tipadas.

5. **Widgets com mais de 100 linhas** devem ser quebrados em widgets menores dentro da pasta `widgets/` da feature.

6. **Responsividade obrigatória:** Em telas web (largura > 640px), o conteúdo fica centralizado:

   ```dart
   Center(
     child: ConstrainedBox(
       constraints: BoxConstraints(maxWidth: kContentMaxWidth),
       child: content,
     ),
   )
   ```

7. **Inputs sempre com `fontSize: 16`** para evitar zoom automático no iOS.

8. **Touch targets mínimos de 48px** em botões, ícones clicáveis e itens de lista.

9. **Nunca hardcodar strings** de rotas, recursos remotos, tabelas ou buckets — usar `route_constants.dart` e `backend_constants.dart`. Constantes Supabase-specific só podem existir dentro de `core/backend/supabase/`.

10. **Nunca salve segredos** (API keys) no código Flutter. As chaves ficam apenas no backend remoto ou nas Edge Functions da implementação Supabase.

11. **Não use `BuildContext`** fora da árvore de widgets.

12. **Não faça chamadas ao SDK de backend diretamente nas telas.** Telas usam repositories; repositories usam contratos de `core/backend/`.

13. **Não crie providers globais** para estado local de tela.

14. **Offline-first obrigatório para estudo:** Nunca bloquear a tela de estudo por falta de conexão. Salvar progresso no Drift antes de qualquer tentativa de sync remoto.

15. **Não implemente SRS completo.** Usar exclusivamente o algoritmo simplificado dos 4 botões descrito acima.

16. **Drift — regras obrigatórias:**
    - Nunca modificar arquivos `.g.dart` manualmente
    - Rodar `flutter pub run build_runner build --delete-conflicting-outputs` após qualquer alteração em tabelas ou DAOs
    - DAOs retornam `Stream<List<T>>` para listas observáveis e `Future<T>` para operações pontuais
    - O banco é aberto uma única vez via provider Riverpod e injetado nos repositórios

17. **Backend desacoplado — regras obrigatórias:**
    - Nenhuma tela, widget ou repository de feature pode importar `supabase_flutter`
    - `supabase_flutter` só pode ser importado dentro de `lib/core/backend/supabase/`
    - Repositories de feature dependem de `BackendClient`/gateways por provider/injeção
    - A troca futura de backend deve ocorrer no provider/factory central de `BackendClient`, sem alterar UI ou regras de domínio
