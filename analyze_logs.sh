#!/usr/bin/env bash
#
# UnicChat Enterprise - Log Collection & Analysis Script
# Собирает логи контейнеров и формирует отчёт об ошибках и ключевых событиях
#

set -euo pipefail

LOG_DIR="${LOG_DIR:-unicchat_logs}"
REPORT_FILE="log_analysis_report_$(date +%Y%m%d_%H%M%S).txt"
CONTAINERS=(
  unicchat-mongodb unicchat-vault unicchat-appserver unicchat-logger
  unicchat-tasker unicchat-minio unicchat-documentserver unicchat-rabbitmq unicchat-postgresql
)
# Fallback для старых имён с точками
CONTAINERS_OLD=(
  unicchat.mongodb unicchat.vault unicchat.appserver unicchat.logger
  unicchat.tasker unicchat.minio unicchat.documentserver unicchat.rabbitmq unicchat.postgresql
)
TAIL_LINES="${TAIL_LINES:-200}"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Сбор логов из Docker ---
collect_logs() {
  local dir="$1"
  mkdir -p "$dir"
  log_info "Сбор логов в $dir (последние $TAIL_LINES строк)..."

  for c in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$c"; then
      docker logs "$c" --tail "$TAIL_LINES" 2>&1 > "$dir/${c}.log" && log_info "  $c ✓" || log_warn "  $c: ошибка сбора"
    fi
  done
  # Пробуем старые имена
  for c in "${CONTAINERS_OLD[@]}"; do
    local newname="${c//\./-}"
    if [ ! -s "$dir/${newname}.log" ] 2>/dev/null; then
      if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$c"; then
        docker logs "$c" --tail "$TAIL_LINES" 2>&1 > "$dir/${newname}.log" && log_info "  $c (old) ✓" || true
      fi
    fi
  done
}

# --- Поиск логов в директориях ---
find_log_dirs() {
  local dirs=()
  [ -d "unicchat_logs" ] && dirs+=("unicchat_logs")
  [ -d "logs_20260216_105804" ] && dirs+=("logs_20260216_105804")
  for d in logs_*/; do
    [ -d "$d" ] && dirs+=("$d")
  done
  echo "${dirs[@]}"
}

# --- Анализ одного файла ---
analyze_file() {
  local file="$1"
  local name
  name=$(basename "$file" .log | sed 's/unicchat[-.]//')

  [ ! -f "$file" ] || [ ! -s "$file" ] && return

  local errors=0 push_errors=0
  errors=$(grep -ciE 'error|ECONNREFUSED|fail|Unable to authenticate|not authorized|\[31m|\[35m\[F\]' "$file" 2>/dev/null | tr -d ' \n') || true
  push_errors=$(grep -c "ECONNREFUSED 127.0.0.1:80" "$file" 2>/dev/null | tr -d ' \n') || true
  errors=${errors:-0}
  push_errors=${push_errors:-0}

  # Ключевые успешные события
  local has_mongo=0 has_kbt=0 has_server_running=0 has_done=0
  grep -q "MongoDB.*Connection" "$file" 2>/dev/null && has_mongo=1
  grep -q "KBTConfigs\|Secret accessed" "$file" 2>/dev/null && has_kbt=1
  grep -q "SERVER RUNNING\|Application started" "$file" 2>/dev/null && has_server_running=1
  grep -q "Getting configs from Vault... Done" "$file" 2>/dev/null && has_done=1

  echo ""
  echo "=== $name ==="
  if [ "$errors" -gt 0 ] 2>/dev/null; then
    echo "  Ошибок: $errors"
    [ "$push_errors" -gt 0 ] 2>/dev/null && echo "  ⚠ Push Gateway: ECONNREFUSED 127.0.0.1:80 (указать LICENSE_HOST в appserver.env)"
    grep -iE 'error|ECONNREFUSED|fail|Unable to authenticate' "$file" 2>/dev/null | head -5 | while read -r line; do
      echo "    └ ${line:0:100}..."
    done || true
  else
    echo "  Ошибок: 0 ✓"
  fi
  [ "$has_mongo" -eq 1 ] && echo "  MongoDB: подключён ✓"
  [ "$has_kbt" -eq 1 ] && echo "  KBTConfigs: OK ✓"
  [ "$has_server_running" -eq 1 ] && echo "  Сервис: запущен ✓"
  [ "$has_done" -eq 1 ] && echo "  Vault configs: Done ✓"
}

# --- Основной анализ ---
run_analysis() {
  set +e  # не прерывать на ошибках grep
  local dir="${1:-}"
  if [ -z "$dir" ]; then
    local dirs=($(find_log_dirs))
    [ ${#dirs[@]} -eq 0 ] && { log_error "Нет директорий с логами. Запустите с --collect"; exit 1; }
    dir="${dirs[0]}"
    log_info "Используется директория: $dir"
  fi

  echo ""
  echo "=========================================="
  echo "  ОТЧЁТ АНАЛИЗА ЛОГОВ UnicChat Enterprise"
  echo "  Директория: $dir"
  echo "  Дата: $(date)"
  echo "=========================================="

  for f in "$dir"/*.log; do
    [ -f "$f" ] && analyze_file "$f"
  done

  echo ""
  echo "--- Сводка по ошибкам ---"
  local total_errors=0
  total_errors=$(grep -rhiE 'error|ECONNREFUSED|Unable to authenticate|\[31m|\[35m\[F\]' "$dir"/*.log 2>/dev/null | wc -l) || true
  total_errors=${total_errors:-0}
  if [ "$total_errors" -gt 0 ] 2>/dev/null; then
    log_warn "Всего найдено ошибок/предупреждений: $total_errors"
  else
    log_info "Критических ошибок не обнаружено."
  fi
}

# --- Вывод справки ---
usage() {
  cat << EOF
Использование: $0 [--collect] [--analyze [DIR]] [--all]

  --collect     Собрать логи из Docker в unicchat_logs/
  --analyze     Анализировать логи (DIR — путь к папке с логами)
  --all         Собрать и проанализировать (по умолчанию)
  -d DIR        Директория для логов (по умолчанию: unicchat_logs)
  -n N          Строк лога с контейнера (по умолчанию: 200)

Примеры:
  sudo $0 --collect              # Только сбор
  $0 --analyze unicchat_logs     # Только анализ
  sudo $0 --all                  # Сбор + анализ
  sudo $0 -n 500                 # Собрать по 500 строк и проанализировать

EOF
}

# --- Main ---
ANALYZE_ONLY=0
COLLECT_ONLY=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --collect) COLLECT_ONLY=1 ;;
    --analyze) ANALYZE_ONLY=1; TARGET_DIR="${2:-}"; shift ;;
    --all) ;;
    -d) LOG_DIR="$2"; shift ;;
    -n) TAIL_LINES="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) TARGET_DIR="$1" ;;
  esac
  shift
done

cd "$(dirname "$0")"

if [ "$COLLECT_ONLY" -eq 1 ]; then
  collect_logs "$LOG_DIR"
  log_info "Логи сохранены в $LOG_DIR/"
  exit 0
fi

if [ "$ANALYZE_ONLY" -eq 1 ]; then
  run_analysis "$TARGET_DIR"
  exit 0
fi

# По умолчанию: собрать (если docker доступен) и анализировать
if docker info >/dev/null 2>&1; then
  collect_logs "$LOG_DIR"
else
  log_warn "Docker недоступен, анализ существующих логов..."
fi
run_analysis "$LOG_DIR"
