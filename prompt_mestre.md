# Memora — Prompt Mestre

Você é um desenvolvedor Flutter sênior. Vamos construir juntos o **Memora**, uma plataforma de aprendizado personalizado com IA. O usuário cria decks de flashcards, gera cards com IA a partir de texto ou PDF, estuda os cards e conversa com um agente de IA configurável por deck para praticar qualquer tema — inglês, biologia, programação, etc.

O app funciona em **web, Android e iOS**. É totalmente responsivo. Siga cada etapa com precisão. **Não avance para a próxima etapa sem minha confirmação explícita de que a atual está funcionando.**

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

### Backend

| Tecnologia | Uso |
|---|---|
| Supabase Auth | Autenticação |
| Supabase Postgres | Banco de dados |
| Supabase Storage | Armazenamento de PDFs |
| Supabase Edge Functions (Deno) | Chamadas à IA |

### IA

| Modelo | Uso |
|---|---|
| Gemini 1.5 Flash | Geração de cards e chat |
| GPT-4o mini (OpenAI) | Fallback |

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
│   │   └── supabase_constants.dart ← nomes de tabelas e buckets
│   ├── theme/
│   │   ├── app_theme.dart          ← ThemeData light e dark
│   │   ├── app_colors.dart         ← paleta de cores centralizada
│   │   ├── app_typography.dart     ← estilos de texto
│   │   └── app_dimensions.dart     ← espaçamentos e tamanhos
│   ├── utils/
│   │   ├── responsive.dart         ← helpers de breakpoint
│   │   └── validators.dart         ← validações de formulário
│   └── widgets/
│       ├── app_button.dart         ← botão padrão reutilizável
│       ├── app_input.dart          ← input padrão reutilizável
│       ├── app_card.dart           ← card container reutilizável
│       ├── empty_state.dart        ← widget de estado vazio
│       ├── error_state.dart        ← widget de erro
│       └── loading_state.dart      ← widget de loading
│
├── features/
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
│   │   │   └── deck_repository.dart
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── deck_screen.dart
│   │       └── widgets/
│   │           ├── deck_card.dart
│   │           └── deck_form_modal.dart
│   │
│   ├── cards/
│   │   ├── data/
│   │   │   ├── card_model.dart
│   │   │   └── card_repository.dart
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
│   │   │   └── agent_repository.dart
│   │   └── presentation/
│   │       ├── chat_screen.dart
│   │       └── agent_config_screen.dart
│   │
│   └── study/
│       └── presentation/
│           └── study_screen.dart
│
supabase/
└── functions/
    ├── generate-cards/
    │   └── index.ts
    └── chat/
        └── index.ts
```

---

## Rotas

| Rota | Tela |
|---|---|
| `/login` | Login |
| `/register` | Cadastro |
| `/forgot-password` | Recuperar senha |
| `/home` | Home com lista de decks |
| `/deck/:deckId` | Tela do deck |
| `/deck/:deckId/study` | Modo estudo |
| `/deck/:deckId/generate` | Importar conteúdo |
| `/deck/:deckId/generate/review` | Revisar cards gerados |
| `/deck/:deckId/chat` | Chat com agente |
| `/deck/:deckId/agent-config` | Configurar agente |

---

## Banco de Dados

### Tabela: `decks`

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

### Tabela: `cards`

| Coluna | Tipo | Flags |
|---|---|---|
| `id` | uuid | PK |
| `deck_id` | uuid | FK → decks |
| `front` | text | NOT NULL |
| `back` | text | NOT NULL |
| `created_at` | timestamptz | DEFAULT now() |
| `updated_at` | timestamptz | DEFAULT now() |

### Tabela: `chat_messages`

| Coluna | Tipo | Flags |
|---|---|---|
| `id` | uuid | PK |
| `deck_id` | uuid | FK → decks |
| `user_id` | uuid | FK → auth.users |
| `role` | text | CHECK IN ('user', 'assistant') |
| `content` | text | NOT NULL |
| `created_at` | timestamptz | DEFAULT now() |

> **RLS:** Todas as tabelas com Row Level Security ativo. Acesso restrito a registros onde `user_id = auth.uid()`. Para `cards` e `chat_messages`, verificado via join com `decks`. Nunca desativar RLS nem criar políticas permissivas demais.

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

### `supabase_constants.dart`

| Constante | Valor |
|---|---|
| `kTableDecks` | `'decks'` |
| `kTableCards` | `'cards'` |
| `kTableChatMessages` | `'chat_messages'` |
| `kBucketPdfs` | `'pdfs'` |

### `route_constants.dart`

| Constante | Valor |
|---|---|
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

**Primária (Violeta)**

| Nome | Valor |
|---|---|
| `primary` | `Color(0xFF6C63FF)` |
| `primaryHover` | `Color(0xFF5A52E0)` |
| `primaryLight` | `Color(0xFFEEEDFE)` |
| `primaryDark` | `Color(0xFF3C3489)` |

**Neutros Light**

| Nome | Valor |
|---|---|
| `background` | `Color(0xFFFAFAFA)` |
| `surface` | `Color(0xFFFFFFFF)` |
| `border` | `Color(0xFFE4E4E7)` |
| `textPrimary` | `Color(0xFF18181B)` |
| `textSecondary` | `Color(0xFF71717A)` |
| `textTertiary` | `Color(0xFFA1A1AA)` |

**Neutros Dark**

| Nome | Valor |
|---|---|
| `backgroundDark` | `Color(0xFF0F0F0F)` |
| `surfaceDark` | `Color(0xFF1A1A1A)` |
| `borderDark` | `Color(0xFF2E2E2E)` |
| `textPrimaryDark` | `Color(0xFFF4F4F5)` |
| `textSecDark` | `Color(0xFFA1A1AA)` |
| `textTertDark` | `Color(0xFF52525B)` |

**Semânticas**

| Nome | Valor | Fundo |
|---|---|---|
| `success` | `Color(0xFF22C55E)` | `successBg` → `Color(0xFFF0FDF4)` |
| `error` | `Color(0xFFEF4444)` | `errorBg` → `Color(0xFFFEF2F2)` |
| `warning` | `Color(0xFFF59E0B)` | `warningBg` → `Color(0xFFFFFBEB)` |
| `info` | `Color(0xFF3B82F6)` | `infoBg` → `Color(0xFFEFF6FF)` |

### `app_typography.dart` — TextStyles centralizados

| Estilo | Fonte | Tamanho | Peso |
|---|---|---|---|
| `displayLarge` | Inter | 32px | w700 |
| `headingLarge` | Inter | 22px | w600 |
| `headingMedium` | Inter | 18px | w600 |
| `bodyLarge` | Inter | 15px | w400 |
| `bodyMedium` | Inter | 14px | w400 |
| `bodySmall` | Inter | 13px | w400 |
| `labelMedium` | Inter | 14px | w500 |
| `labelSmall` | Inter | 11px | w500 |

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
| `radiusFull` | 999.0 |

### `responsive.dart` — helpers de breakpoint

| Helper | Condição |
|---|---|
| `isMobile(context)` | largura < 600px |
| `isTablet(context)` | 600px ≤ largura < 1024px |
| `isDesktop(context)` | largura ≥ 1024px |
| `contentPadding(context)` | 16px mobile / 24px tablet / 32px desktop |

---

## Edge Functions

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

### Auth
- Sessão persiste após fechar o app
- Erros de auth exibem mensagem legível (não o erro raw)
- Logout redireciona imediatamente para `/login`
- Não autenticado acessando rota protegida → `/login`
- Autenticado acessando `/login` ou `/register` → `/home`

### Decks
- Lista atualiza em tempo real via Stream do Supabase
- Deletar deck apaga os cards e mensagens via cascade
- Grid 2 colunas em telas ≥ 600px

### Geração de Cards
- Nenhum card é salvo antes da revisão do usuário
- O usuário pode editar, remover e adicionar cards na revisão
- Erros de PDF exibem mensagem específica (protegido, escaneado, muito grande, poucas páginas, texto insuficiente)

### Chat
- Histórico máximo de `kMaxChatMessages` (40) por sessão
- Ao atingir o limite: aviso + botão "Nova conversa"
- Indicador de digitação durante loading da resposta
- Mensagens salvas no Supabase após cada troca

### Estudo
- Cards sempre embaralhados ao iniciar
- Flip animado em 350ms
- Text-to-speech usa o idioma do agente do deck
- Tela de conclusão com opção de repetir

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

9. **Nunca hardcodar strings** de rotas, tabelas ou buckets — usar as constantes de `route_constants.dart` e `supabase_constants.dart`.

10. **Nunca salve segredos** (API keys) no código Flutter. As chaves `GEMINI_API_KEY` e `DEEPSEEK_API_KEY` ficam apenas nas Edge Functions.

11. **Não use `BuildContext`** fora da árvore de widgets.

12. **Não faça chamadas ao Supabase** diretamente nas telas — sempre via repositório.

13. **Não crie providers globais** para estado local de tela.