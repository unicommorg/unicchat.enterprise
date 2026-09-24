#!/usr/bin/env bash
# Проверка multi-server-install/.env до docker compose up.
set -euo pipefail

ENV_FILE="${1:-.env}"
cd "$(dirname "$0")"

fail=0
warn=0
die() { echo "ERROR: $*" >&2; fail=1; }
note() { echo "WARN: $*" >&2; warn=$((warn + 1)); }
ok() { echo "OK: $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Run: cp .env.example .env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

required=(
  APP_SERVER_NAME
  DOCUMENTSERVER_SERVER_NAME
  MINIO_SERVER_NAME
  ROOT_URL
  LICENSE_HOST
  MONGODB_ROOT_PASSWORD
  MONGODB_PASSWORD
  VAULT_DB_PASSWORD
  LOGGER_DB_PASSWORD
  TASKER_DB_PASSWORD
  MINIO_ROOT_PASSWORD
  IMAGE_MONGODB
  IMAGE_APPSERVER
  IMAGE_NGINX
  IMAGE_MINIO
  IMAGE_VAULT
  IMAGE_POSTGRES
)

for v in "${required[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    die "$v is empty"
  fi
done

for v in MONGODB_ROOT_PASSWORD MONGODB_PASSWORD VAULT_DB_PASSWORD \
  LOGGER_DB_PASSWORD TASKER_DB_PASSWORD MINIO_ROOT_PASSWORD MONGODB_REPLICA_SET_KEY; do
  if [[ "${!v:-}" == change_me_* ]]; then
    die "$v still has a change_me_* default"
  fi
done

if [[ "${MONGODB_REPLICA_SET_KEY:-}" == "rs0key" ]]; then
  die "MONGODB_REPLICA_SET_KEY is still the example value rs0key"
fi

for url in ROOT_URL LICENSE_HOST API_VAULT_URL API_LOGGER_URL UNIC_SOLID_HOST; do
  val="${!url:-}"
  [[ -z "$val" ]] && continue
  if [[ ! "$val" =~ ^https?:// ]]; then
    die "$url must start with http:// or https://"
  fi
done

for host in APP_SERVER_NAME DOCUMENTSERVER_SERVER_NAME MINIO_SERVER_NAME; do
  if [[ "${!host}" == *example.com ]]; then
    note "$host still uses example.com — replace it with your DNS name"
  fi
done

passwords=(
  "$MONGODB_ROOT_PASSWORD"
  "$MONGODB_PASSWORD"
  "$VAULT_DB_PASSWORD"
  "$LOGGER_DB_PASSWORD"
  "$TASKER_DB_PASSWORD"
  "$MINIO_ROOT_PASSWORD"
)
uniq_count=$(printf '%s\n' "${passwords[@]}" | sort -u | wc -l)
if [[ "$uniq_count" -lt 6 ]]; then
  note "some database or MinIO passwords are identical — use a unique secret for each"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "validation FAILED"
  exit 1
fi

ok "required variables are set"
echo "validation PASSED (${warn} warnings)"
exit 0
