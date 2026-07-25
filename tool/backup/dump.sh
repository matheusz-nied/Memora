#!/usr/bin/env bash
#
# Backup do Postgres do Memora para um arquivo que você controla.
#
# Resolve dois problemas de uma vez:
#   1. o plano free do Supabase não tem backup nenhum;
#   2. portabilidade — o dump é gerado com --no-owner --no-privileges, então
#      restaura em QUALQUER Postgres (VPS, Neon, RDS), não só no Supabase.
#
# Uso:
#   DATABASE_URL='postgresql://...' ./tool/backup/dump.sh
#
# Variáveis:
#   DATABASE_URL     (obrigatória) conexão direta, não o pooler de transação
#   BACKUP_DIR       destino dos arquivos            (padrão: ./backups)
#   AGE_PUBLIC_KEY   se definida, cifra o dump com age
#   RETENTION_DAYS   remove backups mais antigos     (padrão: 30)
#
set -euo pipefail

readonly backup_dir="${BACKUP_DIR:-./backups}"
readonly retention_days="${RETENTION_DAYS:-30}"
readonly stamp="$(date -u +%Y%m%dT%H%M%SZ)"

log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
fail() { log "ERRO: $*"; exit 1; }

[ -n "${DATABASE_URL:-}" ] || fail "DATABASE_URL não definida."
command -v pg_dump >/dev/null || fail "pg_dump não encontrado."

mkdir -p "$backup_dir"

readonly dump_file="$backup_dir/memora-$stamp.dump"
readonly users_file="$backup_dir/memora-$stamp.auth_users.csv"

# --- 1. Schema public: os dados do app -------------------------------------
#
# Formato custom (-Fc) para o pg_restore poder listar, filtrar e paralelizar.
# --no-owner/--no-privileges descartam donos e grants específicos do Supabase,
# que é justamente o que torna o dump restaurável em outro Postgres.
log "dump do schema public..."
pg_dump "$DATABASE_URL" \
  --format=custom \
  --compress=9 \
  --no-owner \
  --no-privileges \
  --schema=public \
  --file="$dump_file"

# --- 2. Usuários -----------------------------------------------------------
#
# auth.users fica fora do schema public e é o que amarra os decks aos donos.
# Vai em CSV de propósito: restaurar auth dentro de um Supabase vivo não é um
# psql simples, e o CSV serve tanto para conferência quanto para uma migração
# futura para autenticação própria.
#
# Só identidade: id, email e data. O hash de senha fica de fora de propósito —
# um backup vazado não deve ser material para quebrar senha. O custo disso é
# que, num restore de catástrofe, os usuários passam por "esqueci minha senha".
log "dump de auth.users..."
users_error="$(mktemp)"
if psql "$DATABASE_URL" --quiet --no-align --tuples-only \
  --command="\copy (select id, email, created_at from auth.users order by created_at) to '$users_file' with csv header" \
  2>"$users_error"; then
  log "auth.users: $(($(wc -l < "$users_file") - 1)) registros."
else
  # Sem mascarar o motivo: permissão e coluna inexistente exigem respostas
  # diferentes, e descobrir isso na catástrofe é tarde.
  log "AVISO: auth.users não exportada. Motivo:"
  sed 's/^/    /' "$users_error" >&2
  rm -f "$users_file"
fi
rm -f "$users_error"

# --- 3. Verificação --------------------------------------------------------
#
# Um dump truncado só se revela na hora de restaurar, que é a pior hora.
# pg_restore --list lê o índice do arquivo inteiro e falha se estiver corrompido.
log "verificando integridade do arquivo..."
pg_restore --list "$dump_file" > "$dump_file.toc" \
  || fail "dump corrompido ou ilegível: $dump_file"

readonly table_count="$(grep -c 'TABLE DATA' "$dump_file.toc" || true)"
[ "$table_count" -gt 0 ] || fail "dump sem nenhuma tabela com dados."
rm -f "$dump_file.toc"

# --- 4. Cifragem -----------------------------------------------------------
#
# O dump contém cards, mensagens de chat e e-mails — dado pessoal sob LGPD.
# age cifra com a chave PÚBLICA, então a máquina que faz backup nunca precisa
# guardar a chave de decifragem.
final_file="$dump_file"
if [ -n "${AGE_PUBLIC_KEY:-}" ]; then
  command -v age >/dev/null || fail "AGE_PUBLIC_KEY definida mas age não está instalado."
  log "cifrando com age..."
  age --encrypt --recipient "$AGE_PUBLIC_KEY" --output "$dump_file.age" "$dump_file"
  rm -f "$dump_file"
  final_file="$dump_file.age"
  if [ -f "$users_file" ]; then
    age --encrypt --recipient "$AGE_PUBLIC_KEY" --output "$users_file.age" "$users_file"
    rm -f "$users_file"
  fi
else
  log "AVISO: AGE_PUBLIC_KEY não definida — o backup fica em texto claro."
fi

# --- 5. Retenção -----------------------------------------------------------
log "removendo backups com mais de $retention_days dias..."
find "$backup_dir" -maxdepth 1 -name 'memora-*' -type f \
  -mtime "+$retention_days" -delete

log "pronto: $final_file ($(du -h "$final_file" | cut -f1), $table_count tabelas)"
echo "$final_file"
