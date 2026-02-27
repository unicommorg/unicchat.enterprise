#!/usr/bin/env bash
#
# UnicChat Enterprise Installation Helper
# Refactored version with multi-service DNS support
#

set -euo pipefail

# Ensure running as root or via sudo
if [[ $EUID -ne 0 ]]; then
  echo "🚫 This script must be run as root or with sudo."
  exit 1
fi

# Check if Docker is installed
check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker не установлен. Установите Docker и повторите попытку."
    exit 1
  fi
  
  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
    if ! command -v docker-compose >/dev/null 2>&1; then
      echo "❌ Docker Compose не установлен. Установите Docker Compose и повторите попытку."
      exit 1
    fi
  fi
  
  if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon не запущен. Запустите Docker: sudo systemctl start docker"
    exit 1
  fi
}

# Configuration files
DNS_CONFIG_FILE="dns_config.txt"
MONGO_CONFIG_FILE="mongo_config.txt"
MINIO_CONFIG_FILE="minio_config.txt"
LOG_FILE="unicchat_install.log"

# DNS variables
APP_DNS=""
EDT_DNS=""
MINIO_DNS=""

# === Helper Functions ===

log_info() {
  echo "📝 $1" | tee -a "$LOG_FILE"
}

log_success() {
  echo "✅ $1" | tee -a "$LOG_FILE"
}

log_warning() {
  echo "⚠️ $1" | tee -a "$LOG_FILE"
}

log_error() {
  echo "❌ $1" | tee -a "$LOG_FILE"
}

# Enhanced docker_compose function with better compatibility
docker_compose() {
  local compose_file="${COMPOSE_FILE:--f docker-compose.yml}"
  
  # Try docker compose (plugin) first
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
    return $?
  # Fall back to docker-compose (standalone)
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
    return $?
  else
    log_error "Neither 'docker compose' nor 'docker-compose' found."
    log_info "Please install Docker Compose:"
    log_info "  - Plugin: https://docs.docker.com/compose/install/"
    log_info "  - Standalone: apt-get install docker-compose"
    exit 1
  fi
}

check_avx() {
  echo -e "\n🧠 Checking CPU for AVX…"
  if grep -m1 -q avx /proc/cpuinfo; then
    log_success "AVX supported. You can use MongoDB 5.x+"
  else
    log_warning "No AVX support. Use MongoDB 4.4 or lower"
  fi
}

# === DNS Configuration ===

load_dns_config() {
  if [ -f "$DNS_CONFIG_FILE" ]; then
    log_info "Loading DNS configuration from $DNS_CONFIG_FILE..."
    source "$DNS_CONFIG_FILE"
    
    if [ -n "$APP_DNS" ] && [ -n "$EDT_DNS" ] && [ -n "$MINIO_DNS" ]; then
      log_success "DNS names loaded from config"
      return 0
    fi
  fi
  return 1
}

setup_dns_names() {
  echo -e "\n🌐 Setting up DNS names for UnicChat services..."
  
  if load_dns_config; then
    log_success "DNS names loaded from config:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    echo "   Push/License: ${PUSH_DNS:-push1.unic.chat}"
    
    read -rp "Do you want to change these? (y/N): " change
    if [[ ! "$change" =~ ^[Yy]$ ]]; then
      return 0
    fi
  fi
  
  echo ""
  echo "Enter DNS names for each service:"
  read -rp "  App Server DNS (e.g., app.unic.chat): " APP_DNS
  read -rp "  Document Server DNS (e.g., docs.unic.chat): " EDT_DNS
  read -rp "  MinIO DNS (e.g., minio.unic.chat): " MINIO_DNS
  read -rp "  Push/License Server DNS (e.g., push1.unic.chat) [default: push1.unic.chat]: " PUSH_DNS
  PUSH_DNS=${PUSH_DNS:-push1.unic.chat}
  
  # Validate
  if [ -z "$APP_DNS" ] || [ -z "$EDT_DNS" ] || [ -z "$MINIO_DNS" ]; then
    log_error "All DNS names are required!"
    return 1
  fi
  
  # Save configuration
  cat > "$DNS_CONFIG_FILE" <<EOF
# UnicChat DNS Configuration
APP_DNS="$APP_DNS"
EDT_DNS="$EDT_DNS"
MINIO_DNS="$MINIO_DNS"
PUSH_DNS="$PUSH_DNS"
EOF
  
  log_success "DNS configuration saved to $DNS_CONFIG_FILE"
  
  # Check DNS resolution
  echo ""
  echo "🔍 Checking DNS resolution..."
  for dns in "$APP_DNS" "$EDT_DNS" "$MINIO_DNS"; do
    echo -n "  $dns: "
    if dig +short "$dns" | grep -q .; then
      echo "✅ Resolved"
    else
      echo "⚠️ Not resolved (configure your DNS or /etc/hosts)"
    fi
  done
  
  # Export for docker-compose
  export APP_DNS EDT_DNS MINIO_DNS PUSH_DNS
}

# === URL Encoding ===

urlencode() {
  local string="$1"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [-_.~a-zA-Z0-9] ) o="${c}" ;;
      * ) printf -v o '%%%02x' "'$c"
    esac
    encoded+="${o}"
  done
  echo "${encoded}"
}

urldecode() {
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}

# === MongoDB Configuration ===

update_mongo_config() {
  echo -e "\n🔧 Updating MongoDB configuration..."
  
  local mongo_config_file="$MONGO_CONFIG_FILE"
  
  if [ ! -f "$mongo_config_file" ]; then
    log_info "File $mongo_config_file not found, creating new."
    touch "$mongo_config_file"
  fi
  
  update_config() {
    local key=$1
    local value=$2
    local file=$3
    if grep -q "^$key=" "$file" 2>/dev/null; then
      sed -i "s|^$key=.*|$key=\"$value\"|" "$file"
    else
      echo "$key=\"$value\"" >> "$file"
    fi
    log_success "Updated: $key"
  }
  
  get_value_from_config() {
    local key=$1
    local value
    if grep -q "^$key=" "$mongo_config_file" 2>/dev/null; then
      value=$(grep "^$key=" "$mongo_config_file" | cut -d'=' -f2 | tr -d '"')
      echo "$value"
    else
      echo ""
    fi
  }
  
  prompt_value() {
    local key=$1
    local prompt=$2
    local default=$3
    local value
    
    local current=$(get_value_from_config "$key")
    local show_default="${current:-$default}"
    
    read -rp "$prompt [default: $show_default]: " value
    value=${value:-$show_default}
    
    update_config "$key" "$value" "$mongo_config_file"
  }
  
  echo "📦 Main MongoDB credentials:"
  prompt_value "MONGODB_ROOT_PASSWORD" "  MongoDB root password" "rootpass"
  prompt_value "MONGODB_USERNAME" "  MongoDB admin username" "unicchat_admin"
  prompt_value "MONGODB_PASSWORD" "  MongoDB admin password" "secure_password_123"
  prompt_value "MONGODB_DATABASE" "  MongoDB database name" "unicchat_db"
  
  echo ""
  echo "🔐 Logger service credentials:"
  prompt_value "LOGGER_USER" "  Logger MongoDB username" "logger_user"
  prompt_value "LOGGER_PASSWORD" "  Logger MongoDB password" "logger_pass_123"
  prompt_value "LOGGER_DB" "  Logger database name" "logger_db"
  
  echo ""
  echo "🔐 Vault service credentials:"
  prompt_value "VAULT_USER" "  Vault MongoDB username" "vault_user"
  prompt_value "VAULT_PASSWORD" "  Vault MongoDB password" "vault_pass_123"
  prompt_value "VAULT_DB" "  Vault database name" "vault_db"
  
  log_success "MongoDB configuration updated in $mongo_config_file"
}

# === MinIO Configuration ===

update_minio_config() {
  echo -e "\n🔧 Updating MinIO configuration..."
  
  local minio_config_file="$MINIO_CONFIG_FILE"
  
  if [ ! -f "$minio_config_file" ]; then
    log_info "File $minio_config_file not found, creating new."
    touch "$minio_config_file"
  fi
  
  update_config() {
    local key=$1
    local value=$2
    local file=$3
    if grep -q "^$key=" "$file" 2>/dev/null; then
      sed -i "s|^$key=.*|$key=\"$value\"|" "$file"
    else
      echo "$key=\"$value\"" >> "$file"
    fi
    log_success "Updated: $key"
  }
  
  get_value_from_config() {
    local key=$1
    local value
    if grep -q "^$key=" "$minio_config_file" 2>/dev/null; then
      value=$(grep "^$key=" "$minio_config_file" | cut -d'=' -f2 | tr -d '"')
      echo "$value"
    else
      echo ""
    fi
  }
  
  prompt_value() {
    local key=$1
    local prompt=$2
    local default=$3
    local value
    
    local current=$(get_value_from_config "$key")
    local show_default="${current:-$default}"
    
    read -rp "$prompt [default: $show_default]: " value
    value=${value:-$show_default}
    
    update_config "$key" "$value" "$minio_config_file"
  }
  
  echo "🪣 MinIO credentials:"
  prompt_value "MINIO_ROOT_USER" "  MinIO root user" "minioadmin"
  prompt_value "MINIO_ROOT_PASSWORD" "  MinIO root password" "minioadmin123"
  
  log_success "MinIO configuration updated in $minio_config_file"
}

# === Environment Files Generation ===

prepare_all_envs() {
  echo -e "\n📦 Preparing all environment files…"
  
  local dir="multi-server-install"
  
  # Load MongoDB configuration
  if [ ! -f "$MONGO_CONFIG_FILE" ]; then
    log_warning "$MONGO_CONFIG_FILE not found. Run 'Update MongoDB configuration' first."
    return 1
  fi
  
  source "$MONGO_CONFIG_FILE"
  
  # Load MinIO configuration
  if [ ! -f "$MINIO_CONFIG_FILE" ]; then
    log_warning "$MINIO_CONFIG_FILE not found. Run 'Update MinIO configuration' first."
    return 1
  fi
  
  source "$MINIO_CONFIG_FILE"
  
  # Load DNS configuration
  if [ ! -f "$DNS_CONFIG_FILE" ]; then
    log_warning "$DNS_CONFIG_FILE not found. Run 'Setup DNS names' first."
    return 1
  fi
  
  source "$DNS_CONFIG_FILE"
  
  # Default values if not set
  MONGODB_REPLICA_SET_MODE=${MONGODB_REPLICA_SET_MODE:-primary}
  MONGODB_REPLICA_SET_NAME=${MONGODB_REPLICA_SET_NAME:-rs0}
  MONGODB_REPLICA_SET_KEY=${MONGODB_REPLICA_SET_KEY:-rs0key}
  MONGODB_PORT_NUMBER=${MONGODB_PORT_NUMBER:-27017}
  MONGODB_INITIAL_PRIMARY_HOST=${MONGODB_INITIAL_PRIMARY_HOST:-unicchat-mongodb}
  MONGODB_INITIAL_PRIMARY_PORT_NUMBER=${MONGODB_INITIAL_PRIMARY_PORT_NUMBER:-27017}
  MONGODB_ADVERTISED_HOSTNAME=${MONGODB_ADVERTISED_HOSTNAME:-unicchat-mongodb}
  MONGODB_ENABLE_JOURNAL=${MONGODB_ENABLE_JOURNAL:-true}
  MONGODB_ROOT_PASSWORD=${MONGODB_ROOT_PASSWORD:-rootpass}
  MONGODB_USERNAME=${MONGODB_USERNAME:-unicchat_admin}
  MONGODB_PASSWORD=${MONGODB_PASSWORD:-secure_password_123}
  MONGODB_DATABASE=${MONGODB_DATABASE:-unicchat_db}
  
  # Service defaults
  LOGGER_USER=${LOGGER_USER:-logger_user}
  LOGGER_PASSWORD=${LOGGER_PASSWORD:-logger_pass_123}
  LOGGER_DB=${LOGGER_DB:-logger_db}
  
  VAULT_USER=${VAULT_USER:-vault_user}
  VAULT_PASSWORD=${VAULT_PASSWORD:-vault_pass_123}
  VAULT_DB=${VAULT_DB:-vault_db}
  
  MINIO_ROOT_USER=${MINIO_ROOT_USER:-minioadmin}
  MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-minioadmin123}
  
  # Generate mongo.env
  cat > "$dir/mongo.env" << EOL
# Replica Set Configuration
MONGODB_REPLICA_SET_MODE=$MONGODB_REPLICA_SET_MODE
MONGODB_REPLICA_SET_NAME=$MONGODB_REPLICA_SET_NAME
MONGODB_REPLICA_SET_KEY=$MONGODB_REPLICA_SET_KEY
MONGODB_PORT_NUMBER=$MONGODB_PORT_NUMBER
MONGODB_INITIAL_PRIMARY_HOST=$MONGODB_INITIAL_PRIMARY_HOST
MONGODB_INITIAL_PRIMARY_PORT_NUMBER=$MONGODB_INITIAL_PRIMARY_PORT_NUMBER
MONGODB_ADVERTISED_HOSTNAME=$MONGODB_ADVERTISED_HOSTNAME
MONGODB_ENABLE_JOURNAL=$MONGODB_ENABLE_JOURNAL
EOL
  log_success "Generated $dir/mongo.env"
  
  # Generate mongo_creds.env
  cat > "$dir/mongo_creds.env" << EOL
# MongoDB Authentication
MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD
MONGODB_USERNAME=$MONGODB_USERNAME
MONGODB_PASSWORD=$MONGODB_PASSWORD
MONGODB_DATABASE=$MONGODB_DATABASE
EOL
  chmod 600 "$dir/mongo_creds.env" 2>/dev/null || true
  log_success "Generated $dir/mongo_creds.env"
  
  # LICENSE_HOST for Push Gateway (default: https://push1.unic.chat/)
  LICENSE_HOST="${LICENSE_HOST:-https://${PUSH_DNS:-push1.unic.chat}/}"
  
  # Generate appserver.env (public configuration)
  cat > "$dir/appserver.env" << EOL
# UnicChat AppServer Configuration
ROOT_URL=https://$APP_DNS
DOCUMENT_SERVER_HOST=https://$EDT_DNS
LICENSE_HOST=$LICENSE_HOST
PORT=3000
DEPLOY_METHOD=docker
DB_COLLECTIONS_PREFIX=unicchat_
MONGODB_HOST=$MONGODB_INITIAL_PRIMARY_HOST
MONGODB_PORT=$MONGODB_PORT_NUMBER
EOL
  log_success "Generated $dir/appserver.env"
  
  # Generate appserver_creds.env (sensitive data)
  local mongo_url="mongodb://$MONGODB_USERNAME:$MONGODB_PASSWORD@$MONGODB_INITIAL_PRIMARY_HOST:$MONGODB_PORT_NUMBER/$MONGODB_DATABASE?replicaSet=$MONGODB_REPLICA_SET_NAME"
  local mongo_oplog_url="mongodb://$MONGODB_USERNAME:$MONGODB_PASSWORD@$MONGODB_INITIAL_PRIMARY_HOST:$MONGODB_PORT_NUMBER/local"
  
  cat > "$dir/appserver_creds.env" << EOL
# UnicChat AppServer Credentials (sensitive)
MONGO_URL=$mongo_url
MONGO_OPLOG_URL=$mongo_oplog_url
EOL
  chmod 600 "$dir/appserver_creds.env" 2>/dev/null || true
  log_success "Generated $dir/appserver_creds.env"
  
  # URL-encode passwords
  local LOGGER_PASSWORD_ENCODED=$(urlencode "$LOGGER_PASSWORD")
  local VAULT_PASSWORD_ENCODED=$(urlencode "$VAULT_PASSWORD")
  
  # Generate logger_creds.env
  cat > "$dir/logger_creds.env" << EOL
# MongoDB connection for logger service
MongoCS="mongodb://$LOGGER_USER:$LOGGER_PASSWORD_ENCODED@$MONGODB_INITIAL_PRIMARY_HOST:$MONGODB_PORT_NUMBER/$LOGGER_DB?directConnection=true&authSource=$LOGGER_DB&authMechanism=SCRAM-SHA-256"
EOL
  chmod 600 "$dir/logger_creds.env" 2>/dev/null || true
  log_success "Generated $dir/logger_creds.env"
  
  # Generate vault_creds.env
  cat > "$dir/vault_creds.env" << EOL
# MongoDB connection for vault service
MongoCS="mongodb://$VAULT_USER:$VAULT_PASSWORD_ENCODED@$MONGODB_INITIAL_PRIMARY_HOST:$MONGODB_PORT_NUMBER/$VAULT_DB?directConnection=true&authSource=$VAULT_DB&authMechanism=SCRAM-SHA-256"
EOL
  chmod 600 "$dir/vault_creds.env" 2>/dev/null || true
  log_success "Generated $dir/vault_creds.env"
  
  # Generate logger.env
  cat > "$dir/logger.env" << EOL
# Logger API URL (internal)
api.logger.url=http://unicchat-logger:8080/
EOL
  log_success "Generated $dir/logger.env"
  
  # Generate minio_env.env
  mkdir -p "$dir/env"
  cat > "$dir/env/minio_env.env" << EOL
# MinIO Configuration
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
MINIO_BROWSER=on
MINIO_DOMAIN=$MINIO_DNS
EOL
  log_success "Generated $dir/env/minio_env.env"
  
  # Generate documentserver_env.env
  cat > "$dir/env/documentserver_env.env" << EOL
# DocumentServer Configuration
JWT_ENABLED=true
JWT_SECRET=your_jwt_secret_here
JWT_HEADER=Authorization
DB_TYPE=postgres
DB_HOST=unicchat-postgresql
DB_PORT=5432
DB_NAME=dbname
DB_USER=dbuser
AMQP_URI=amqp://guest:guest@unicchat-rabbitmq
EOL
  log_success "Generated $dir/env/documentserver_env.env"
  
  echo ""
  log_success "All environment files prepared:"
  echo "   • mongo.env (replica set config)"
  echo "   • mongo_creds.env (authentication)"
  echo "   • logger_creds.env (Logger service MongoDB)"
  echo "   • vault_creds.env (Vault service MongoDB)"
  echo "   • appserver.env (AppServer public config)"
  echo "   • appserver_creds.env (AppServer credentials & Vault URL)"
  echo "   • logger.env (Logger API URL)"
  echo "   • env/minio_env.env (MinIO configuration)"
  echo "   • env/documentserver_env.env (DocumentServer)"
}

# === MongoDB Users Setup ===

setup_mongodb_users() {
  echo -e "\n🔐 Setting up MongoDB users for services…"
  local dir="multi-server-install"
  local container="unicchat-mongodb"
  
  # Wait for MongoDB container to appear (docker compose may report before container is in ps)
  local wait_attempts=15
  local w=0
  while [ $w -lt $wait_attempts ]; do
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$container"; then
      break
    fi
    w=$((w + 1))
    if [ $w -lt $wait_attempts ]; then
      echo "   ⏳ Waiting for MongoDB container... ($w/$wait_attempts)"
      sleep 3
    fi
  done
  if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$container"; then
    log_warning "MongoDB container is not running. Start services first (option 8)."
    return 1
  fi
  
  # Read root password
  local mongo_creds_file="$dir/mongo_creds.env"
  if [ ! -f "$mongo_creds_file" ]; then
    log_error "File $mongo_creds_file not found. Run 'Prepare .env files' first."
    return 1
  fi
  
  local root_password=$(grep '^MONGODB_ROOT_PASSWORD=' "$mongo_creds_file" | cut -d '=' -f2- | tr -d '\r')
  
  if [ -z "$root_password" ]; then
    log_error "MONGODB_ROOT_PASSWORD not found in $mongo_creds_file"
    return 1
  fi
  
  # Wait for MongoDB
  echo "⏳ Waiting for MongoDB to be ready..."
  local max_attempts=15
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if docker exec "$container" mongosh -u root -p "$root_password" --quiet --eval "db.adminCommand('ping')" 2>/dev/null | grep -q "ok.*1"; then
      log_success "MongoDB is ready"
      break
    fi
    attempt=$((attempt + 1))
    echo "  Attempt $attempt/$max_attempts..."
    sleep 2
  done
  
  if [ $attempt -eq $max_attempts ]; then
    log_warning "MongoDB is not ready after $max_attempts attempts. Trying to continue anyway..."
  fi
  
  # Create logger user
  local logger_creds_file="$dir/logger_creds.env"
  if [ -f "$logger_creds_file" ]; then
    local logger_mongocs=$(grep '^MongoCS=' "$logger_creds_file" | cut -d '=' -f2- | tr -d '\r' | sed 's/^"//;s/"$//')
    if [ -n "$logger_mongocs" ]; then
      local creds_part=$(echo "$logger_mongocs" | sed 's|^mongodb://||' | cut -d '@' -f1)
      local host_part=$(echo "$logger_mongocs" | sed 's|^mongodb://||' | cut -d '@' -f2)
      local logger_user=$(echo "$creds_part" | cut -d ':' -f1)
      local logger_pass_encoded=$(echo "$creds_part" | cut -d ':' -f2-)
      local logger_db=$(echo "$host_part" | cut -d '/' -f2 | cut -d '?' -f1)
      logger_db=${logger_db:-logger_db}
      
      local logger_pass
      if [[ "$logger_pass_encoded" == *%* ]]; then
        logger_pass=$(urldecode "$logger_pass_encoded")
      else
        logger_pass="$logger_pass_encoded"
      fi
      
      if [ -n "$logger_user" ] && [ -n "$logger_pass" ] && [ -n "$logger_db" ]; then
        echo "📝 Creating $logger_db and user $logger_user..."
        
        local temp_script=$(mktemp)
        cat > "$temp_script" <<EOF
use admin
db = db.getSiblingDB('$logger_db')
try {
  db.createUser({
    user: '$logger_user',
    pwd: '$logger_pass',
    roles: [{ role: 'readWrite', db: '$logger_db' }]
  })
  print('CREATED')
} catch(e) {
  if (e.code === 51003 || e.codeName === 'DuplicateKey' || e.message.includes('already exists')) {
    db.changeUserPassword('$logger_user', '$logger_pass')
    print('PASSWORD_UPDATED')
  } else {
    print('ERROR: ' + e.message)
    throw e
  }
}
EOF
        
        local create_output=$(timeout 30 docker exec -i "$container" mongosh -u root -p "$root_password" --authenticationDatabase admin < "$temp_script" 2>&1)
        rm -f "$temp_script"
        
        if echo "$create_output" | grep -qE "CREATED|PASSWORD_UPDATED"; then
          log_success "Logger user configured"
        else
          log_warning "Logger user configuration uncertain"
          echo "   Output: $(echo "$create_output" | grep -E "CREATED|PASSWORD_UPDATED|ERROR" | head -1)"
        fi
      fi
    fi
  fi
  
  # Create vault user
  local vault_env_file="$dir/vault_creds.env"
  if [ -f "$vault_env_file" ]; then
    local vault_mongocs=$(grep '^MongoCS=' "$vault_env_file" | cut -d '=' -f2- | tr -d '\r' | sed 's/^"//;s/"$//')
    if [ -n "$vault_mongocs" ]; then
      local creds_part=$(echo "$vault_mongocs" | sed 's|^mongodb://||' | cut -d '@' -f1)
      local host_part=$(echo "$vault_mongocs" | sed 's|^mongodb://||' | cut -d '@' -f2)
      local vault_user=$(echo "$creds_part" | cut -d ':' -f1)
      local vault_pass_encoded=$(echo "$creds_part" | cut -d ':' -f2-)
      local vault_db=$(echo "$host_part" | cut -d '/' -f2 | cut -d '?' -f1)
      vault_db=${vault_db:-vault_db}
      
      local vault_pass
      if [[ "$vault_pass_encoded" == *%* ]]; then
        vault_pass=$(urldecode "$vault_pass_encoded")
      else
        vault_pass="$vault_pass_encoded"
      fi
      
      if [ -n "$vault_user" ] && [ -n "$vault_pass" ] && [ -n "$vault_db" ]; then
        echo "📝 Creating $vault_db and user $vault_user..."
        
        local temp_script=$(mktemp)
        cat > "$temp_script" <<EOF
use admin
db = db.getSiblingDB('$vault_db')
try {
  db.createUser({
    user: '$vault_user',
    pwd: '$vault_pass',
    roles: [{ role: 'readWrite', db: '$vault_db' }]
  })
  print('CREATED')
} catch(e) {
  if (e.code === 51003 || e.codeName === 'DuplicateKey' || e.message.includes('already exists')) {
    db.changeUserPassword('$vault_user', '$vault_pass')
    print('PASSWORD_UPDATED')
  } else {
    print('ERROR: ' + e.message)
    throw e
  }
}
EOF
        
        local create_output=$(timeout 30 docker exec -i "$container" mongosh -u root -p "$root_password" --authenticationDatabase admin < "$temp_script" 2>&1)
        rm -f "$temp_script"
        
        if echo "$create_output" | grep -qE "CREATED|PASSWORD_UPDATED"; then
          log_success "Vault user configured"
        else
          log_warning "Vault user configuration uncertain"
          echo "   Output: $(echo "$create_output" | grep -E "CREATED|PASSWORD_UPDATED|ERROR" | head -1)"
        fi
      fi
    fi
  fi
  
  log_success "MongoDB users configured."
}

# === Vault Secrets Setup (with real values, using bash) ===

setup_vault_secrets() {
  echo -e "\n🔐 Setting up Vault secrets for KBT service…"
  local dir="multi-server-install"
  
  local container="unicchat-vault"
  # Wait for Vault container to be running (may need time after depends_on)
  local wait_attempts=12
  local w=0
  while [ $w -lt $wait_attempts ]; do
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$container"; then
      break
    fi
    w=$((w + 1))
    if [ $w -lt $wait_attempts ]; then
      echo "   ⏳ Waiting for Vault container... ($w/$wait_attempts)"
      sleep 3
    fi
  done
  if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$container"; then
    log_warning "Vault container is not running. Start services first (option 8)."
    return 1
  fi
  
  # Load MinIO configuration
  if [ ! -f "$MINIO_CONFIG_FILE" ]; then
    log_error "$MINIO_CONFIG_FILE not found. Run 'Update MinIO configuration' first."
    return 1
  fi
  
  source "$MINIO_CONFIG_FILE"
  
  # Load DNS configuration
  if [ ! -f "$DNS_CONFIG_FILE" ]; then
    log_error "$DNS_CONFIG_FILE not found. Run 'Setup DNS names' first."
    return 1
  fi
  
  source "$DNS_CONFIG_FILE"
  
  # Read MongoDB connection string
  local logger_creds_file="$dir/logger_creds.env"
  if [ ! -f "$logger_creds_file" ]; then
    log_error "File $logger_creds_file not found. Run 'Prepare .env files' first."
    return 1
  fi
  
  local mongo_url=$(grep '^MongoCS=' "$logger_creds_file" | cut -d '=' -f2- | tr -d '\r' | sed 's/^"//;s/"$//')
  if [ -z "$mongo_url" ]; then
    log_error "MongoCS not found in $logger_creds_file"
    return 1
  fi
  
  # Check and install curl in container if needed
  echo "🔧 Checking for curl in Vault container..."
  if ! docker exec "$container" bash -c "command -v curl >/dev/null 2>&1"; then
    echo "   Installing curl (this may take a moment)..."
    # Try with root user
    if docker exec -u root "$container" bash -c "apt-get update -qq && apt-get install -y -qq curl" >/dev/null 2>&1; then
      log_success "curl installed"
    elif docker exec "$container" bash -c "apt-get update -qq && apt-get install -y -qq curl" >/dev/null 2>&1; then
      log_success "curl installed"
    else
      log_error "Failed to install curl. Container may not have package manager access."
      echo "   Try manually: docker exec -u root unicchat-vault apt-get update && apt-get install -y curl"
      return 1
    fi
  else
    echo "   ✓ curl available"
  fi
  
  # Vault API configuration
  local vault_url="http://localhost:80"
  local token_id="0f8e160416b94225a73f86ac23b9118b"
  local username="KBTservice"
  
  echo "📝 Step 1: Checking Vault availability..."
  echo "   Container: $container"
  echo "   Vault URL (internal): $vault_url"
  echo "   Test endpoint: GET /api/token/$token_id?username=$username"
  
  echo "⏳ Waiting for Vault to be ready..."
  local max_attempts=15
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    echo "   Attempt $attempt/$max_attempts - checking Vault health..."
    if docker exec "$container" bash -c "curl -s -f '$vault_url/api/token/$token_id?username=$username' >/dev/null 2>&1"; then
      log_success "Vault is responding (attempt $attempt)"
      break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -lt $max_attempts ]; then
      echo "   ⏱️  Waiting 2 seconds before retry..."
      sleep 2
    fi
  done
  
  if [ $attempt -eq $max_attempts ]; then
    log_warning "Vault didn't respond after $max_attempts attempts, trying to continue anyway..."
  fi
  
  # Get token
  echo ""
  echo "📝 Step 2: Getting Vault authentication token..."
  echo "   Token ID: ${token_id:0:8}...${token_id:(-8)}"
  echo "   Username: $username"
  echo "   Request: GET $vault_url/api/token/$token_id?username=$username"
  echo "   Timeout: 30 seconds"
  echo "   🔄 Executing curl inside container..."
  
  local token_response=$(timeout 30 docker exec "$container" bash -c "curl -s -w '\nHTTP_CODE:%{http_code}' -X 'GET' '$vault_url/api/token/$token_id?username=$username'" 2>&1)
  
  # Extract HTTP code and body
  local http_code=$(echo "$token_response" | grep "HTTP_CODE:" | cut -d':' -f2)
  local response_body=$(echo "$token_response" | grep -v "HTTP_CODE:" | tr -d '\n\r')
  
  echo "   ✓ Response received"
  echo "   HTTP Code: ${http_code:-unknown}"
  echo "   Response length: ${#response_body} chars"
  echo "   Response (first 50 chars): ${response_body:0:50}..."
  echo "   Response (last 30 chars): ...${response_body:(-30)}"
  
  local token=""
  
  echo "   🔍 Parsing token from response..."
  
  # API returns JWT token directly (not wrapped in JSON)
  if [[ "$response_body" =~ ^eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
    # JWT token format detected
    token="$response_body"
    echo "   ✓ JWT token format detected (3 base64url parts)"
    local header=$(echo "$token" | cut -d'.' -f1)
    local payload=$(echo "$token" | cut -d'.' -f2)
    local signature=$(echo "$token" | cut -d'.' -f3)
    echo "   ✓ Token parts: header(${#header}), payload(${#payload}), signature(${#signature})"
  elif echo "$response_body" | grep -q '"token"'; then
    # JSON format: {"token": "..."}
    token=$(echo "$response_body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "   ✓ JSON format detected, extracted 'token' field"
  else
    log_warning "Unexpected token format, using raw response"
    token="$response_body"
  fi
  
  if [ -z "$token" ] || [ "$token" = "null" ]; then
    log_error "Failed to extract token from response."
    echo "   Full response: $token_response"
    return 1
  fi
  
  log_success "Token obtained successfully"
  echo "   Token length: ${#token} characters"
  echo "   Token preview: ${token:0:40}...${token:(-40)}"
  
  # Create secret with real MinIO credentials
  echo ""
  echo "📝 Step 3: Creating KBTConfigs secret in Vault..."
  echo "   Secret ID: KBTConfigs"
  echo "   Secret Type: Password"
  echo "   Expiration: 2030-12-31"
  echo "   Tags: KB, Tasker, Mongo, Minio"
  echo ""
  echo "   📦 Secret contents:"
  echo "      └─ metadata.MongoCS: ${mongo_url:0:25}...@..."
  echo "      └─ metadata.MinioHost: $MINIO_DNS"
  echo "      └─ metadata.MinioUser: $MINIO_ROOT_USER"
  echo "      └─ metadata.MinioPass: ${MINIO_ROOT_PASSWORD:0:3}***${MINIO_ROOT_PASSWORD:(-3)}"
  
  local secret_payload=$(cat <<EOF
{
  "id": "KBTConfigs",
  "name": "KBTConfigs",
  "type": "Password",
  "data": "All info in META",
  "metadata": {
    "MongoCS": "$mongo_url",
    "MinioHost": "$MINIO_DNS",
    "MinioUser": "$MINIO_ROOT_USER",
    "MinioPass": "$MINIO_ROOT_PASSWORD"
  },
  "tags": ["KB", "Tasker", "Mongo", "Minio"],
  "expiresAt": "2030-12-31T23:59:59.999Z"
}
EOF
)
  
  # Escape JSON payload for shell
  echo ""
  echo "   🔧 Preparing JSON payload..."
  local escaped_payload=$(echo "$secret_payload" | sed 's/"/\\"/g' | tr -d '\n')
  echo "   ✓ Payload prepared (${#escaped_payload} chars after escaping)"
  
  # Send POST request using bash
  echo ""
  echo "   📤 Sending POST request to Vault API..."
  echo "   Endpoint: POST $vault_url/api/Secrets"
  echo "   Headers:"
  echo "      └─ Authorization: Bearer ${token:0:20}...${token:(-20)}"
  echo "      └─ Content-Type: application/json"
  echo "      └─ Accept: text/plain"
  echo "   Timeout: 90 seconds"
  echo "   🔄 Executing..."
  
  local secret_response=$(timeout 90 docker exec "$container" bash -c "curl -s --max-time 85 -w '\n%{http_code}' -X 'POST' \
    '$vault_url/api/Secrets' \
    -H 'Authorization: Bearer $token' \
    -H 'accept: text/plain' \
    -H 'Content-Type: application/json' \
    -d \"$escaped_payload\"" 2>&1) || secret_response="TIMEOUT"
  
  echo ""
  if [ "$secret_response" = "TIMEOUT" ]; then
    log_warning "Request timeout after 90s. Verifying if secret was created..."
    
    # Try to verify
    echo "   🔍 Verification: GET /api/Secrets/KBTConfigs"
    local verify_response=$(timeout 10 docker exec "$container" bash -c "curl -s -X 'GET' \
      '$vault_url/api/Secrets/KBTConfigs' \
      -H 'Authorization: Bearer $token'" 2>&1)
    
    if echo "$verify_response" | grep -q "KBTConfigs"; then
      log_success "Secret KBTConfigs was created (verified after timeout)"
      echo "   ✓ Secret exists in Vault"
      return 0
    else
      log_warning "Could not verify secret creation. Please check Vault manually."
      echo "   Verification response: ${verify_response:0:100}"
      return 0
    fi
  fi
  
  local http_code=$(echo "$secret_response" | tail -n1)
  local response_body=$(echo "$secret_response" | head -n-1)
  
  echo "   ✓ Response received"
  echo "   HTTP Code: $http_code"
  if [ -n "$response_body" ]; then
    echo "   Response body (first 100 chars): ${response_body:0:100}"
  fi
  
  echo ""
  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    log_success "Vault secret KBTConfigs created successfully"
    echo "   ✅ Secret stored in Vault"
    echo "   ✅ MongoDB connection: configured"
    echo "   ✅ MinIO credentials: configured"
    echo "   ✅ Tags: KB, Tasker, Mongo, Minio"
    echo "   ✅ Expires: 2030-12-31"
  else
    log_warning "Failed to create Vault secret. HTTP code: $http_code"
    if [ -n "$response_body" ]; then
      echo "   Full response: ${response_body:0:300}"
    fi
  fi
}

# === Docker Operations ===

login_yandex() {
  echo -e "\n🔑 Logging into Yandex Container Registry…"
  if docker login --username oauth \
    --password-stdin \
    cr.yandex <<< "y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ"; then
    log_success "Logged in to Yandex CR"
  else
    log_warning "Could not connect to Yandex CR "
  fi
}

create_network() {
  echo -e "\n🌐 Creating Docker network…"
  if docker network inspect unicchat-network >/dev/null 2>&1; then
    log_success "Network 'unicchat-network' already exists"
  else
    docker network create unicchat-network
    log_success "Network 'unicchat-network' created"
  fi
}

start_unicchat() {
  echo -e "\n🚀 Starting UnicChat services…"
  local dir="multi-server-install"
  create_network

  echo -e "\n📥 Pulling all images…"
  (cd "$dir" && docker_compose -f docker-compose.yml pull) || true

  echo -e "\n📦 Starting all services (with --wait)…"
  (cd "$dir" && docker_compose -f docker-compose.yml up -d --wait)

  echo -e "\n📦 MinIO init: creating bucket uc.onlyoffice.docs…"
  docker pull cr.yandex/crpst6ndtaf70or2n2bb/minio-mc:latest 2>/dev/null || true
  if [ -f "$dir/env/minio_env.env" ]; then
    . "$dir/env/minio_env.env"
    sleep 5
    mc_vol="unicchat-mc-init-$$"
    docker run --rm --network unicchat-network -v "${mc_vol}:/root/.mc" \
      --env-file "$dir/env/minio_env.env" \
      cr.yandex/crpst6ndtaf70or2n2bb/minio-mc:latest \
      alias set myminio "http://unicchat-minio:9000" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" 2>/dev/null && \
    docker run --rm --network unicchat-network -v "${mc_vol}:/root/.mc" \
      cr.yandex/crpst6ndtaf70or2n2bb/minio-mc:latest \
      mb --ignore-existing myminio/uc.onlyoffice.docs 2>/dev/null && \
    docker run --rm --network unicchat-network -v "${mc_vol}:/root/.mc" \
      cr.yandex/crpst6ndtaf70or2n2bb/minio-mc:latest \
      anonymous set public myminio/uc.onlyoffice.docs 2>/dev/null
    docker volume rm "${mc_vol}" 2>/dev/null || true
  fi

  log_success "All services started"
}

restart_unicchat() {
  echo -e "\n🔄 Restarting UnicChat services…"
  local dir="multi-server-install"
  (cd "$dir" && docker_compose -f docker-compose.yml restart)
  log_success "Services restarted"
}

cleanup_all() {
  echo -e "\n🗑️ Cleaning up Docker resources…"
  
  read -rp "⚠️ This will remove ALL UnicChat containers, volumes, and images. Continue? (yes/NO): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    return 0
  fi
  
  local dir="multi-server-install"
  
  # Stop and remove containers
  echo "Stopping containers..."
  (cd "$dir" && docker_compose -f docker-compose.yml down -v 2>/dev/null) || true
  
  # Remove images
  echo "Removing images..."
  docker images | grep -E "unicchat|unic|uniceditor|minio|mongodb|rabbitmq|postgres" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
  
  # Remove network (but don't fail if it doesn't exist or in use)
  echo "Removing network..."
  docker network rm unicchat-network 2>/dev/null || true
  
  # Important: Do NOT remove the multi-server-install directory itself
  # Only remove generated env files
  echo "Removing generated .env files..."
  rm -f "$dir"/mongo.env "$dir"/mongo_creds.env "$dir"/appserver.env "$dir"/logger.env
  rm -f "$dir"/logger_creds.env "$dir"/vault_creds.env
  rm -rf "$dir"/env/
  
  log_success "Cleanup complete (directory structure preserved)"
}

# === Automatic Setup ===

auto_setup() {
  echo -e "\n⚙️ Running full automatic setup…"
  
  check_avx
  setup_dns_names
  update_mongo_config
  update_minio_config
  create_network
  prepare_all_envs
  login_yandex
  start_unicchat
  
  echo -e "\n⏳ Waiting for MongoDB to be ready..."
  sleep 15
  setup_mongodb_users
  
  echo -e "\n⏳ Waiting for Vault to be ready..."
  sleep 10
  setup_vault_secrets
  
  echo -e "\n🎉 UnicChat setup complete!"
  echo -e "🌐 Access your services at:"
  echo -e "   App Server: https://$APP_DNS"
  echo -e "   Document Server: https://$EDT_DNS"
  echo -e "   MinIO Console: https://$MINIO_DNS:9002"
}

# === Main Menu ===

main_menu() {
  # Load configurations if they exist
  load_dns_config || true
  
  echo -e "\n✨ Welcome to UnicChat Enterprise Installer"
  if [ -n "$APP_DNS" ]; then
    echo -e "📋 Current DNS configuration:"
    echo -e "   App Server: $APP_DNS"
    echo -e "   Document Server: $EDT_DNS"
    echo -e "   MinIO: $MINIO_DNS"
  fi
  echo ""
  
  while true; do
    cat <<MENU
 [1]  Check AVX support
 [2]  Setup DNS names for services (APP, EDT, MinIO)
 [3]  Update MongoDB configuration
 [4]  Update MinIO configuration
 [5]  Prepare .env files
 [6]  Login to Yandex registry
 [7]  Create Docker network
 [8]  Start UnicChat containers
 [9]  Setup MongoDB users (separate DB per service)
[10]  Setup Vault secrets for KBT service
[11]  Restart all services
[99]  🚀 Full automatic setup
[100] 🗑️  Cleanup (remove containers & volumes)
 [0]  Exit
MENU
    read -rp "👉 Select an option: " choice
    case $choice in
      1) check_avx ;;
      2) setup_dns_names ;;
      3) update_mongo_config ;;
      4) update_minio_config ;;
      5) prepare_all_envs ;;
      6) login_yandex ;;
      7) create_network ;;
      8) start_unicchat ;;
      9) setup_mongodb_users ;;
      10) setup_vault_secrets ;;
      11) restart_unicchat ;;
      100) cleanup_all ;;
      99) auto_setup ;;
      0) echo "👋 Goodbye!" && break ;;
      *) echo "❓ Invalid option." ;;
    esac
    echo ""
  done
}

# === Entry Point ===

# Check Docker before starting
check_docker

log_info "Starting UnicChat installation - $(date)"
main_menu "$@"
