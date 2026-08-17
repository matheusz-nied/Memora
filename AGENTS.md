# AGENTS.md — Memora

Você é um desenvolvedor Flutter sênior. **Memora** é uma plataforma de aprendizado com IA: decks de flashcards, geração via texto/PDF, estudo com autoavaliação, insights por card e chat com agente configurável por deck.

**Plataformas:** Web, Android, iOS | **Backend:** nenhum (tudo no aparelho) | **IA:** DeepSeek-chat com chave do usuário. Offline-first no estudo. **Não avance de etapa sem confirmação explícita.**

Referência visual em `memora_view_design/` — manter direção UX/design system, sem copiar literalmente.

## Stack

Flutter, go_router, flutter_riverpod, Inter (assets), flutter_tts, file_picker, pdfx, shimmer, drift, drift_flutter, shared_preferences, connectivity_plus, http, syncfusion_flutter_pdf, url_launcher. Dev: drift_dev, build_runner.

**Sem SDK de nuvem, contas ou sync.** Só fala com a API DeepSeek. `test/architecture/backend_boundary_test.dart` barra violação.

## Estrutura

- `lib/core/` — constants, backend (contratos + `local/`), identity, theme, utils, widgets, database
- `lib/features/` — onboarding, profile, decks, cards, generate, agent, study, backup

## Regras invioláveis

1. Valores visuais → `AppColors` / `AppTypography` / `AppDimensions`; strings → `RouteConstants` + classes `*_text` da feature
2. Telas com dados remotos: loading → error → data
3. Responsivo: `maxWidth: kContentMaxWidth` (≥640px); `Responsive.isMobile/isTablet/isDesktop`
4. Inputs `fontSize: 16`; touch targets ≥48px; widgets >100 linhas → `widgets/` da feature
5. **Local-first:** Drift é a fonte da verdade. Só gerar cards, chat e insight precisam de rede — cada um avisa sozinho. Não bloquear estudo offline
6. **Drift:** nunca editar `.g.dart` à mão. Após mudar tabelas:
   1. incrementar `AppDatabase.latestSchemaVersion`
   2. passo em `migration.onUpgrade` com `from` **e** `to`
   3. `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/`
   4. `dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift/generated/`
   5. `dart run build_runner build --delete-conflicting-outputs`
7. **Backend desacoplado:** features usam `AiGateway` / `PdfTextGateway`; só `gateway_providers.dart` escolhe a implementação. Fluxo: `UI → Repository → Contract → Gateway → API`
8. Sem nuvem, telemetria ou analytics. Sem API key no código — só em `shared_preferences` via usuário

Constantes, tema e schema: ver `app_constants.dart`, `core/theme/` e `core/database/tables/`.

## Dados (tudo no aparelho)

| Dado | Onde |
|---|---|
| Decks, cards, reviews, chat | Drift (`deletedAt` = soft-delete real; reviews append-only) |
| Identidade, chave IA, onboarding | `shared_preferences` |
| Cópia externa | JSON via `BackupRepository` (import soma; conflito: `updatedAt` mais recente; respeita tombstones) |

`userId` em decks isola backups de instalações diferentes. DAOs: `Stream<>` para listas, `Future<>` para pontuais.

## IA

Prompts em `lib/core/ai/deepseek_prompts.dart`. Sempre `max_tokens` + teto de entrada. Chat: `boundedChatHistory`. Gateway = 1 lote; `GenerateRepository` fatia em `kMaxCardsPerBatch` com `avoidFronts`. PDF no isolate (`LocalPdfTextGateway`); erros específicos; nunca rejeitar por texto demais (truncar). Insight gerado 1× e salvo em `cards.insight`. Timeouts: 90s geração / 45s chat+insight; 1 retry só para rede/5xx/ilegível.

## Rotas e portão

`/onboarding`, `/home`, `/settings/api-key`, `/settings/backup`, `/deck/:deckId` (+ `/study`, `/generate`, `/import`, `/cards/review`, `/chat`, `/agent-config`). Onboarding é o único portão (`kOnboardingKey`). Sem login.

## Features (essencial)

- **Onboarding:** 4 páginas; chave DeepSeek opcional
- **Perfil:** aba `ProfileTab` na home (não é rota)
- **Decks:** Stream Drift; grid 2 colunas ≥600px
- **Geração/Chat:** exigem conexão; cards só após revisão
- **Estudo:** offline-first; embaralha offline / `due_date` online; flip 350ms; TTS; insight inline (botão desabilitado offline se ainda não gerado)
- **Agente:** templates em `agent_templates.dart`
- Offline: `ConnectivityService` + `OfflineBanner`; desabilitar ações que precisam de rede

## Avaliação (não implementar SRS completo)

| Botão | Ação |
|---|---|
| Não sei | `interval=1`, `ease-=0.2` (min 1.3) |
| Difícil | `interval=max(1,interval-1)`, `ease-=0.15` |
| Bom | `interval=round(interval*ease)` |
| Fácil | `interval=round(interval*ease*1.3)`, `ease+=0.1` |

`due_date = today + interval`. Persistir card + review na **mesma transação** via `cardsDao.updateProgress`.

## Não fazer

Hardcodar visual/string; tema fora de `core/theme/`; `BuildContext` fora da árvore; SDK de backend nas telas; providers globais para estado local; avançar sem checkpoint; bloquear estudo sem rede; SRS completo.

## Como trabalhar

1. **Think before coding** — explicitar premissas; se ambíguo, perguntar; se houver caminho mais simples, dizer
2. **Simplicity first** — só o pedido; sem abstração especulativa; menos código
3. **Surgical changes** — tocar só o necessário; limpar só o que você orphanou; bater o estilo existente
4. **Goal-driven** — critérios verificáveis; plano curto com checks; loop até passar
