#!/usr/bin/env bash
#
# UnicChat installation helper with VCS support (обновлено 2025-09-10)
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

# Конфигурационные файлы
CONFIG_FILE="app_config.txt"
DNS_CONFIG="dns_config.txt"
VCS_CONFIG="vcs_config.txt"
LICENSE_FILE="license.txt"
MONGO_CONFIG_FILE="mongo_config.txt"
MINIO_CONFIG_FILE="minio_config.txt"
LOG_FILE="unicchat_install.log"

# Переменные
EMAIL=""
APP_DNS=""
EDT_DNS=""
MINIO_DNS=""
VCS_DNS=""
VCS_TURN_DNS=""
VCS_WHIP_DNS=""
UNIC_LICENSE=""

# Initialize logging
exec > >(tee -a "$LOG_FILE") 2>&1

log_info "Starting UnicChat installation with VCS - $(date)"

load_config() {
  log_info "Loading configuration..."
  
  # Загружаем email из конфига если есть
  if [ -f "$CONFIG_FILE" ]; then
    log_info "Loading email from $CONFIG_FILE..."
    EMAIL=$(grep '^EMAIL=' "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r' | tr -d '"' | tr -d "'")
  fi
  
  # Запрашиваем email если нет в конфиге
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
  
  # Загружаем DNS конфигурацию если есть
  if [ -f "$DNS_CONFIG" ]; then
    log_info "Loading DNS configuration from $DNS_CONFIG..."
    source "$DNS_CONFIG"
    log_success "DNS names loaded from config"
  fi
  
  # Загружаем VCS конфигурацию если есть
  if [ -f "$VCS_CONFIG" ]; then
    log_info "Loading VCS configuration from $VCS_CONFIG..."
    source "$VCS_CONFIG"
    log_success "VCS DNS names loaded from config"
  fi
  
  # Загружаем лицензию если есть
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

install_docker() {
  echo -e "\n🐳 Installing Docker and related components…"

  # Удаляем конфликтующие пакеты если они есть
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
  
  # Устанавливаем Docker пакеты с принудительным разрешением зависимостей
  apt install -y -f docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose

  echo "✅ Docker and related components installed:"
  echo "   - docker-ce, docker-ce-cli, containerd.io"
  echo "   - docker-compose-plugin, docker-compose"
  echo "   - ca-certificates, curl, gnupg, lsb-release, software-properties-common"
}

install_nginx_ssl() {
  echo -e "\n🌐 Installing Nginx and SSL components…"

  apt update -y
  apt install -y nginx certbot python3-certbot-nginx

  echo "✅ Nginx and SSL components installed:"
  echo "   - nginx"
  echo "   - certbot, python3-certbot-nginx"
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

clone_repo() {
  echo -e "\n📥 Cloning repository…"
  if [ ! -d unicchat.enterprise ]; then
    git clone https://github.com/unicommorg/unicchat.enterprise.git
  else
    echo "📁 Repository already exists."
  fi
  (cd unicchat.enterprise && git fetch --all && git switch skonstantinov-patch-2 )
  echo "✅ Repo ready on branch skonstantinov-patch-2."
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
  echo -e "\n🌐 Setting up DNS names for all services..."
  
  if [ -f "$DNS_CONFIG" ] && [ -f "$VCS_CONFIG" ]; then
    source "$DNS_CONFIG"
    source "$VCS_CONFIG"
    echo "✅ DNS names loaded from config:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    echo "   VCS: $VCS_DNS"
    echo "   VCS TURN: $VCS_TURN_DNS"
    echo "   VCS WHIP: $VCS_WHIP_DNS"
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
  
  # Сохраняем в конфиг UnicChat
  cat > "$DNS_CONFIG" <<EOF
APP_DNS="$APP_DNS"
EDT_DNS="$EDT_DNS"
MINIO_DNS="$MINIO_DNS"
EOF
  echo "✅ UnicChat DNS configuration saved to $DNS_CONFIG"
  
  # VCS DNS names - отдельный файл
  echo "📹 Configure VCS (Video Communication Server) DNS names:"
  
  local vcs_dns=""
  local vcs_turn_dns=""
  local vcs_whip_dns=""
  
  while [ -z "$vcs_dns" ]; do
    read -rp "Enter DNS for VCS Main (e.g. vcs.unic.chat): " vcs_dns
  done
  
  while [ -z "$vcs_turn_dns" ]; do
    read -rp "Enter DNS for VCS TURN (e.g. turn.unic.chat): " vcs_turn_dns
  done
  
  while [ -z "$vcs_whip_dns" ]; do
    read -rp "Enter DNS for VCS WHIP (e.g. whip.unic.chat): " vcs_whip_dns
  done
  
  # Сохраняем в отдельный файл для VCS
  cat > "$VCS_CONFIG" <<EOF
VCS_DNS="$vcs_dns"
VCS_TURN_DNS="$vcs_turn_dns"
VCS_WHIP_DNS="$vcs_whip_dns"
EOF
  echo "✅ VCS DNS configuration saved to $VCS_CONFIG"
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

  # Определяем пути к файлам конфигурации
  local mongo_config_file="$MONGO_CONFIG_FILE"
  local config_file="unicchat.enterprise/multi-server-install/config.txt"

  # Проверка существования файлов, создание если отсутствуют
  if [ ! -f "$mongo_config_file" ]; then
    log_info "Файл $mongo_config_file не найден, создаем новый."
    touch "$mongo_config_file"
  fi

  if [ ! -f "$config_file" ]; then
    log_info "Файл $config_file не найден, создаем новый."
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"
  fi

  # Функция для обновления или добавления значения переменной в указанном файле
  update_config() {
    local key=$1
    local value=$2
    local file=$3
    # Проверяем, существует ли строка с ключом
    if grep -q "^$key=" "$file"; then
      # Заменяем существующую строку
      sed -i "s|^$key=.*|$key=\"$value\"|" "$file"
    else
      # Добавляем новую строку в конец файла
      echo "$key=\"$value\"" >> "$file"
    fi
    if [ $? -eq 0 ]; then
      log_success "Успешно обновлено: $key=\"$value\" в $file"
    else
      log_error "Ошибка при обновлении $key в $file"
      exit 1
    fi
  }

  # Функция для получения значения из mongo_config.txt
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

  # Функция для запроса значения у пользователя и обновления обоих файлов
  prompt_value() {
    local key=$1
    local prompt=$2
    read -p "$prompt: " value
    if [ -z "$value" ]; then
      log_error "Значение для $key не может быть пустым."
      exit 1
    fi
    update_config "$key" "$value" "$mongo_config_file"
    update_config "$key" "$value" "$config_file"
  }

  # Переменные для обработки
  local keys=(
    "MONGODB_ROOT_PASSWORD"
    "MONGODB_USERNAME"
    "MONGODB_PASSWORD"
    "MONGODB_DATABASE"
  )

  # Обработка каждой переменной
  for key in "${keys[@]}"; do
    value=$(get_value_from_mongo_config "$key")
    if [ -n "$value" ]; then
      # Если значение найдено в mongo_config.txt, обновляем только config.txt
      update_config "$key" "$value" "$config_file"
    else
      # Если значение не найдено, запрашиваем у пользователя и обновляем оба файла
      prompt_value "$key" "Введите $key"
    fi
  done

  log_success "MongoDB configuration updated in $mongo_config_file and $config_file."
}

update_minio_config() {
  echo -e "\n🔧 Updating MinIO configuration..."

  # Определяем пути к файлам конфигурации
  local minio_config_file="$MINIO_CONFIG_FILE"
  local config_file="unicchat.enterprise/knowledgebase/config.txt"

  # Проверка существования файлов, создание если отсутствуют
  if [ ! -f "$minio_config_file" ]; then
    log_info "Файл $minio_config_file не найден, создаем новый."
    touch "$minio_config_file"
  fi

  if [ ! -f "$config_file" ]; then
    log_info "Файл $config_file не найден, создаем новый."
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"
  fi

  # Функция для обновления или добавления значения переменной в указанном файле
  update_config() {
    local key=$1
    local value=$2
    local file=$3
    # Проверяем, существует ли строка с ключом
    if grep -q "^$key=" "$file"; then
      # Заменяем существующую строку
      sed -i "s|^$key=.*|$key=\"$value\"|" "$file"
    else
      # Добавляем новую строку в конец файла
      echo "$key=\"$value\"" >> "$file"
    fi
    if [ $? -eq 0 ]; then
      log_success "Успешно обновлено: $key=\"$value\" в $file"
    else
      log_error "Ошибка при обновлении $key в $file"
      exit 1
    fi
  }

  # Функция для получения значения из minio_config.txt
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

  # Функция для запроса значения у пользователя и обновления обоих файлов
  prompt_value() {
    local key=$1
    local prompt=$2
    read -p "$prompt: " value
    if [ -z "$value" ]; then
      log_error "Значение для $key не может быть пустым."
      exit 1
    fi
    update_config "$key" "$value" "$minio_config_file"
    update_config "$key" "$value" "$config_file"
  }

  # Переменные для обработки
  local keys=(
    "DB_NAME"
    "DB_USER"
    "MINIO_ROOT_USER"
    "MINIO_ROOT_PASSWORD"
  )

  # Обработка каждой переменной
  for key in "${keys[@]}"; do
    value=$(get_value_from_minio_config "$key")
    if [ -n "$value" ]; then
      # Если значение найдено в minio_config.txt, обновляем только config.txt
      update_config "$key" "$value" "$config_file"
    else
      # Если значение не найдено, запрашиваем у пользователя и обновляем оба файла
      prompt_value "$key" "Введите $key"
    fi
  done

  log_success "MinIO configuration updated in $minio_config_file and $config_file."
}

copy_ssl_configs() {
  echo -e "\n📋 Copying SSL configuration files..."

  # Копируем options-ssl-nginx.conf если его нет
  if [ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]; then
    if [ -f "unicchat.enterprise/nginx/options-ssl-nginx.conf" ]; then
      sudo cp "unicchat.enterprise/nginx/options-ssl-nginx.conf" /etc/letsencrypt/
      echo "✅ options-ssl-nginx.conf copied to /etc/letsencrypt/"
    else
      echo "⚠️ options-ssl-nginx.conf not found in unicchat.enterprise/nginx/"
    fi
  else
    echo "✅ options-ssl-nginx.conf already exists in /etc/letsencrypt/"
  fi

  # Генерируем DH параметры если их нет
  if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
    echo -e "\n⏳ Generating DH parameters..."
    sudo openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
    echo "✅ DH parameters generated"
  else
    echo "✅ DH parameters already exist"
  fi
}

generate_nginx_conf() {
  echo -e "\n🛠️ Generating Nginx configs for UnicChat services…"
  
  # Загружаем DNS конфигурацию только для UnicChat
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Получаем IP сервера
  SERVER_IP=$(hostname -I | awk '{print $1}')
  
  # Порты для сервисов
  APP_PORT="8080"
  EDT_PORT="8880"
  MINIO_PORT="9000"
  
  # Создаем директорию для конфигов если нет
  mkdir -p "unicchat.enterprise/nginx/generated"
  
  # Функция генерации конфига
  generate_config() {
    local domain=$1
    local upstream=$2
    local port=$3
    local output_file="unicchat.enterprise/nginx/generated/${domain}.conf"
    
    echo "🔧 Generating config for: $domain → $upstream:$port"
    
    cat > "$output_file" <<EOF
# Configuration for $domain
# Generated: $(date)
# Server IP: $SERVER_IP

upstream $upstream {
    server $SERVER_IP:$port;
}

server {
    server_name $domain;
    client_max_body_size 200M;

    error_log /var/log/nginx/${domain}.error.log;
    access_log /var/log/nginx/${domain}.access.log;

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

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    server_name $domain;
    listen 80;
    return 301 https://\$host\$request_uri;
}
EOF
    
    echo "✅ Created: $output_file"
  }
  
  # Генерируем конфиги только для UnicChat сервисов
  generate_config "$APP_DNS" "myapp" "$APP_PORT"
  generate_config "$EDT_DNS" "edtapp" "$EDT_PORT"
  generate_config "$MINIO_DNS" "myminio" "$MINIO_PORT"
  
  echo "🎉 Nginx configs generated in unicchat.enterprise/nginx/generated/"
  echo "ℹ️ VCS uses Caddy for reverse proxy, no Nginx config needed for VCS domains"
}

deploy_nginx_conf() {
  echo -e "\n📤 Deploying Nginx configs (excluding VCS)…"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Копируем все сгенерированные конфиги
  if [ -d "unicchat.enterprise/nginx/generated" ]; then
    sudo cp unicchat.enterprise/nginx/generated/*.conf /etc/nginx/sites-available/
    echo "✅ Configs copied to /etc/nginx/sites-available/"
  else
    echo "❌ Generated configs directory not found"
    return 1
  fi
  
  # Создаем симлинки только для UnicChat доменов
  sudo ln -sf "/etc/nginx/sites-available/${APP_DNS}.conf" "/etc/nginx/sites-enabled/" || true
  sudo ln -sf "/etc/nginx/sites-available/${EDT_DNS}.conf" "/etc/nginx/sites-enabled/" || true
  sudo ln -sf "/etc/nginx/sites-available/${MINIO_DNS}.conf" "/etc/nginx/sites-enabled/" || true
  
  # Удаляем дефолтный конфиг
  sudo rm -f /etc/nginx/sites-enabled/default || true
  
  echo "✅ Nginx configs deployed"
  echo "ℹ️ VCS uses Caddy, no Nginx configs needed for VCS domains"
}

setup_ssl() {
  echo -e "\n🔐 Setting up SSL certificates for UnicChat domains only…"
  
  # Загружаем только DNS конфигурацию для UnicChat
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Копируем SSL конфигурационные файлы
  copy_ssl_configs
  
  # Собираем только домены UnicChat
  local domains=()
  [ -n "$APP_DNS" ] && domains+=("$APP_DNS")
  [ -n "$EDT_DNS" ] && domains+=("$EDT_DNS")
  [ -n "$MINIO_DNS" ] && domains+=("$MINIO_DNS")
  
  if [ ${#domains[@]} -eq 0 ]; then
    echo "❌ No domains found in DNS config."
    return 1
  fi
  
  echo "📋 Creating SSL certificates for: ${domains[*]}"
  
  echo "🛑 Stopping nginx to free port 80/443..."
  sudo systemctl stop nginx
  if [ $? -ne 0 ]; then
    echo "❌ Failed to stop nginx"
    return 1
  fi
  
  for domain in "${domains[@]}"; do
    CERT_PATH="/etc/letsencrypt/live/$domain"
    if [ -d "$CERT_PATH" ]; then
      echo "ℹ️ Certificate for $domain found. Attempting to renew if needed..."
      sudo certbot renew --cert-name "$domain" --quiet --deploy-hook "systemctl reload nginx"
      if [ $? -ne 0 ]; then
        echo "❌ Certbot renew failed for $domain"
        sudo systemctl start nginx
        return 1
      fi
    else
      echo "📝 No certificate found for $domain. Requesting new certificate..."
      sudo certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" -d "$domain"
      if [ $? -ne 0 ]; then
        echo "❌ Certbot failed to obtain certificate for $domain"
        sudo systemctl start nginx
        return 1
      fi
    fi
  done
  
  echo "▶️ Starting nginx..."
  sudo systemctl start nginx
  
  if [ $? -ne 0 ]; then
    echo "❌ Failed to start nginx"
    echo "🔍 Checking nginx configuration..."
    nginx -t
    return 1
  fi
  
  echo "✅ SSL setup complete for UnicChat domains"
  
  # Отдельное сообщение для VCS доменов
  if [ -f "$VCS_CONFIG" ]; then
    source "$VCS_CONFIG"
    echo "ℹ️ VCS domains ($VCS_DNS, $VCS_TURN_DNS, $VCS_WHIP_DNS) will use Caddy for SSL"
  fi
}

activate_nginx() {
  echo -e "\n🚀 Activating Nginx sites…"
  nginx -t && systemctl reload nginx
  echo "✅ Nginx activated for all sites"
}

update_solid_env() {
  echo -e "\n🔗 Linking Knowledgebase MinIO with UnicChat solid…"
  
  local solid_env="unicchat.enterprise/multi-server-install/solid.env"
  local kb_config="unicchat.enterprise/knowledgebase/config.txt"
  
  if [ ! -f "$solid_env" ]; then
    echo "❌ solid.env file not found: $solid_env"
    return 1
  fi
  
  if [ ! -f "$kb_config" ]; then
    echo "❌ Knowledgebase config not found: $kb_config"
    echo "⚠️ Please deploy knowledgebase first to get MinIO credentials"
    return 1
  fi
  
  # Загружаем данные из knowledgebase config
  source "$kb_config"
  
  # Загружаем DNS конфигурацию
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Удаляем старую MinIO конфигурацию если есть
  sed -i '/# MinIO Configuration/,/MINIO_SECRET_KEY/d' "$solid_env"
  
  # Добавляем новую MinIO конфигурацию в правильном формате
  cat >> "$solid_env" <<EOF

# MinIO Configuration from Knowledgebase
UnInit.1="'Minio': { 'Type': 'NamedServiceAuth', 'IpOrHost': '$MINIO_DNS', 'UserName': '$MINIO_ROOT_USER', 'Password': '$MINIO_ROOT_PASSWORD' }"
EOF
  
  # Добавляем лицензию если она есть
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
  
  local appserver_env="unicchat.enterprise/multi-server-install/appserver.env"
  
  if [ ! -f "$appserver_env" ]; then
    echo "❌ appserver.env file not found: $appserver_env"
    return 1
  fi
  
  # Загружаем DNS конфигурацию
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Обновляем ROOT_URL в appserver.env
  sed -i "s|ROOT_URL=.*|ROOT_URL=https://$APP_DNS|" "$appserver_env"
  
  # Добавляем/обновляем DOCUMENT_SERVER_HOST
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
  
  # Подготавливаем основные env файлы
  local dir="unicchat.enterprise/multi-server-install"
  (cd "$dir" && chmod +x generate_env_files.sh && ./generate_env_files.sh)
  
  # Обновляем solid.env и appserver.env
  update_solid_env
  update_appserver_env
  
  echo "✅ All environment files prepared and updated"
}

update_env_files() {
  echo -e "\n🔗 Linking Knowledgebase services with UnicChat…"
  update_solid_env
  update_appserver_env
  echo "✅ All services linked successfully"
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
  local dir="unicchat.enterprise/multi-server-install"
  docker network inspect unicchat-backend >/dev/null 2>&1 || docker network create unicchat-backend
  docker network inspect unicchat-frontend >/dev/null 2>&1 || docker network create unicchat-frontend
  (cd "$dir" && docker_compose -f mongodb.yml -f unic.chat.appserver.yml -f unic.chat.solid.yml  up -d)
  echo "✅ Services started."
}

update_site_url() {
  echo -e "\n📝 Updating Site_Url in MongoDB…"
  local container="unic.chat.db.mongo"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Проверяем существование конфигурационного файла MongoDB
  if [ ! -f "mongo_config.txt" ]; then
    echo "❌ MongoDB configuration not found. Run 'Update MongoDB configuration' first."
    return 1
  fi
  
  # Загружаем настройки MongoDB из конфигурационного файла
  source "mongo_config.txt"
  
  # Проверяем, запущен ли контейнер
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "❌ MongoDB container is not running: $container"
    return 1
  fi
  
  local url="https://$APP_DNS"
  
  echo "🔄 Updating Site_Url to: $url"
  echo "📊 Using database: $MONGODB_DATABASE"
  
  # Первая команда - обновление value
  docker exec "$container" mongosh -u root -p "$MONGODB_ROOT_PASSWORD" --quiet --eval "db.getSiblingDB('$MONGODB_DATABASE').rocketchat_settings.updateOne({_id:'Site_Url'},{\$set:{value:'$url'}})"
  
  # Вторая команда - обновление packageValue
  docker exec "$container" mongosh -u root -p "$MONGODB_ROOT_PASSWORD" --quiet --eval "db.getSiblingDB('$MONGODB_DATABASE').rocketchat_settings.updateOne({_id:'Site_Url'},{\$set:{packageValue:'$url'}})"
  
  echo "✅ Site_Url updated successfully in database: $MONGODB_DATABASE"
}

prepare_knowledgebase() {
  echo -e "\n📚 Preparing knowledge base deployment…"
  local kb_dir="unicchat.enterprise/knowledgebase"
  
  if [ ! -d "$kb_dir" ]; then
    echo "❌ Knowledge base directory not found: $kb_dir"
    return 1
  fi
  
  # Делаем скрипт deploy_knowledgebase.sh исполняемым
  if [ -f "$kb_dir/deploy_knowledgebase.sh" ]; then
    chmod +x "$kb_dir/deploy_knowledgebase.sh"
    echo "✅ Knowledge base deployment script prepared"
  else
    echo "⚠️ Knowledge base deployment script not found: $kb_dir/deploy_knowledgebase.sh"
  fi
}

deploy_knowledgebase() {
  echo -e "\n🚀 Deploying knowledge base services…"
  local kb_dir="unicchat.enterprise/knowledgebase"
  
  if [ ! -f "$kb_dir/deploy_knowledgebase.sh" ]; then
    echo "❌ Knowledge base deployment script not found"
    return 1
  fi
  
  # Запускаем автоматическое развертывание базы знаний
  echo "📦 Running knowledge base deployment..."
  (cd "$kb_dir" && ./deploy_knowledgebase.sh --auto)
  
  echo "✅ Knowledge base services deployed"
}

prepare_vcs() {
  echo -e "\n📹 Preparing VCS (Video Communication Server)…"
  
  local vcs_dir="unicchat.enterprise/vcs.unic.chat.template"
  
  if [ ! -d "$vcs_dir" ]; then
    echo "❌ VCS directory not found: $vcs_dir"
    return 1
  fi
  
  # Загружаем VCS конфигурацию
  if [ ! -f "$VCS_CONFIG" ]; then
    echo "❌ VCS configuration not found. Run step 5 first."
    return 1
  fi
  source "$VCS_CONFIG"
  
  # Создаем .env файл для VCS
  cat > "$vcs_dir/.env" <<EOF
# домены VCS для работы, должны быть зарегистрированы и доступны
# после запуска сервера надо установить сертификаты через caddy

VCS_URL=$VCS_DNS
VCS_TURN_URL=$VCS_TURN_DNS
VCS_WHIP_URL=$VCS_WHIP_DNS
EOF
  
  echo "✅ VCS .env file created with DNS names"
  
  # Делаем скрипты исполняемыми
  chmod +x "$vcs_dir/install_server.sh" 2>/dev/null || true
  chmod +x "$vcs_dir/install_docker.sh" 2>/dev/null || true
  chmod +x "$vcs_dir/update_ip.sh" 2>/dev/null || true
  
  echo "✅ VCS preparation complete"
}

install_vcs() {
  echo -e "\n🚀 Installing VCS (Video Communication Server)…"
  
  local vcs_dir="unicchat.enterprise/vcs.unic.chat.template"
  local vcs_compose_dir="$vcs_dir/unicomm-vcs"
  local vcs_compose_file="$vcs_compose_dir/docker-compose.yaml"
  
  if [ ! -f "$vcs_dir/install_server.sh" ]; then
    echo "❌ VCS installation script not found"
    return 1
  fi
  
  # Проверяем наличие .env файла
  if [ ! -f "$vcs_dir/.env" ]; then
    echo "❌ VCS .env file not found. Run step 5 and VCS preparation first."
    return 1
  fi
  
  # Очищаем возможные конфликты с директориями
  if [ -d "$vcs_compose_dir/caddy.yaml" ]; then
    echo "🔄 Removing conflicting directory: $vcs_compose_dir/caddy.yaml"
    rm -rf "$vcs_compose_dir/caddy.yaml"
  fi
  
  echo "📦 Running VCS installation..."
  (cd "$vcs_dir" && ./install_server.sh)
  
  if [ $? -ne 0 ]; then
    echo "❌ VCS installation failed. Trying alternative approach..."
    
    # Альтернативный подход: создаем файлы вручную
    echo "🔄 Creating VCS files manually..."
    
    # Создаем директории
    mkdir -p "$vcs_compose_dir/caddy_data"
    
    # Загружаем VCS конфигурацию для получения DNS имен
    source "$VCS_CONFIG"
    
    # Создаем vcs.yaml
    cat > "$vcs_compose_dir/vcs.yaml" <<EOF
port: 7880
bind_addresses:
    - ""
rtc:
    tcp_port: 7881
    port_range_start: 50000
    port_range_end: 60000
    use_external_ip: true
    enable_loopback_candidate: false
redis:
    address: localhost:6379
    username: ""
    password: ""
    db: 0
    use_tls: false
    sentinel_master_name: ""
    sentinel_username: ""
    sentinel_password: ""
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
turn:
    enabled: true
    domain: $VCS_TURN_DNS
    tls_port: 5349
    udp_port: 3478
    external_tls: true
keys:
    APIFB6qLxKJDW7T: 1jH9vBVaFfBwMXDaBcjkQG8d6z5GBhUowsz2VhiDoqe
EOF
    
    # Получаем IP сервера для caddy.yaml
    SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
    
    # Создаем caddy.yaml
    cat > "$vcs_compose_dir/caddy.yaml" <<EOF
logging:
  logs:
    default:
      level: INFO
storage:
  "module": "file_system"
  "root": "/data"
apps:
  tls:
    certificates:
      automate:
        - $VCS_URL
        - $VCS_TURN_URL
  layer4:
    servers:
      main:
        listen: [":443"]
        routes:
          - match:
            - tls:
                sni:
                  - "$VCS_TURN_URL"
            handle:
              - handler: tls
              - handler: proxy
                upstreams:
                  - dial: ["localhost:5349"]
          - match:
              - tls:
                  sni:
                    - "$VCS_URL"
            handle:
              - handler: tls
                connection_policies:
                  - alpn: ["http/1.1"]
              - handler: proxy
                upstreams:
                  - dial: ["localhost:7880"]
EOF
    
    # Создаем остальные файлы
    cat > "$vcs_compose_dir/redis.conf" <<EOF
bind 127.0.0.1 ::1
protected-mode yes
port 6379
timeout 0
tcp-keepalive 300
EOF
    
    cat > "$vcs_compose_dir/egress.yaml" <<EOF
redis:
    address: localhost:6379
    username: ""
    password: ""
    db: 0
    use_tls: false
    sentinel_master_name: ""
    sentinel_username: ""
    sentinel_password: ""
    sentinel_addresses: []
    cluster_addresses: []
    max_redirects: null
api_key: APIFB6qLxKJDW7T
api_secret: 1jH9vBVaFfBwMXDaBcjkQG8d6z5GBhUowsz2VhiDoqe
ws_url: wss://$VCS_URL
EOF
    
    # Создаем update_ip.sh
    cat > "$vcs_compose_dir/update_ip.sh" <<"EOF"
#!/usr/bin/env bash
ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -1|cut -d" " -f6|cut -d/ -f1`
sed -i.orig -r "s/\\\"(.+)(\:5349)/\\\"$ip\2/" ./unicomm-vcs/caddy.yaml
EOF
    
    chmod +x "$vcs_compose_dir/update_ip.sh"
  fi
  
  # Получаем внешний IP адрес сервера
  echo "🌐 Getting server external IP address..."
  SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
  
  if [ -z "$SERVER_IP" ]; then
    echo "⚠️ Could not determine external IP, using local IP"
    SERVER_IP=$(hostname -I | awk '{print $1}')
  fi
  
  echo "📝 Setting external IP: $SERVER_IP"
  
  # Создаем исправленный docker-compose файл
  if [ -f "$vcs_compose_file" ]; then
    # Создаем backup
    cp "$vcs_compose_file" "$vcs_compose_file.backup"
    
    # Создаем исправленную версию
    cat > "$vcs_compose_file" <<EOF
# This docker-compose requires host networking, which is only available on Linux
# This compose will not function correctly on Mac or Windows
services:
  caddy:
    image: livekit/caddyl4:latest
    command: run --config /etc/caddy.yaml --adapter yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./caddy.yaml:/etc/caddy.yaml
      - ./caddy_data:/data
  vcs:
    image: livekit/livekit-server:v1.7.2
    command: --config /etc/livekit.yaml
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./vcs.yaml:/etc/livekit.yaml
    environment:
      - LIVEKIT_IP=$SERVER_IP
  redis:
    image: redis:7.4.1-alpine
    command: redis-server /etc/redis.conf
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./redis.conf:/etc/redis.conf
  egress:
    image: livekit/egress:latest
    restart: unless-stopped
    environment:
      - EGRESS_CONFIG_FILE=/etc/egress.yaml
    network_mode: "host"
    volumes:
      - ./egress.yaml:/etc/egress.yaml
    cap_add:
      - CAP_SYS_ADMIN
EOF
    
    echo "✅ Created corrected docker-compose.yaml with LIVEKIT_IP=$SERVER_IP"
    
  else
    echo "❌ VCS docker-compose.yaml not found"
    return 1
  fi
  
  # Запускаем docker-compose для VCS
  echo "🐳 Starting VCS services with docker-compose..."
  (cd "$vcs_compose_dir" && docker-compose up -d)
  
  if [ $? -eq 0 ]; then
    echo "✅ VCS docker-compose started successfully with external IP: $SERVER_IP"
  else
    echo "❌ Failed to start VCS docker-compose"
    echo "🔍 Checking docker-compose file syntax..."
    docker-compose -f "$vcs_compose_file" config
    return 1
  fi
  
  echo "✅ VCS installation completed"
}

auto_setup() {
  echo -e "\n⚙️ Running full automatic setup…"
  install_docker
  install_nginx_ssl
  install_git
  install_dns_utils
  install_minio_client
  clone_repo
  check_avx
  setup_dns_names
  setup_license
  update_mongo_config
  update_minio_config
  generate_nginx_conf
  deploy_nginx_conf
  copy_ssl_configs
  setup_ssl
  activate_nginx
  prepare_unicchat
  login_yandex
  start_unicchat
  update_site_url
  prepare_knowledgebase
  deploy_knowledgebase
  update_env_files
  prepare_vcs
  install_vcs
  echo -e "\n🎉 UnicChat setup complete! (including knowledge base and VCS)"
}

main_menu() {
  echo -e "\n✨ Welcome to UnicChat Installer with VCS"
  echo -e "✅ Email: $EMAIL"
  
  # Показываем текущие настройки если есть
  if [ -f "$DNS_CONFIG" ] && [ -f "$VCS_CONFIG" ]; then
    source "$DNS_CONFIG"
    source "$VCS_CONFIG"
    echo "📋 Current DNS configuration:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    echo "   VCS: $VCS_DNS"
    echo "   VCS TURN: $VCS_TURN_DNS"
    echo "   VCS WHIP: $VCS_WHIP_DNS"
  fi
  
  # Показываем информацию о лицензии если есть
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
 [6]  Clone repository
 [7]  Check AVX support
 [8]  Setup DNS names for all services (including VCS)
 [9]  Setup License Key
[10]  Update MongoDB configuration
[11]  Update MinIO configuration
[12]  Generate Nginx configs
[13]  Deploy Nginx configs
[14]  Copy SSL configs and generate DH params
[15]  Setup SSL certificates (all domains)
[16]  Activate Nginx sites
[17]  Prepare .env files
[18]  Login to Yandex registry
[19]  Start UnicChat containers
[20]  Update MongoDB Site_Url
[21]  Prepare knowledge base
[22]  Deploy knowledge base services
[23]  🔗 Link Knowledgebase with UnicChat
[24]  📹 Prepare VCS
[25]  📹 Install VCS
[99]  🚀 Full automatic setup (with knowledge base and VCS)
 [0]  Exit
MENU
    read -rp "👉 Select an option: " choice
    case $choice in
      1) install_docker ;;
      2) install_nginx_ssl ;;
      3) install_git ;;
      4) install_dns_utils ;;
      5) install_minio_client ;;
      6) clone_repo ;;
      7) check_avx ;;
      8) setup_dns_names ;;
      9) setup_license ;;
     10) update_mongo_config ;;
     11) update_minio_config ;;
     12) generate_nginx_conf ;;
     13) deploy_nginx_conf ;;
     14) copy_ssl_configs ;;
     15) setup_ssl ;;
     16) activate_nginx ;;
     17) prepare_unicchat ;;
     18) login_yandex ;;
     19) start_unicchat ;;
     20) update_site_url ;;
     21) prepare_knowledgebase ;;
     22) deploy_knowledgebase ;;
     23) update_env_files ;;
     24) prepare_vcs ;;
     25) install_vcs ;;
     99) auto_setup ;;
      0) echo "👋 Goodbye!" && break ;;
      *) echo "❓ Invalid option." ;;
    esac
    echo ""
  done
}

# === Start ===
load_config
main_menu "$@"
