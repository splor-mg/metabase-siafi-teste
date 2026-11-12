#!/usr/bin/env bash
# Inicializa o Postgres gratuito do Render para o dashboard público.
# A carga é limitada às três tabelas usadas pelas views do dashboard para caber
# melhor no limite de 1 GB do Postgres gratuito.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${ENV_FILE:-.env.render.local}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Copie .env.render.example para .env.render.local e preencha as credenciais." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

: "${PGHOST:?Preencha o host externo do Render Postgres}"
: "${PGPORT:=5432}"
: "${SIAFI_DB:=siafi_2026}"
: "${PGUSER:?Preencha o usuário externo do Render Postgres}"
: "${PGPASSWORD:?Preencha a senha externa do Render Postgres}"
: "${SIAFI_OWNER_PASSWORD:?Defina uma senha exclusiva para siafi_owner}"
: "${METABASE_RO_PASSWORD:?Defina a senha de metabase_leitor e repita no Render}"
: "${SIAFI_DATA_REPO:?Preencha o caminho do clone dados-siafi-2026}"

export PGSSLMODE="${PGSSLMODE:-require}"
PSQL_ADMIN=(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$SIAFI_DB" -v ON_ERROR_STOP=1)

echo "1/5 criando os usuários de carga e leitura..."
"${PSQL_ADMIN[@]}" -v owner_pw="$SIAFI_OWNER_PASSWORD" -v reader_pw="$METABASE_RO_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE siafi_owner LOGIN PASSWORD %L', :'owner_pw')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'siafi_owner')
\gexec
SELECT format('CREATE ROLE metabase_leitor LOGIN PASSWORD %L', :'reader_pw')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'metabase_leitor')
\gexec
ALTER ROLE siafi_owner SET client_encoding TO 'utf8';
ALTER ROLE siafi_owner SET timezone TO 'UTC';
ALTER ROLE metabase_leitor SET default_transaction_read_only TO on;
SQL
"${PSQL_ADMIN[@]}" -c 'GRANT CONNECT ON DATABASE siafi_2026 TO siafi_owner, metabase_leitor;'

echo "2/5 criando o schema e as tabelas..."
"${PSQL_ADMIN[@]}" -c 'CREATE SCHEMA IF NOT EXISTS siafi AUTHORIZATION siafi_owner;'
python3 scripts/gen_ddl.py "$SIAFI_DATA_REPO/datapackage.json" > sql/02_tabelas.sql
PGPASSWORD="$SIAFI_OWNER_PASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$SIAFI_OWNER" \
  -d "$SIAFI_DB" -v ON_ERROR_STOP=1 -f sql/02_tabelas.sql

echo "3/5 carregando as tabelas usadas no painel..."
ENV_FILE="$ENV_FILE" SIAFI_LOAD_TABLES="execucao receita credito" \
  bash scripts/load.sh "$SIAFI_DATA_REPO/data"

echo "4/5 criando as views e permissões do projeto..."
PGPASSWORD="$SIAFI_OWNER_PASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$SIAFI_OWNER" \
  -d "$SIAFI_DB" -v ON_ERROR_STOP=1 -f sql/03_permissoes_e_views.sql

echo "5/5 conferindo as views do dashboard..."
PGPASSWORD="$METABASE_RO_PASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U metabase_leitor \
  -d "$SIAFI_DB" -Atc "SELECT 'painel.execucao_mensal', count(*) FROM painel.execucao_mensal;"
echo "Postgres pronto. O dashboard consulta somente as tabelas execucao, receita e credito."
