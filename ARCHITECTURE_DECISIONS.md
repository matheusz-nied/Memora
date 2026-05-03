# Base de Conhecimento para Artigos: Arquitetura do Memora

> **Prompt padrão para a IA (Copie e cole quando for escrever o artigo):**
> *"Atue como um Engenheiro de Software Sênior e Tech Writer. Baseado nas decisões arquiteturais do projeto Memora descritas abaixo, escreva um artigo técnico envolvente e profissional para a comunidade de desenvolvedores (ideal para Medium ou LinkedIn). O artigo deve explicar o 'porquê' dessas escolhas, focando nos benefícios de acoplamento baixo, resiliência offline e Clean Architecture no ecossistema Flutter. Use um tom didático, mostrando como essas decisões diferenciam um app amador de um projeto de alto nível."*

---

## Resumo das Decisões para o Artigo

### 1. Inversão de Controle (Backend Desacoplado)
- **Decisão:** Criação de `Contracts` / Gateways (interfaces genéricas, ex: `RemoteDatabaseGateway`) e uso de `Adapters` específicos (ex: `SupabaseRemoteDatabaseGateway`).
- **Por quê:** O app nunca importa pacotes de terceiros (como a SDK do Supabase) em suas telas. Isso evita o *vendor lock-in*. Mudar a tecnologia de nuvem requer apenas reescrever os adapters; a lógica do app e a UI permanecem intocadas.

### 2. Padrão DTO (Data Transfer Objects)
- **Decisão:** Conversão das respostas da nuvem para modelos próprios do Dart (ex: `BackendDeck`).
- **Por quê:** Isola o aplicativo de alterações no esquema ou nomes de colunas do banco de dados remoto, garantindo que o Flutter trabalhe apenas com classes fortemente tipadas do Dart.

### 3. Persistência Local Tipada (Drift + DAOs)
- **Decisão:** Adoção do Drift (SQLite) como banco relacional local, com operações isoladas no padrão Data Access Object (DAO).
- **Por quê:** O Drift garante consultas SQL seguras em tempo de compilação. Os DAOs abstraem as operações e retornam **Streams**. Isso significa que a interface gráfica é inteiramente reativa: se o banco local for alterado em background, a UI se atualiza sozinha, garantindo reatividade fluida.

### 4. Resiliência Offline-first Absoluta
- **Decisão:** Leitura e escrita primárias são sempre feitas no banco local. A sincronização para a nuvem depende de uma flag relacional (`syncPending = true`).
- **Por quê:** Garante zero latência e 100% de disponibilidade em áreas sem rede (como no metrô). O progresso do usuário é salvo instantaneamente. Quando a rede volta (monitorada ativamente pelo app), um serviço de background sincroniza o que estiver pendente de forma assíncrona e tolerante a falhas.

### 5. Segurança Nativa (Row Level Security - RLS)
- **Decisão:** A trava de proteção de dados não é feita no aplicativo (client-side), mas sim direto no motor do banco de dados Postgres.
- **Por quê:** Assegura verdadeiro isolamento entre os usuários (*multitenancy*). Mesmo que uma API Key pública seja exposta ou a chamada de rede seja interceptada, o banco se recusa nativamente a entregar dados que não coincidam com o token criptografado do usuário logado.
