#!/usr/bin/env bash
#
# Automated deployment script for UNICCHAT knowledge base (based on readme.md)
# Updated: September 04, 2025
#

set -euo pipefail

# Ensure running as root or via sudo
if [[ $EUID -ne 0 ]]; then
  echo "🚫 This script must be run as root or with sudo."
  exit 1
fi

# Paths and variables
BASE_DIR="$(pwd)"
REPO_URL="https://github.com/unicommorg/unicchat.enterprise.git"
REPO_BRANCH="skonstantinov-patch-2"
CONFIG_FILE="$BASE_DIR/config.txt"
HOSTS_FILE="/etc/hosts"
LOG_FILE="$BASE_DIR/deploy.log"
MINIO_COMPOSE="$BASE_DIR/unicchat.enterprise/knowledgebase/minio/docker-compose.yml"
ONLYOFFICE_COMPOSE="$BASE_DIR/unicchat.enterprise/knowledgebase/Docker-DocumentServer/docker-compose.yml"
MINIO_ENV="$BASE_DIR/unicchat.enterprise/knowledgebase/minio/minio_env.env"
ONLYOFFICE_ENV="$BASE_DIR/unicchat.enterprise/knowledgebase/Docker-DocumentServer/onlyoffice_env.env"

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
  for cmd in git curl; do
    if ! command -v "$cmd" &> /dev/null; then
      log "Ошибка: $cmd не установлен. Установите его с помощью: sudo apt install -y $cmd"
      exit 1
    fi
  done
  # Install MinIO client if not present
  if ! command -v mc &> /dev/null; then
    log "Установка MinIO клиента (mc)..."
    curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
  fi
  log "✅ Зависимости проверены"
}

# Check if docker compose is available
check_docker_compose() {
  if ! docker compose version &> /dev/null; then
    log "Ошибка: docker compose не установлен или Docker демон не работает."
    log "Убедитесь, что Docker установлен и работает. Выполните следующие команды:"
    log "  sudo apt update"
    log "  sudo apt install -y docker.io docker-compose-plugin"
    log "  sudo systemctl start docker"
    log "  sudo systemctl enable docker"
    log "Проверьте статус: sudo systemctl status docker"
    exit 1
  fi
}

# Step 1: Load or prompt for variables from config.txt
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
    log "🔧 Файл $CONFIG_FILE не найден. Запрашиваем переменные..."
    # MinIO variables
    while [ -z "$MINIO_ROOT_USER" ]; do
      read -rp "Введите MINIO_ROOT_USER (например, minioadmin): " MINIO_ROOT_USER
    done
    while [ -z "$MINIO_ROOT_PASSWORD" ]; do
      read -rp "Введите MINIO_ROOT_PASSWORD: " MINIO_ROOT_PASSWORD
    done
    # OnlyOffice variables
    while [ -z "$DB_TYPE" ]; do
      read -rp "Введите DB_TYPE (например, postgres): " DB_TYPE
    done
    while [ -z "$DB_HOST" ]; do
      read -rp "Введите DB_HOST (например, onlyoffice-postgresql): " DB_HOST
    done
    while [ -z "$DB_PORT" ]; do
      read -rp "Введите DB_PORT (например, 5432): " DB_PORT
    done
    while [ -z "$DB_NAME" ]; do
      read -rp "Введите DB_NAME (например, dbname): " DB_NAME
    done
    while [ -z "$DB_USER" ]; do
      read -rp "Введите DB_USER (например, dbuser): " DB_USER
    done
    while [ -z "$WOPI_ENABLED" ]; do
      read -rp "Введите WOPI_ENABLED (true/false): " WOPI_ENABLED
    done
    while [ -z "$AMQP_URI" ]; do
      read -rp "Введите AMQP_URI (например, amqp://guest:guest@onlyoffice-rabbitmq): " AMQP_URI
    done
    while [ -z "$JWT_ENABLED" ]; do
      read -rp "Введите JWT_ENABLED (true/false): " JWT_ENABLED
    done
    while [ -z "$ALLOW_PRIVATE_IP_ADDRESS" ]; do
      read -rp "Введите ALLOW_PRIVATE_IP_ADDRESS (true/false): " ALLOW_PRIVATE_IP_ADDRESS
    done
    while [ -z "$ALLOW_META_IP_ADDRESS" ]; do
      read -rp "Введите ALLOW_META_IP_ADDRESS (true/false): " ALLOW_META_IP_ADDRESS
    done
    while [ -z "$USE_UNAUTHORIZED_STORAGE" ]; do
      read -rp "Введите USE_UNAUTHORIZED_STORAGE (true/false): " USE_UNAUTHORIZED_STORAGE
    done
    # DNS and IP variables
    while [ -z "$MINIO_DNS" ]; do
      read -rp "Введите DNS для minio (например, myminio.unic.chat): " MINIO_DNS
    done
    while [ -z "$ONLYOFFICE_DNS" ]; do
      read -rp "Введите DNS для onlyoffice (например, myonlyoffice.unic.chat): " ONLYOFFICE_DNS
    done
    while [ -z "$LOCAL_IP" ]; do
      read -rp "Введите локальный IP для hosts (например, 10.0.XX.XX): " LOCAL_IP
    done
    # Save to config.txt
    cat > "$CONFIG_FILE" << EOF
# MinIO variables
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD

# OnlyOffice variables
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

# DNS and IP variables
MINIO_DNS=$MINIO_DNS
ONLYOFFICE_DNS=$ONLYOFFICE_DNS
LOCAL_IP=$LOCAL_IP
EOF
    log "✅ Переменные сохранены в $CONFIG_FILE"
  fi
}

# Step 2: Server preparation
prepare_server() {
  log "Шаг 2: Подготовка сервера"
  # Clone repo if not exists
  if [ ! -d "unicchat.enterprise" ]; then
    git clone -b "$REPO_BRANCH" "$REPO_URL" unicchat.enterprise
  fi
  cd unicchat.enterprise
  git fetch --all && git checkout "$REPO_BRANCH"
  cd ..
  # Check directories
  for dir in knowledgebase knowledgebase/minio knowledgebase/Docker-DocumentServer; do
    if [ ! -d "$BASE_DIR/unicchat.enterprise/$dir" ]; then
      log "Ошибка: Директория $dir не найдена"
      exit 1
    fi
  done
  log "✅ Сервер подготовлен"
}

# Step 3: Local network placement
setup_local_network() {
  log "Шаг 3: Размещение в локальной сети"
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
  log "Шаг 4: Развертывание MinIO"
  # Check if config is loaded
  if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ] || [ -z "$MINIO_DNS" ]; then
    log "Ошибка: Не загружены переменные MINIO_ROOT_USER, MINIO_ROOT_PASSWORD или MINIO_DNS. Выполните шаг 1."
    exit 1
  fi
  # Check if docker-compose.yml exists
  if [ ! -f "$MINIO_COMPOSE" ]; then
    log "Ошибка: Файл $MINIO_COMPOSE не найден. Выполните шаг 2."
    exit 1
  fi
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
  cd "$BASE_DIR/unicchat.enterprise/knowledgebase/minio"
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
  log "Шаг 5: Развертывание OnlyOffice"
  # Check if config is loaded
  if [ -z "$DB_TYPE" ] || [ -z "$DB_HOST" ] || [ -z "$ONLYOFFICE_DNS" ]; then
    log "Ошибка: Не загружены переменные DB_TYPE, DB_HOST или ONLYOFFICE_DNS. Выполните шаг 1."
    exit 1
  fi
  # Check if docker-compose.yml exists
  if [ ! -f "$ONLYOFFICE_COMPOSE" ]; then
    log "Ошибка: Файл $ONLYOFFICE_COMPOSE не найден. Выполните шаг 2."
    exit 1
  fi
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
  cd "$BASE_DIR/unicchat.enterprise/knowledgebase/Docker-DocumentServer"
  docker compose up -d
  log "✅ OnlyOffice развернут. Доступ: http://$ONLYOFFICE_DNS:8880"
}

# Function to display menu and get user input
select_steps() {
  echo "Выберите шаги для выполнения (введите номера шагов через пробел, например '1 2 4', '0' или Enter для автоустановки, 'exit' для выхода):"
  echo "1. Загрузка переменных из config.txt"
  echo "2. Подготовка сервера (клонирование репозитория)"
  echo "3. Размещение в локальной сети (/etc/hosts)"
  echo "4. Развертывание MinIO"
  echo "5. Развертывание OnlyOffice"
  read -rp "Ваш выбор: " steps

  if [ "$steps" = "exit" ]; then
    log "🚪 Выход из скрипта"
    exit 0
  elif [ -z "$steps" ] || [ "$steps" = "0" ]; then
    STEPS=("1" "2" "3" "4" "5")
  else
    # Convert input to array
    read -ra STEPS <<< "$steps"
    # Validate input
    for step in "${STEPS[@]}"; do
      if ! [[ "$step" =~ ^[1-5]$ ]]; then
        echo "Ошибка: Неверный номер шага '$step'. Допустимы номера от 1 до 5, '0', Enter или 'exit'."
        return 1
      fi
    done
  fi
  return 0
}

# Main function
auto_deploy() {
  log "Начало развертывания"
  check_deps
  while true; do
    select_steps
    if [ $? -eq 0 ]; then
      for step in "${STEPS[@]}"; do
        case $step in
          1) load_config ;;
          2) prepare_server ;;
          3) setup_local_network ;;
          4) deploy_minio ;;
          5) deploy_onlyoffice ;;
        esac
      done
      log "✅ Выполнение выбранных шагов завершено"
    fi
    echo "Нажмите Enter для возврата в меню или Ctrl+C для выхода"
    read -r
  done
}

# Execute
auto_deploy
