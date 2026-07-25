#!/usr/bin/env bash
#
# Restaura um backup gerado por dump.sh em qualquer Postgres.
#
# Rode isto de verdade, num banco descartável, pelo menos uma vez por mês.
# Backup que nunca foi restaurado é uma suposição, não um backup.
#
# Uso:
#   TARGET_DATABASE_URL='postgresql://...' ./tool/backup/restore.sh backups/memora-....dump
#
# Variáveis:
#   TARGET_DATABASE_URL  (obrigatória) destino — NUNCA aponte para produção
#   AGE_KEY_FILE         chave privada age, se o arquivo estiver cifrado
#
set -euo pipefail

log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
fail() { log "ERRO: $*"; exit 1; }

readonly source_file="${1:-}"
[ -n "$source_file" ] || fail "uso: $0 <arquivo.dump[.age]>"
[ -f "$source_file" ] || fail "arquivo não encontrado: $source_file"
[ -n "${TARGET_DATABASE_URL:-}" ] || fail "TARGET_DATABASE_URL não definida."
command -v pg_restore >/dev/null || fail "pg_restore não encontrado."

# Guarda contra o acidente clássico: restaurar por cima do banco vivo.
case "$TARGET_DATABASE_URL" in
  *prod*|*production*)
    fail "TARGET_DATABASE_URL parece ser produção. Restaure num banco descartável."
    ;;
esac

work_file="$source_file"
cleanup() { [ "${work_file:-}" != "$source_file" ] && rm -f "$work_file" || true; }
trap cleanup EXIT

if [ "${source_file##*.}" = "age" ]; then
  [ -n "${AGE_KEY_FILE:-}" ] || fail "arquivo cifrado, mas AGE_KEY_FILE não definida."
  command -v age >/dev/null || fail "age não encontrado."
  log "decifrando..."
  work_file="$(mktemp)"
  age --decrypt --identity "$AGE_KEY_FILE" --output "$work_file" "$source_file"
fi

# Restaurar por cima de dados existentes mistura duas gerações de backup e o
# resultado não prova nada. Um drill honesto começa de um banco vazio.
existing="$(psql "$TARGET_DATABASE_URL" --quiet --no-align --tuples-only \
  --command="select count(*) from information_schema.tables where table_schema = 'public'")"
if [ "${existing:-0}" -gt 0 ] && [ "${FORCE_RESTORE:-0}" != "1" ]; then
  fail "o schema public do alvo já tem $existing tabelas. Recrie o banco (dropdb/createdb) ou use FORCE_RESTORE=1."
fi

log "conteúdo do arquivo:"
pg_restore --list "$work_file" | grep 'TABLE DATA' | sed 's/^/  /' >&2

# --- Scaffolding que o dump espera encontrar -------------------------------
#
# Todas as tabelas do Memora têm FK para auth.users, que é do Supabase e não
# existe num Postgres puro. Sem isto o pg_restore restaura os dados e depois
# explode ao recriar as constraints.
#
# `if not exists` em tudo, e a função auth.uid() só é criada quando ausente:
# restaurar num Supabase real não pode sobrescrever a implementação dele.
log "garantindo scaffolding de auth..."
psql "$TARGET_DATABASE_URL" --quiet -v ON_ERROR_STOP=1 <<'SQL' >/dev/null
-- O dump traz `CREATE SCHEMA public`, e todo Postgres já nasce com um.
-- O alvo foi validado como vazio acima, então cedemos o schema para o dump
-- recriá-lo do jeito que estava na origem.
drop schema if exists public cascade;

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key,
  email text,
  created_at timestamptz not null default now()
);

do $outer$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'auth' and p.proname = 'uid'
  ) then
    execute $f$
      create function auth.uid() returns uuid language sql stable as
      $b$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $b$
    $f$;
  end if;
end
$outer$;

do $$ begin create role anon;          exception when duplicate_object then null; end $$;
do $$ begin create role authenticated; exception when duplicate_object then null; end $$;
do $$ begin create role service_role;  exception when duplicate_object then null; end $$;
SQL

# Os usuários precisam existir ANTES das FKs serem recriadas, e o pg_restore
# faz dados e constraints numa passada só — então a carga vem primeiro.
users_csv="${source_file%.age}"
users_csv="${users_csv%.dump}.auth_users.csv"
[ "$source_file" != "${source_file%.age}" ] && users_csv="$users_csv.age"

if [ -f "$users_csv" ]; then
  csv_work="$users_csv"
  if [ "${users_csv##*.}" = "age" ]; then
    csv_work="$(mktemp)"
    age --decrypt --identity "$AGE_KEY_FILE" --output "$csv_work" "$users_csv"
  fi
  log "carregando auth.users de $(basename "$users_csv")..."
  psql "$TARGET_DATABASE_URL" --quiet -v ON_ERROR_STOP=1 \
    --command="\copy auth.users (id, email, created_at) from '$csv_work' with csv header" \
    >/dev/null
  [ "$csv_work" != "$users_csv" ] && rm -f "$csv_work"
else
  log "AVISO: CSV de auth.users não encontrado; as FKs podem falhar."
fi

# --no-owner/--no-privileges são necessários porque os papéis do Supabase
# (supabase_admin, authenticated, service_role) não existem em outro Postgres.
log "restaurando..."
pg_restore \
  --dbname="$TARGET_DATABASE_URL" \
  --no-owner \
  --no-privileges \
  --exit-on-error \
  "$work_file"

# --- Sanidade --------------------------------------------------------------
#
# Restaurar sem erro não prova que os dados chegaram. Conferir contagem prova.
log "conferindo linhas restauradas:"
psql "$TARGET_DATABASE_URL" --quiet --no-align --field-separator=' ' <<'SQL' >&2
select
  relname as tabela,
  n_live_tup as linhas
from pg_stat_user_tables
where schemaname = 'public'
order by relname;
SQL

log "restauração concluída."
