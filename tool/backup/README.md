# Backup e restauração do Memora

Resolve dois problemas de uma vez:

1. **O plano free do Supabase não tem backup nenhum.** Um `drop table` errado
   ou uma conta suspensa não têm desfazer.
2. **Portabilidade.** O dump sai com `--no-owner --no-privileges`, então
   restaura em qualquer Postgres — sua VPS, Neon, RDS — e não só no Supabase.

## Setup, uma vez

### 1. Gerar o par de chaves de cifragem

O dump contém cards, mensagens de chat e e-mails: dado pessoal sob LGPD. Ele é
cifrado com [age](https://github.com/FiloSottile/age), usando chave pública —
assim a máquina que faz o backup nunca precisa guardar a chave de decifragem.

```bash
age-keygen -o memora-backup.key
# Public key: age1xxxxxxxx...
```

> **Guarde `memora-backup.key` fora do GitHub e fora da máquina de build.**
> Gerenciador de senhas ou cofre offline. Perder essa chave torna todos os
> backups ilegíveis; vazá-la torna todos eles legíveis.

### 2. Configurar os secrets do repositório

| Secret | Valor |
|---|---|
| `BACKUP_DATABASE_URL` | Conexão **direta** (porta 5432) do Supabase, não o pooler de transação |
| `BACKUP_AGE_PUBLIC_KEY` | A linha `age1...` do passo anterior |

Opcionais, para arquivar num bucket seu em vez de depender do artifact do
GitHub: `BACKUP_S3_BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
`AWS_DEFAULT_REGION` e `BACKUP_S3_ENDPOINT` (para R2/B2).

### 3. Rodar uma vez à mão

Em **Actions → backup → Run workflow**. Se passar, o agendamento diário às
05:17 UTC está de pé.

## O que entra no backup

| Conteúdo | Formato | Observação |
|---|---|---|
| Schema `public` completo | `pg_dump -Fc` | Tabelas, dados, funções de quota, policies RLS |
| `auth.users` | CSV | Só `id`, `email`, `created_at` |

**O hash de senha fica de fora de propósito.** Um backup vazado não deve virar
material para quebrar senha. O custo: num restore de catástrofe os usuários
passam por "esqueci minha senha" — as contas e todos os decks continuam lá,
ligados pelo `id`.

## Restaurar

```bash
createdb memora_restore

TARGET_DATABASE_URL='postgresql://localhost/memora_restore' \
AGE_KEY_FILE=~/memora-backup.key \
./tool/backup/restore.sh backups/memora-20260725T051700Z.dump.age
```

O script recusa alvo com tabelas em `public` (use `FORCE_RESTORE=1` para
insistir) e recusa URL que pareça produção.

Ele também cria o scaffolding mínimo de `auth` antes de restaurar: **todas as
tabelas do Memora têm FK para `auth.users`**, que é do Supabase e não existe
num Postgres puro. Sem isso o restore carrega os dados e explode ao recriar as
constraints. Num Supabase real o scaffolding é no-op e a `auth.uid()` dele não
é sobrescrita.

## Drill mensal — a parte que ninguém faz

**Backup que nunca foi restaurado é uma suposição, não um backup.**

Uma vez por mês, baixe o artifact mais recente e rode o restore num banco
descartável. Leva cinco minutos e é a única coisa que prova que a corrente
inteira funciona: dump legível, cifragem reversível, chave certa, schema
compatível.

O drill é **manual de propósito**. Automatizá-lo exigiria a chave privada nos
secrets do GitHub, que é exatamente o que a cifragem por chave pública evita.

Confira, além do "terminou sem erro":

```sql
select relname, n_live_tup from pg_stat_user_tables
where schemaname = 'public' order by relname;

-- As funções de quota vieram junto?
select proname from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' order by 1;

-- E funcionam?
select * from consume_ai_quota('<um-user-id-do-csv>', 'chat', 1);
```

## O que este backup NÃO cobre

- **Bucket `pdfs`.** Hoje os PDFs nunca são apagados depois de virarem cards,
  o que é desperdício, não dado a preservar. A correção certa é apagá-los após
  a geração, não copiá-los.
- **Configuração do projeto Supabase.** Redirect URLs, SMTP, secrets das Edge
  Functions. Mantenha isso em `a_fazer.md` ou em infra-as-code.
- **Point-in-time recovery.** Um dump diário significa até 24h de perda. PITR
  só existe nos planos pagos do Supabase.

## Rodando fora do GitHub Actions

Os scripts não dependem de CI. Numa VPS, via cron:

```cron
17 5 * * * cd /srv/memora && DATABASE_URL='...' AGE_PUBLIC_KEY='age1...' \
  BACKUP_DIR=/var/backups/memora ./tool/backup/dump.sh >> /var/log/memora-backup.log 2>&1
```

`RETENTION_DAYS` (padrão 30) controla a poda dos antigos.
