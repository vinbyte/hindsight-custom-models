#!/usr/bin/env bash

set -Eeuo pipefail

DB_HOST="${HINDSIGHT_DB_HOST:-db}"
DB_PORT="${HINDSIGHT_DB_PORT:-5432}"
DB_USER="${HINDSIGHT_DB_USER:-hindsight_user}"
DB_NAME="${HINDSIGHT_DB_NAME:-hindsight_db}"

: "${PGPASSWORD:?PGPASSWORD must be set}"

PSQL=(
  psql
  --no-psqlrc
  -v
  ON_ERROR_STOP=1
  -h "$DB_HOST"
  -p "$DB_PORT"
  -U "$DB_USER"
)

echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
for attempt in {1..30}; do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1 \
    && "${PSQL[@]}" -d postgres -Atqc 'SELECT 1' >/dev/null 2>&1; then
    break
  fi

  if [[ "$attempt" == 30 ]]; then
    echo "PostgreSQL did not become ready after 30 attempts" >&2
    exit 1
  fi

  sleep 2
done

echo "PostgreSQL is ready"

# POSTGRES_DB creates this database on a fresh volume. The check also handles
# an existing volume whose database was created with a different name.
database_exists="$(
  "${PSQL[@]}" \
    -d postgres \
    -v "target_db=$DB_NAME" \
    -Atqc "SELECT 1 FROM pg_database WHERE datname = :'target_db'"
)"

if [[ "$database_exists" != "1" ]]; then
  echo "Creating database ${DB_NAME}..."
  "${PSQL[@]}" \
    -d postgres \
    -v "target_db=$DB_NAME" \
    -c 'CREATE DATABASE :"target_db";'
else
  echo "Database ${DB_NAME} already exists"
fi

echo "Installing PostgreSQL extensions..."
for extension in vector vectorscale pg_textsearch; do
  echo "Ensuring extension ${extension}..."
  "${PSQL[@]}" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS ${extension} CASCADE;"
done

echo "Timescale extensions are ready"
