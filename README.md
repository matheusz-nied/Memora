# Memora

Flashcards com repetição espaçada e IA. O usuário cria decks, gera cards a
partir de texto ou PDF, estuda com auto-avaliação, pede insights por card e
conversa com um agente tutor configurável por deck.

Flutter — Android, iOS e web.

## Dois modos, um binário de cada vez

O app compila em dois modos, escolhidos em `lib/core/config/app_mode.dart`:

| | `AppMode.local` | `AppMode.cloud` |
|---|---|---|
| Identidade | id gerado no aparelho | conta Supabase (e-mail + senha) |
| Dados | só no Drift local | Drift + sync com Postgres |
| Chave da IA | cadastrada pelo usuário | no servidor, com quota por usuário |
| Backup | export/import `.json` na tela de Backup | dump cifrado agendado |

`kAppMode` é `const`: as comparações somem em tempo de compilação, então o
build local não carrega o SDK do Supabase e o build de nuvem não carrega o
adaptador local. **O v1 é `AppMode.local`**; o adaptador de nuvem está pronto e
testado, reservado para o v2.

Trocar de modo é editar aquela linha e recompilar — nunca um `sed` sobre
`AppMode.cloud`, que casaria também com a definição de `kIsCloudMode` logo
abaixo e deixaria os dois atalhos com o mesmo valor.

## Rodando

Requer Flutter ≥ 3.35 (Dart ^3.8.1).

```bash
cp .env.example .env      # `.env` é asset declarado no pubspec: sem ele o build falha
flutter pub get
flutter run
```

O conteúdo do `.env` só é lido no modo nuvem — mas o arquivo precisa existir
nos dois, porque está na lista de assets.

No modo local, o app pede a chave da DeepSeek no fim do onboarding. Ela fica no
armazenamento privado do app, é do usuário e cobra na conta dele — sem ela o
app funciona, mas sem geração, chat nem insight.

Depois de mexer em tabela do Drift:

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

O passo completo, incluindo o que fazer com `schemaVersion` e a migração, está
em `AGENTS.md`. A CI recusa código gerado desatualizado.

## Verificação

O que a CI cobra, na ordem em que ela cobra:

```bash
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

As Edge Functions (só usadas no modo nuvem) têm um job próprio com
`deno fmt`, `deno lint`, `deno check` e `deno test`.

## Onde está o quê

- `lib/core/backend/` — contratos (`AuthGateway`, `RemoteDatabaseGateway`,
  `StorageGateway`, `AiGateway`, `PdfTextGateway`) e os dois adaptadores,
  `local/` e `supabase/`. Nenhuma feature sabe qual está ativo; a fronteira é
  verificada por `test/architecture/backend_boundary_test.dart`.
- `lib/core/database/` — Drift: tabelas, DAOs e migrações versionadas.
- `lib/features/` — uma pasta por feature, cada uma com repositório, telas e
  os textos em `*_text.dart`.
- `supabase/functions/` — Edge Functions do modo nuvem.

O que falta para publicar, na ordem de execução: `LANCAMENTO.md`.

## Licença

O código do Memora está sob a licença [MIT](LICENSE) — use, modifique e
redistribua à vontade.

Uma ressalva importante para quem for compilar ou publicar a partir daqui: a
dependência **`syncfusion_flutter_pdf`**, usada para extrair o texto dos PDFs,
**não é open source**. Ela exige a Community License da Syncfusion (gratuita,
mas com registro obrigatório e limitada a organizações com receita anual abaixo
de US$ 1 milhão e menos de 5 desenvolvedores) ou uma licença comercial. A
licença MIT deste repositório cobre o código escrito aqui, não as dependências
de terceiros — se você não se enquadra na Community License, precisa contratar
a comercial ou trocar o extrator de PDF.

Os mockups em `memora_view_design/` são referência visual gerada no Stitch e
não fazem parte do software licenciado acima.
