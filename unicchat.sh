#!/usr/bin/env bash
#
# UnicChat installation helper with license support (updated 2025-09-10)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}📝 ${NC}$1"; }
log_success() { echo -e "${GREEN}✅ ${NC}$1"; }
log_warning() { echo -e "${YELLOW}⚠️ ${NC}$1"; }
log_error() { echo -e "${RED}❌ ${NC}$1"; }

# Ensure running as root or via sudo
if [[ $EUID -ne 0 ]]; then
  log_error "This script must be run as root or with sudo."
  exit 1
fi

# Configuration files
CONFIG_FILE="app_config.txt"
DNS_CONFIG="dns_config.txt"
LICENSE_FILE="license.txt"
MONGO_CONFIG_FILE="mongo_config.txt"
MINIO_CONFIG_FILE="minio_config.txt"
LOG_FILE="unicchat_install.log"

NGINX_STACK_DIR="nginx/docker"
NGINX_CONF_DIR="$NGINX_STACK_DIR/conf.d"
NGINX_CERTBOT_CONF_DIR="$NGINX_STACK_DIR/certbot/conf"
NGINX_CERTBOT_WORK_DIR="$NGINX_STACK_DIR/certbot/work"
NGINX_CERTBOT_LOG_DIR="$NGINX_STACK_DIR/certbot/logs"
NGINX_COMPOSE_FILE="nginx/docker-compose.yml"

# Variables
EMAIL=""
APP_DNS=""
EDT_DNS=""
MINIO_DNS=""
UNIC_LICENSE=""
HOSTS_FILE="/etc/hosts"
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Initialize logging
exec > >(tee -a "$LOG_FILE") 2>&1

log_info "Starting UnicChat installation - $(date)"

load_config() {
  log_info "Loading configuration..."
  
  # Load email from config if exists
  if [ -f "$CONFIG_FILE" ]; then
    log_info "Loading email from $CONFIG_FILE..."
    EMAIL=$(grep '^EMAIL=' "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r' | tr -d '"' | tr -d "'")
  fi
  
  # Prompt for email if not in config
  if [ -z "$EMAIL" ]; then
    log_info "First-time setup:"
    while [ -z "$EMAIL" ]; do
      read -rp "📧 Enter contact email for Let's Encrypt: " EMAIL
      # Basic email validation
      if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log_warning "Invalid email format. Please try again."
        EMAIL=""
      fi
    done
    echo "EMAIL=\"$EMAIL\"" > "$CONFIG_FILE"
    log_success "Email saved to $CONFIG_FILE"
  fi
  
  # Load DNS configuration if exists
  if [ -f "$DNS_CONFIG" ]; then
    log_info "Loading DNS configuration from $DNS_CONFIG..."
    source "$DNS_CONFIG"
    log_success "DNS names loaded from config"
  fi
  
  # Load license if exists
  if [ -f "$LICENSE_FILE" ]; then
    log_info "Loading license from $LICENSE_FILE..."
    UNIC_LICENSE=$(cat "$LICENSE_FILE" | tr -d '\r' | tr -d '"' | tr -d "'" | xargs)
    if [ -n "$UNIC_LICENSE" ]; then
      log_success "License loaded from $LICENSE_FILE"
    else
      log_warning "License file exists but is empty"
    fi
  fi
}

setup_local_network() {
  log_info "Setting up local network..."
  # Check for duplicates in /etc/hosts
  if ! grep -q "$MINIO_DNS" "$HOSTS_FILE"; then
    echo "$LOCAL_IP $MINIO_DNS" >> "$HOSTS_FILE"
  fi
  if ! grep -q "$EDT_DNS" "$HOSTS_FILE"; then
    echo "$LOCAL_IP $EDT_DNS" >> "$HOSTS_FILE"
  fi
  log_success "/etc/hosts updated"
}

install_docker() {
  echo -e "\n🐳 Installing Docker and related components…"

  # Remove conflicting packages if present
  apt remove -y containerd || true
  apt autoremove -y

  apt update -y
  apt install -y ca-certificates curl gnupg lsb-release software-properties-common

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt update -y
  
  # Install Docker packages with dependency resolution
  apt install -y -f docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose

  echo "✅ Docker and related components installed:"
  echo "   - docker-ce, docker-ce-cli, containerd.io"
  echo "   - docker-compose-plugin, docker-compose"
  echo "   - ca-certificates, curl, gnupg, lsb-release, software-properties-common"
}

install_nginx_ssl() {
  echo -e "\n🌐 Preparing dockerized Nginx + Certbot stack…"

  mkdir -p "$NGINX_CONF_DIR" "$NGINX_CERTBOT_CONF_DIR" "$NGINX_CERTBOT_WORK_DIR" "$NGINX_CERTBOT_LOG_DIR" "nginx/logs"

  if [ ! -f "$NGINX_COMPOSE_FILE" ]; then
    log_error "Docker compose file not found: $NGINX_COMPOSE_FILE"
    return 1
  fi

  copy_ssl_configs

  docker_compose -f "$NGINX_COMPOSE_FILE" pull nginx certbot
  docker_compose -f "$NGINX_COMPOSE_FILE" up -d nginx

  echo "✅ Dockerized Nginx stack is ready"
}

install_git() {
  echo -e "\n📦 Installing Git…"

  apt update -y
  apt install -y git

  echo "✅ Git installed"
}

install_dns_utils() {
  echo -e "\n🔍 Installing DNS utilities…"

  apt update -y
  apt install -y dnsutils

  echo "✅ DNS utilities installed:"
  echo "   - dnsutils (nslookup, dig, etc.)"
}

install_minio_client() {
  echo -e "\n📦 Installing MinIO client (mc)…"
  if ! command -v mc &> /dev/null; then
    curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
    echo "✅ MinIO client installed"
  else
    echo "✅ MinIO client already installed"
  fi
}

docker_compose() {
  if command -v docker compose >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "❌ docker compose not found."
    exit 1
  fi
}



check_avx() {
  echo -e "\n🧠 Checking CPU for AVX…"
  if grep -m1 -q avx /proc/cpuinfo; then
    echo "✅ AVX supported. You can use MongoDB 5.x+"
  else
    echo "⚠️ No AVX. Use MongoDB 4.4"
  fi
}

setup_dns_names() {
  echo -e "\n🌐 Setting up DNS names for UnicChat services..."
  
  if [ -f "$DNS_CONFIG" ]; then
    source "$DNS_CONFIG"
    echo "✅ DNS names loaded from config:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    return
  fi
  
  echo "🔧 Configure DNS names for UnicChat services:"
  
  while [ -z "$APP_DNS" ]; do
    read -rp "Enter DNS for App Server (e.g. app.unic.chat): " APP_DNS
  done
  
  while [ -z "$EDT_DNS" ]; do
    read -rp "Enter DNS for Document Server (e.g. docs.unic.chat): " EDT_DNS
  done
  
  while [ -z "$MINIO_DNS" ]; do
    read -rp "Enter DNS for MinIO (e.g. minio.unic.chat): " MINIO_DNS
  done
  
  # Save to UnicChat config
  cat > "$DNS_CONFIG" <<EOF
APP_DNS="$APP_DNS"
EDT_DNS="$EDT_DNS"
MINIO_DNS="$MINIO_DNS"
EOF
  echo "✅ UnicChat DNS configuration saved to $DNS_CONFIG"
}

setup_license() {
  echo -e "\n🔑 Setting up UnicChat license..."
  
  if [ -f "$LICENSE_FILE" ] && [ -n "$(cat "$LICENSE_FILE" 2>/dev/null | xargs)" ]; then
    UNIC_LICENSE=$(cat "$LICENSE_FILE" | tr -d '\r' | tr -d '"' | tr -d "'" | xargs)
    echo "✅ License already exists in $LICENSE_FILE"
    echo "   License: $UNIC_LICENSE"
    return
  fi
  
  echo "📝 Enter UnicChat License Key (or press Enter to skip):"
  read -rp "License Key: " license_input
  
  if [ -n "$license_input" ]; then
    echo "$license_input" > "$LICENSE_FILE"
    UNIC_LICENSE="$license_input"
    chmod 600 "$LICENSE_FILE"
    log_success "License saved to $LICENSE_FILE"
  else
    log_warning "No license provided. Some features may be limited."
  fi
}

update_mongo_config() {
  echo -e "\n🔧 Updating MongoDB configuration..."

  local mongo_config_file="$MONGO_CONFIG_FILE"
  local config_file="multi-server-install/config.txt"

  if [ ! -f "$mongo_config_file" ]; then
    log_info "File $mongo_config_file not found, creating new."
    touch "$mongo_config_file"
  fi

  if [ ! -f "$config_file" ]; then
    log_info "File $config_file not found, creating new."
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"
  fi

  update_config() {
    local key=$1
    local value=$2
    local file=$3
    if grep -q "^$key=" "$file"; then
      sed -i "s|^$key=.*|$key=\"$value\"|" "$file"
    else
      echo "$key=\"$value\"" >> "$file"
    fi
    if [ $? -eq 0 ]; then
      log_success "Successfully updated: $key=\"$value\" in $file"
    else
      log_error "Error updating $key in $file"
      exit 1
    fi
  }

  get_value_from_mongo_config() {
    local key=$1
    local value
    if grep -q "^$key=" "$mongo_config_file"; then
      value=$(grep "^$key=" "$mongo_config_file" | cut -d'=' -f2 | tr -d '"')
      echo "$value"
    else
      echo ""
    fi
  }

  prompt_value() {
    local key=$1
    local prompt=$2
    read -p "$prompt: " value
    if [ -z "$value" ]; then
      log_error "Value for $key cannot be empty."
      exit 1
    fi
    update_config "$key" "$value" "$mongo_config_file"
    update_config "$key" "$value" "$config_file"
  }

  local keys=(
    "MONGODB_ROOT_PASSWORD"
    "MONGODB_USERNAME"
    "MONGODB_PASSWORD"
    "MONGODB_DATABASE"
  )

  for key in "${keys[@]}"; do
    value=$(get_value_from_mongo_config "$key")
    if [ -n "$value" ]; then
      update_config "$key" "$value" "$config_file"
    else
      prompt_value "$key" "Enter $key"
    fi
  done

  log_success "MongoDB configuration updated in $mongo_config_file and $config_file."
}

update_minio_config() {
  echo -e "\n🔧 Updating MinIO configuration..."

  local minio_config_file="$MINIO_CONFIG_FILE"
  local config_file="knowledgebase/config.txt"

  if [ ! -f "$minio_config_file" ]; then
    log_info "File $minio_config_file not found, creating new."
    touch "$minio_config_file"
  fi

  if [ ! -f "$config_file" ]; then
    log_info "File $config_file not found, creating new."
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"
  fi

  update_config() {
    local key=$1
    local value=$2
    local file=$3
    if grep -q "^$key=" "$file"; then
      sed -i "s|^$key=.*|$key=\"$value\"|" "$file"
    else
      echo "$key=\"$value\"" >> "$file"
    fi
    if [ $? -eq 0 ]; then
      log_success "Successfully updated: $key=\"$value\" in $file"
    else
      log_error "Error updating $key in $file"
      exit 1
    fi
  }

  get_value_from_minio_config() {
    local key=$1
    local value
    if grep -q "^$key=" "$minio_config_file"; then
      value=$(grep "^$key=" "$minio_config_file" | cut -d'=' -f2 | tr -d '"')
      echo "$value"
    else
      echo ""
    fi
  }

  prompt_value() {
    local key=$1
    local prompt=$2
    read -p "$prompt: " value
    if [ -z "$value" ]; then
      log_error "Value for $key cannot be empty."
      exit 1
    fi
    update_config "$key" "$value" "$minio_config_file"
    update_config "$key" "$value" "$config_file"
  }

  local keys=(
    "MINIO_ROOT_USER"
    "MINIO_ROOT_PASSWORD"
  )

  for key in "${keys[@]}"; do
    value=$(get_value_from_minio_config "$key")
    if [ -n "$value" ]; then
      update_config "$key" "$value" "$config_file"
    else
      prompt_value "$key" "Enter $key"
    fi
  done

  log_success "MinIO configuration updated in $minio_config_file and $config_file."
}

copy_ssl_configs() {
  echo -e "\n📋 Copying SSL configuration files..."

  mkdir -p "$NGINX_CERTBOT_CONF_DIR"

  if [ ! -f "$NGINX_CERTBOT_CONF_DIR/options-ssl-nginx.conf" ]; then
    if [ -f "nginx/options-ssl-nginx.conf" ]; then
      cp "nginx/options-ssl-nginx.conf" "$NGINX_CERTBOT_CONF_DIR/"
      echo "✅ options-ssl-nginx.conf copied to $NGINX_CERTBOT_CONF_DIR"
    else
      echo "⚠️ options-ssl-nginx.conf not found in nginx/"
    fi
  else
    echo "✅ options-ssl-nginx.conf already exists in $NGINX_CERTBOT_CONF_DIR"
  fi

  if [ ! -f "$NGINX_CERTBOT_CONF_DIR/ssl-dhparams.pem" ]; then
    echo -e "\n⏳ Generating DH parameters..."
    openssl dhparam -out "$NGINX_CERTBOT_CONF_DIR/ssl-dhparams.pem" 2048
    echo "✅ DH parameters generated"
  else
    echo "✅ DH parameters already exist"
  fi
}

generate_nginx_conf() {
  echo -e "\n🛠️ Generating Nginx configs for UnicChat services…"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  SERVER_IP=$(hostname -I | awk '{print $1}')
  
  APP_PORT="8080"
  EDT_PORT="8880"
  MINIO_PORT="9000"
  
  mkdir -p "$NGINX_CONF_DIR"
  
  generate_config() {
    local domain=$1
    local upstream=$2
    local port=$3
    local output_file="$NGINX_CONF_DIR/${domain}.conf"
    
    echo "🔧 Generating config for: $domain → $upstream:$port"
    
    cat > "$output_file" <<EOF
# Configuration for $domain
# Generated: $(date)
# Server IP: $SERVER_IP

upstream $upstream {
    server $SERVER_IP:$port;
}

server {
    listen 80;
    listen 443 ssl;
    http2 on;
    server_name $domain;
    client_max_body_size 200M;

    error_log /var/log/nginx/${domain}.error.log;
    access_log /var/log/nginx/${domain}.access.log;

    if (\$scheme = http) {
        return 301 https://\$host\$request_uri;
    }

    location / {
        proxy_pass http://$upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Nginx-Proxy true;
        proxy_redirect off;
    }

    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
EOF
    
    echo "✅ Created: $output_file"
  }
  
  generate_config "$APP_DNS" "myapp" "$APP_PORT"
  generate_config "$EDT_DNS" "edtapp" "$EDT_PORT"
  generate_config "$MINIO_DNS" "myminio" "$MINIO_PORT"
  
  echo "🎉 Nginx configs generated in $NGINX_CONF_DIR"
}

deploy_nginx_conf() {
  echo -e "\n📤 Deploying Nginx configs…"
  
  if [ ! -f "$NGINX_COMPOSE_FILE" ]; then
    echo "❌ Docker compose file not found: $NGINX_COMPOSE_FILE"
    return 1
  fi

  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 7 first."
    return 1
  fi
  source "$DNS_CONFIG"

  if [ ! -d "$NGINX_CONF_DIR" ] || [ -z "$(ls -A "$NGINX_CONF_DIR" 2>/dev/null)" ]; then
    echo "❌ No configs found in $NGINX_CONF_DIR. Run step 12 first."
    return 1
  fi

  local domains=()
  [ -n "${APP_DNS:-}" ] && domains+=("$APP_DNS")
  [ -n "${EDT_DNS:-}" ] && domains+=("$EDT_DNS")
  [ -n "${MINIO_DNS:-}" ] && domains+=("$MINIO_DNS")

  local missing_certs=()
  for domain in "${domains[@]}"; do
    if [ ! -f "$NGINX_CERTBOT_CONF_DIR/live/$domain/fullchain.pem" ]; then
      missing_certs+=("$domain")
    fi
  done

  if [ ${#missing_certs[@]} -gt 0 ]; then
    echo "⚠️ SSL certificates not found for: ${missing_certs[*]}"
    echo "   Run 'Setup SSL certificates' (menu option 15) before deploying configs."
    return 1
  fi

  docker_compose -f "$NGINX_COMPOSE_FILE" up -d nginx

  if docker_compose -f "$NGINX_COMPOSE_FILE" exec -T nginx nginx -t; then
    docker_compose -f "$NGINX_COMPOSE_FILE" exec -T nginx nginx -s reload
    echo "✅ Nginx container reloaded with new configs"
  else
    echo "❌ Nginx config test failed. Check logs."
    return 1
  fi
}

setup_ssl() {
  echo -e "\n🔐 Setting up SSL certificates for UnicChat domains…"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  copy_ssl_configs
  
  local domains=()
  [ -n "$APP_DNS" ] && domains+=("$APP_DNS")
  [ -n "$EDT_DNS" ] && domains+=("$EDT_DNS")
  [ -n "$MINIO_DNS" ] && domains+=("$MINIO_DNS")
  
  if [ ${#domains[@]} -eq 0 ]; then
    echo "❌ No domains found in DNS config."
    return 1
  fi
  
  echo "📋 Creating SSL certificates for: ${domains[*]}"

  if [ ! -f "$NGINX_COMPOSE_FILE" ]; then
    echo "❌ Docker compose file not found: $NGINX_COMPOSE_FILE"
    return 1
  fi

  echo "🛑 Stopping dockerized nginx to free port 80/443..."
  docker_compose -f "$NGINX_COMPOSE_FILE" stop nginx || true

  for domain in "${domains[@]}"; do
    CERT_PATH="$NGINX_CERTBOT_CONF_DIR/live/$domain"
    if [ -d "$CERT_PATH" ]; then
      echo "ℹ️ Certificate for $domain found. Attempting to renew if needed..."
      if ! docker_compose -f "$NGINX_COMPOSE_FILE" run --rm --service-ports certbot renew --cert-name "$domain" --non-interactive; then
        echo "❌ Certbot renew failed for $domain"
        docker_compose -f "$NGINX_COMPOSE_FILE" start nginx >/dev/null 2>&1 || true
        return 1
      fi
    else
      echo "📝 No certificate found for $domain. Requesting new certificate..."
      if ! docker_compose -f "$NGINX_COMPOSE_FILE" run --rm --service-ports certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$domain"; then
        echo "❌ Certbot failed to obtain certificate for $domain"
        docker_compose -f "$NGINX_COMPOSE_FILE" start nginx >/dev/null 2>&1 || true
        return 1
      fi
    fi
  done
  
  echo "▶️ Starting dockerized nginx..."
  docker_compose -f "$NGINX_COMPOSE_FILE" up -d nginx
  
  if docker_compose -f "$NGINX_COMPOSE_FILE" exec -T nginx nginx -t; then
    docker_compose -f "$NGINX_COMPOSE_FILE" exec -T nginx nginx -s reload
    echo "✅ SSL setup complete for UnicChat domains"
  else
    echo "❌ Nginx config test failed after SSL setup."
    return 1
  fi
}

activate_nginx() {
  echo -e "\n🚀 Activating dockerized Nginx…"
  if [ ! -f "$NGINX_COMPOSE_FILE" ]; then
    echo "❌ Docker compose file not found: $NGINX_COMPOSE_FILE"
    return 1
  fi

  if docker_compose -f "$NGINX_COMPOSE_FILE" exec -T nginx nginx -t; then
    docker_compose -f "$NGINX_COMPOSE_FILE" exec -T nginx nginx -s reload
    echo "✅ Nginx container reloaded"
  else
    echo "❌ Nginx config test failed."
    return 1
  fi
}

update_solid_env() {
  echo -e "\n🔗 Linking Knowledgebase MinIO with UnicChat solid…"
  
  local solid_env="multi-server-install/solid.env"
  local kb_config="knowledgebase/config.txt"
  
  if [ ! -f "$solid_env" ]; then
    echo "❌ solid.env file not found: $solid_env"
    return 1
  fi
  
  if [ ! -f "$kb_config" ]; then
    echo "❌ Knowledgebase config not found: $kb_config"
    echo "⚠️ Please deploy knowledgebase first to get MinIO credentials"
    return 1
  fi
  
  source "$kb_config"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  sed -i '/# MinIO Configuration/,/MINIO_SECRET_KEY/d' "$solid_env"
  
  cat >> "$solid_env" <<EOF

# MinIO Configuration from Knowledgebase
UnInit.1="'Minio': { 'Type': 'NamedServiceAuth', 'IpOrHost': '$MINIO_DNS', 'UserName': '$MINIO_ROOT_USER', 'Password': '$MINIO_ROOT_PASSWORD' }"
EOF
  
  if [ -n "$UNIC_LICENSE" ]; then
    echo "UnicLicense=\"$UNIC_LICENSE\"" >> "$solid_env"
    echo "✅ License added to solid.env"
  fi
  
  echo "✅ Knowledgebase MinIO linked to UnicChat solid"
  echo "   MinIO URL: $MINIO_DNS"
  echo "   Username: $MINIO_ROOT_USER"
}

update_appserver_env() {
  echo -e "\n🔗 Linking Document Server with UnicChat appserver…"
  
  local appserver_env="multi-server-install/appserver.env"
  
  if [ ! -f "$appserver_env" ]; then
    echo "❌ appserver.env file not found: $appserver_env"
    return 1
  fi
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Removed ROOT_URL modification as requested
  sed -i "s|ROOT_URL=.*|ROOT_URL=https://$APP_DNS|" "$appserver_env"
  
  if ! grep -q "DOCUMENT_SERVER_HOST" "$appserver_env"; then
    echo "DOCUMENT_SERVER_HOST=https://$EDT_DNS" >> "$appserver_env"
  else
    sed -i "s|DOCUMENT_SERVER_HOST=.*|DOCUMENT_SERVER_HOST=https://$EDT_DNS|" "$appserver_env"
  fi
  
  echo "✅ Document Server linked to UnicChat appserver"
  echo "   Document Server URL: https://$EDT_DNS"
}

prepare_all_envs() {
  echo -e "\n📦 Preparing all environment files…"
  
  local dir="multi-server-install"
  (cd "$dir" && chmod +x generate_env_files.sh && ./generate_env_files.sh)
  
  update_solid_env
  update_appserver_env
  
  echo "✅ All environment files prepared and updated"
}

prepare_unicchat() {
  echo -e "\n📦 Preparing env files…"
  prepare_all_envs
}

login_yandex() {
  echo -e "\n🔑 Logging into Yandex Container Registry…"
  docker login --username oauth \
    --password y0_AgAAAAB3muX6AATuwQAAAAEawLLRAAB9TQHeGyxGPZXkjVDHF1ZNJcV8UQ \
    cr.yandex
  echo "✅ Logged in."
}

start_unicchat() {
  echo -e "\n🚀 Starting UnicChat services…"
  local dir="multi-server-install"
  docker network inspect unicchat-backend >/dev/null 2>&1 || docker network create unicchat-backend
  docker network inspect unicchat-frontend >/dev/null 2>&1 || docker network create unicchat-frontend
  (cd "$dir"  && docker_compose -f mongodb.yml up -d --wait && docker_compose -f unic.chat.appserver.yml up -d && docker_compose  -f unic.chat.solid.yml up -d --wait)
  echo "✅ Services started."
}

update_site_url() {
  echo -e "\n📝 Updating Site_Url in MongoDB…"
  local container="unic.chat.db.mongo"
  local max_attempts=5
  local attempt=1
  local delay=2
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  if [ ! -f "mongo_config.txt" ]; then
    echo "❌ MongoDB configuration not found. Run 'Update MongoDB configuration' first."
    return 1
  fi
  
  source "mongo_config.txt"
  
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "❌ MongoDB container is not running: $container"
    return 1
  fi
  
  local url="https://$APP_DNS"
  
  echo "🔄 Updating Site_Url to: $url"
  echo "📊 Using database: $MONGODB_DATABASE"
  
  # Функция для проверки текущего значения
  check_current_value() {
    local field=$1
    docker exec "$container" mongosh -u root -p "$MONGODB_ROOT_PASSWORD" --quiet --eval "
      db.getSiblingDB('$MONGODB_DATABASE').unicchat_settings.findOne(
        {_id: 'Site_Url'}, 
        {'$field': 1}
      ).$field
    " 2>/dev/null
  }
  
  # Функция для обновления значения с проверкой
  update_with_retry() {
    local field=$1
    local update_command=$2
    local current_value=""
    
    while [ $attempt -le $max_attempts ]; do
      echo "🔄 Attempt $attempt/$max_attempts to update $field..."
      
      # Выполняем обновление
      docker exec "$container" mongosh -u root -p "$MONGODB_ROOT_PASSWORD" --quiet --eval "$update_command" >/dev/null 2>&1
      
      # Даем время на применение изменений
      sleep $delay
      
      # Проверяем текущее значение
      current_value=$(check_current_value "$field")
      
      if [ "$current_value" = "$url" ]; then
        echo "✅ $field successfully updated to: $url"
        return 0
      else
        echo "⚠️  $field not updated yet. Current value: '$current_value', Expected: '$url'"
        attempt=$((attempt + 1))
        sleep $delay
      fi
    done
    
    echo "❌ Failed to update $field after $max_attempts attempts"
    return 1
  }
  
  # Обновляем value поле
  attempt=1
  update_command_value="db.getSiblingDB('$MONGODB_DATABASE').unicchat_settings.updateOne({_id:'Site_Url'},{\$set:{value:'$url'}})"
  if ! update_with_retry "value" "$update_command_value"; then
    return 1
  fi
  
  # Обновляем packageValue поле
  attempt=1
  update_command_package="db.getSiblingDB('$MONGODB_DATABASE').unicchat_settings.updateOne({_id:'Site_Url'},{\$set:{packageValue:'$url'}})"
  if ! update_with_retry "packageValue" "$update_command_package"; then
    return 1
  fi
  
  # Финальная проверка обоих полей
  echo "🔍 Final verification..."
  final_value=$(check_current_value "value")
  final_package=$(check_current_value "packageValue")
  
  if [ "$final_value" = "$url" ] && [ "$final_package" = "$url" ]; then
    echo "✅ Site_Url updated successfully in database: $MONGODB_DATABASE"
    echo "   value: $final_value"
    echo "   packageValue: $final_package"
    return 0
  else
    echo "❌ Final verification failed:"
    echo "   value: '$final_value' (expected: '$url')"
    echo "   packageValue: '$final_package' (expected: '$url')"
    return 1
  fi
}
deploy_knowledgebase() {
  echo -e "\n🚀 Deploying knowledge base services…"
  local kb_dir="knowledgebase"
  
  if [ ! -f "$kb_dir/deploy_knowledgebase.sh" ]; then
    echo "❌ Knowledge base deployment script not found"
    return 1
  fi
  
  # Делаем скрипт исполняемым
  chmod +x "$kb_dir/deploy_knowledgebase.sh"
  
  echo "📦 Running knowledge base deployment..."
  (cd "$kb_dir" && ./deploy_knowledgebase.sh --auto)
  
  echo "✅ Knowledge base services deployed"
}


cleanup_docker() {
    echo -e "\n🐳 Removing Docker completely...\n"
    
    # Удалить все Docker ресурсы
    if command -v docker &>/dev/null; then
        echo "🗑️ Cleaning up Docker resources..."
        docker rm -f $(docker ps -aq) 2>/dev/null || true
        docker rmi -f $(docker images -q) 2>/dev/null || true
        docker volume rm -f $(docker volume ls -q) 2>/dev/null || true
        docker network rm $(docker network ls -q) 2>/dev/null || true
        docker system prune -af --volumes --force 2>/dev/null || true
    fi
    
    # Удалить Docker пакеты
    echo "📦 Removing Docker packages..."
    apt remove -y --purge docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose 2>/dev/null || true
    
    # Удалить конфиги
    echo "🗂️ Removing Docker configuration..."
    rm -rf /var/lib/docker /etc/docker 2>/dev/null || true
    rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
    rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null || true
    
    # Очистка
    apt autoremove -y 2>/dev/null || true
    apt clean 2>/dev/null || true
    
    echo -e "\n✅ Docker completely removed from system!"
}

cleanup_nginx() {
    echo -e "\n🗑️ Removing dockerized Nginx...\n"
    if [ -f "$NGINX_COMPOSE_FILE" ]; then
        docker_compose -f "$NGINX_COMPOSE_FILE" down || true
    fi
    rm -rf "$NGINX_STACK_DIR" "nginx/logs"
    echo "✅ Nginx stack removed!"
}

cleanup_ssl() {
    echo "Removing SSL certificates and Certbot volumes..."
    rm -rf "$NGINX_CERTBOT_CONF_DIR" "$NGINX_CERTBOT_WORK_DIR" "$NGINX_CERTBOT_LOG_DIR"
    echo "✅ SSL assets removed!"
}

cleanup_git() {
    echo -e "\n📦 Removing Git...\n"
    apt remove -y --purge git 2>/dev/null || true
    apt autoremove -y 2>/dev/null || true
    echo "✅ Git completely removed!"
}

cleanup_dns_utils() {
    echo -e "\n🔍 Removing DNS utilities...\n"
    apt remove -y --purge dnsutils 2>/dev/null || true
    apt autoremove -y 2>/dev/null || true
    echo "✅ DNS utilities completely removed!"
}

cleanup_minio_client() {
    echo -e "\n📦 Removing MinIO client...\n"
    rm -f /usr/local/bin/mc 2>/dev/null || true
    echo "✅ MinIO client completely removed!"
}

cleanup_utilities() {
    echo -e "\n🗑️ Removing all installed utilities...\n"
    
    # Временно отключаем set -e для этой функции
    set +e
    
    # Вызов всех отдельных функций очистки
    cleanup_docker
    cleanup_nginx
    cleanup_ssl
    cleanup_git
    cleanup_dns_utils
    cleanup_minio_client
    
    # Дополнительно: удалить всю папку unicchat.enterprise
    echo "🗑️ Removing unicchat.enterprise directory"

    # Переходим на уровень выше и удаляем всю папку

    rm -rf "../unicchat.enterprise" 2>/dev/null || true

    # Восстанавливаем set -e
    set -e

    echo -e "\n✅ unicchat.enterprise completely removed!"
    # Восстанавливаем set -e
    set -e
    
    echo -e "\n✅ All utilities completely removed!"
}

auto_setup() {
  echo -e "\n⚙️ Running full automatic setup…"
  install_docker
  install_nginx_ssl
  install_git
  install_dns_utils
  install_minio_client

  check_avx
  setup_dns_names
  setup_license
  update_mongo_config
  update_minio_config
  setup_local_network
  generate_nginx_conf
  setup_ssl
  deploy_nginx_conf
  activate_nginx
  prepare_unicchat
  login_yandex
  start_unicchat
#  update_site_url
  deploy_knowledgebase
  echo -e "\n🎉 UnicChat setup complete! (including knowledge base)"
}

main_menu() {
  echo -e "\n✨ Welcome to UnicChat Installer"
  echo -e "✅ Email: $EMAIL"
  
  if [ -f "$DNS_CONFIG" ]; then
    source "$DNS_CONFIG"
    echo "📋 Current DNS configuration:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
  fi
  
  if [ -n "$UNIC_LICENSE" ]; then
    echo "🔑 License: $UNIC_LICENSE"
  else
    echo "⚠️ No license configured"
  fi
  echo ""
  
  while true; do
    cat <<MENU
 [1]  Install Docker
 [2]  Install Nginx and Certbot
 [3]  Install Git
 [4]  Install DNS utilities
 [5]  Install MinIO client (mc)
 [6]  Check AVX support
 [7]  Setup DNS names for UnicChat services
 [8]  Setup License Key
 [9]  Update MongoDB configuration
 [10] Update MinIO configuration
 [11] Setup local network (/etc/hosts)
 [12] Generate Nginx configs
 [13] Deploy Nginx configs
 [14] Copy SSL configs and generate DH params
 [15] Setup SSL certificates
 [16] Activate Nginx sites
 [17] Prepare .env files
 [18] Login to Yandex registry
 [19] Start UnicChat containers
 [20] Deploy knowledge base services
 [99]  🚀 Full automatic setup (with knowledge base)
 [100] Remove all
 [0]  Exit
MENU
    read -rp "👉 Select an option: " choice
    case $choice in
      1) install_docker ;;
      2) install_nginx_ssl ;;
      3) install_git ;;
      4) install_dns_utils ;;
      5) install_minio_client ;;
      6) check_avx ;;
      7) setup_dns_names ;;
      8) setup_license ;;
     9) update_mongo_config ;;
     10) update_minio_config ;;
     11) setup_local_network ;;
     12) generate_nginx_conf ;;
     13) deploy_nginx_conf ;;
     14) copy_ssl_configs ;;
     15) setup_ssl ;;
     16) activate_nginx ;;
     17) prepare_unicchat ;;
     18) login_yandex ;;
     19) start_unicchat ;;
     20) deploy_knowledgebase ;;
     99) auto_setup ;;
    100) cleanup_utilities ;;
      0) echo "👋 Goodbye!" && break ;;
      *) echo "❓ Invalid option." ;;
    esac
    echo ""
  done
}

# === Start ===
load_config
main_menu "$@"
