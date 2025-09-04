#!/usr/bin/env bash
#
# Automated deployment script for UNICCHAT knowledge base
# Updated: September 05, 2025
#

set -euo pipefail

# Ensure running as root or via sudo
if [[ $EUID -ne 0 ]]; then
  echo "🚫 This script must be run as root or with sudo."
  exit 1
fi

# Paths and variables
BASE_DIR="$(pwd)"
CONFIG_FILE="$BASE_DIR/config.txt"
HOSTS_FILE="/etc/hosts"
LOG_FILE="$BASE_DIR/deploy.log"
MINIO_COMPOSE="$BASE_DIR/minio/docker-compose.yml"
ONLYOFFICE_COMPOSE="$BASE_DIR/Docker-DocumentServer/docker-compose.yml"
MINIO_ENV="$BASE_DIR/minio/minio_env.env"
ONLYOFFICE_ENV="$BASE_DIR/Docker-DocumentServer/onlyoffice_env.env"

# Variables to be loaded from config.txt
MINIO_ROOT_USER=""
MINIO_ROOT_PASSWORD=""
DB_TYPE=""
DB_HOST=""
DB_PORT=""
DB_NAME=""
DB_USER=""
WOPI_ENABLED=""
AMQP_URI=""
JWT_ENABLED=""
ALLOW_PRIVATE_IP_ADDRESS=""
ALLOW_META_IP_ADDRESS=""
USE_UNAUTHORIZED_STORAGE=""
MINIO_DNS=""
ONLYOFFICE_DNS=""
LOCAL_IP=""

# Function for logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if required dependencies are installed
check_deps() {
  log "Проверка зависимостей..."
  for cmd in git curl docker; do
    if ! command -v "$cmd" &> /dev/null; then
      log "Ошибка: $cmd не установлен."
      exit 1
    fi
  done
  log "✅ Зависимости проверены"
}

# Check if docker compose is available
check_docker_compose() {
  if ! docker compose version &> /dev/null; then
    log "Ошибка: docker compose не установлен."
    exit 1
  fi
}

# Step 1: Load variables from config.txt
load_config() {
  log "Шаг 1: Загрузка переменных из $CONFIG_FILE..."
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    required_vars=(
      "MINIO_ROOT_USER" "MINIO_ROOT_PASSWORD" "DB_TYPE" "DB_HOST" "DB_PORT"
      "DB_NAME" "DB_USER" "WOPI_ENABLED" "AMQP_URI" "JWT_ENABLED"
      "ALLOW_PRIVATE_IP_ADDRESS" "ALLOW_META_IP_ADDRESS" "USE_UNAUTHORIZED_STORAGE"
      "MINIO_DNS" "ONLYOFFICE_DNS" "LOCAL_IP"
    )
    for var in "${required_vars[@]}"; do
      if [ -z "${!var}" ]; then
        log "Ошибка: Переменная $var не найдена в $CONFIG_FILE."
        exit 1
      fi
    done
    log "✅ Переменные загружены из $CONFIG_FILE"
  else
    log "❌ Файл $CONFIG_FILE не найден."
    exit 1
  fi
}

# Step 3: Local network placement
setup_local_network() {
  log "Шаг 2: Размещение в локальной сети"
  # Check for duplicates in /etc/hosts
  if ! grep -q "$MINIO_DNS" "$HOSTS_FILE"; then
    echo "$LOCAL_IP $MINIO_DNS" >> "$HOSTS_FILE"
  fi
  if ! grep -q "$ONLYOFFICE_DNS" "$HOSTS_FILE"; then
    echo "$LOCAL_IP $ONLYOFFICE_DNS" >> "$HOSTS_FILE"
  fi
  log "✅ /etc/hosts обновлен"
}

# Step 4: Deploy MinIO
deploy_minio() {
  log "Шаг 3: Развертывание MinIO"
  check_docker_compose
  
  # Remove version attribute from docker-compose.yml
  sed -i '/^version:/d' "$MINIO_COMPOSE"
  
  # Create minio network if it doesn't exist
  if ! docker network ls | grep -q "minio"; then
    log "Создание внешней сети minio..."
    docker network create minio
  fi
  
  mkdir -p "$(dirname "$MINIO_ENV")"
  cat > "$MINIO_ENV" << EOF
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
EOF
  
  cd "$BASE_DIR/minio"
  docker compose up -d
  
  # Create bucket
  sleep 10
  docker exec unic.chat.minio mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
  docker exec unic.chat.minio mc mb local/uc.onlyoffice.docs || true
  docker exec unic.chat.minio mc anonymous set public local/uc.onlyoffice.docs || true
  log "✅ MinIO развернут. Консоль: http://$MINIO_DNS:9002, Bucket: uc.onlyoffice.docs (public)"
}

# Step 5: Deploy OnlyOffice
deploy_onlyoffice() {
  log "Шаг 4: Развертывание OnlyOffice"
  check_docker_compose
  
  # Remove version attribute from docker-compose.yml
  sed -i '/^version:/d' "$ONLYOFFICE_COMPOSE"
  
  mkdir -p "$(dirname "$ONLYOFFICE_ENV")"
  cat > "$ONLYOFFICE_ENV" << EOF
DB_TYPE=$DB_TYPE
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
WOPI_ENABLED=$WOPI_ENABLED
AMQP_URI=$AMQP_URI
JWT_ENABLED=$JWT_ENABLED
ALLOW_PRIVATE_IP_ADDRESS=$ALLOW_PRIVATE_IP_ADDRESS
ALLOW_META_IP_ADDRESS=$ALLOW_META_IP_ADDRESS
USE_UNAUTHORIZED_STORAGE=$USE_UNAUTHORIZED_STORAGE
EOF
  
  cd "$BASE_DIR/Docker-DocumentServer"
  docker compose up -d
  log "✅ OnlyOffice развернут. Доступ: http://$ONLYOFFICE_DNS:8880"
}

# Main function for automatic deployment
auto_deploy() {
  log "Начало автоматического развертывания базы знаний"
  check_deps
  load_config
  setup_local_network
  deploy_minio
  deploy_onlyoffice
  log "✅ Развертывание базы знаний завершено!"
}

# Check if auto mode is requested
if [[ "${1:-}" == "--auto" ]]; then
  auto_deploy
  exit 0
fi

# Manual mode with simple menu
echo "Выберите действие:"
echo "1. Автоматическое развертывание базы знаний"
echo "2. Выход"
read -rp "Ваш выбор: " choice

case $choice in
  1) auto_deploy ;;
  2) echo "👋 Выход" && exit 0 ;;
  *) echo "❌ Неверный выбор" && exit 1 ;;
esac
