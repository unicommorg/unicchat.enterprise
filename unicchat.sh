#!/usr/bin/env bash
#
# UnicChat installation helper (обновлено 2025-08-05)
#

set -euo pipefail

# Ensure running as root or via sudo
if [[ $EUID -ne 0 ]]; then
  echo "🚫 This script must be run as root or with sudo."
  exit 1
fi

# Конфигурационные файлы
CONFIG_FILE="app_config.txt"
DNS_CONFIG="dns_config.txt"

# Переменные
EMAIL=""
APP_DNS=""
EDT_DNS=""
MINIO_DNS=""

load_config() {
  # Загружаем email из конфига если есть
  if [ -f "$CONFIG_FILE" ]; then
    echo "📄 Loading email from $CONFIG_FILE..."
    EMAIL=$(grep '^EMAIL=' "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r' | tr -d '"')
  fi
  
  # Запрашиваем email если нет в конфиге
  if [ -z "$EMAIL" ]; then
    echo "🔧 First-time setup:"
    while [ -z "$EMAIL" ]; do
      read -rp "📧 Enter contact email for Let's Encrypt: " EMAIL
    done
    echo "EMAIL=\"$EMAIL\"" > "$CONFIG_FILE"
    echo "✅ Email saved to $CONFIG_FILE"
  fi
  
  # Загружаем DNS конфигурацию если есть
  if [ -f "$DNS_CONFIG" ]; then
    echo "📄 Loading DNS configuration from $DNS_CONFIG..."
    source "$DNS_CONFIG"
    echo "✅ DNS names loaded from config"
  fi
}

# Функция для настройки DNS имен всех сервисов
setup_dns_names() {
  echo -e "\n🌐 Setting up DNS names for all services..."
  
  if [ -f "$DNS_CONFIG" ]; then
    source "$DNS_CONFIG"
    echo "✅ DNS names loaded from config:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    return
  fi
  
  echo "🔧 Configure DNS names for services:"
  
  while [ -z "$APP_DNS" ]; do
    read -rp "Enter DNS for App Server (e.g. app.unic.chat): " APP_DNS
  done
  
  while [ -z "$EDT_DNS" ]; do
    read -rp "Enter DNS for Document Server (e.g. docs.unic.chat): " EDT_DNS
  done
  
  while [ -z "$MINIO_DNS" ]; do
    read -rp "Enter DNS for MinIO (e.g. minio.unic.chat): " MINIO_DNS
  done
  
  # Сохраняем в конфиг
  cat > "$DNS_CONFIG" <<EOF
APP_DNS="$APP_DNS"
EDT_DNS="$EDT_DNS"
MINIO_DNS="$MINIO_DNS"
EOF
  echo "✅ DNS configuration saved to $DNS_CONFIG"
}

install_deps() {
  echo -e "\n🔧 Adding Docker APT repository and installing dependencies…"

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
  
  # Устанавливаем пакеты с принудительным разрешением зависимостей
  apt install -y -f docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose nginx certbot python3-certbot-nginx git dnsutils

  echo "✅ Dependencies installed (including docker compose plugin)."
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
  (cd unicchat.enterprise && git fetch --all && git switch skonstantinov-patch-2)
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

# Новая функция генерации Nginx конфигов
generate_nginx_conf() {
  echo -e "\n🛠️ Generating Nginx configs for all services…"
  
  # Загружаем DNS конфигурацию
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
  
  # Генерируем конфиги для всех сервисов
  generate_config "$APP_DNS" "myapp" "$APP_PORT"
  generate_config "$EDT_DNS" "edtapp" "$EDT_PORT"
  generate_config "$MINIO_DNS" "myminio" "$MINIO_PORT"
  
  echo "🎉 All Nginx configs generated in unicchat.enterprise/nginx/generated/"
}

# Новая функция для применения всех Nginx конфигов
deploy_nginx_conf() {
  echo -e "\n📤 Deploying all Nginx configs…"
  
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
  
  # Создаем симлинки для всех доменов
  sudo ln -sf "/etc/nginx/sites-available/${APP_DNS}.conf" "/etc/nginx/sites-enabled/" || true
  sudo ln -sf "/etc/nginx/sites-available/${EDT_DNS}.conf" "/etc/nginx/sites-enabled/" || true
  sudo ln -sf "/etc/nginx/sites-available/${MINIO_DNS}.conf" "/etc/nginx/sites-enabled/" || true
  
  # Удаляем дефолтный конфиг
  sudo rm -f /etc/nginx/sites-enabled/default || true
  
  echo "✅ All Nginx configs deployed"
}

# Новая функция для создания SSL сертификатов для всех доменов
setup_ssl() {
  echo -e "\n🔐 Setting up SSL certificates for all domains…"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  # Собираем все домены в массив
  local domains=()
  [ -n "$APP_DNS" ] && domains+=("$APP_DNS")
  [ -n "$EDT_DNS" ] && domains+=("$EDT_DNS")
  [ -n "$MINIO_DNS" ] && domains+=("$MINIO_DNS")
  
  if [ ${#domains[@]} -eq 0 ]; then
    echo "❌ No domains found in DNS config."
    return 1
  fi
  
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
  
  echo -e "\n⏳ Generating DH parameters (if not exist)…"
  if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
    sudo openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
  else
    echo "ℹ️ DH parameters already exist, skipping generation."
  fi
  
  echo "▶️ Starting nginx..."
  sudo systemctl start nginx
  
  echo "✅ SSL setup complete."
}
activate_nginx() {
  echo -e "\n🚀 Activating Nginx sites…"
  nginx -t && systemctl reload nginx
  echo "✅ Nginx activated for all sites"
}

prepare_unicchat() {
  echo -e "\n📦 Preparing env files…"
  local dir="unicchat.enterprise/multi-server-install"
  (cd "$dir" && chmod +x generate_env_files.sh && ./generate_env_files.sh)
  echo "✅ Env ready."
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
  local dir="unicchat.enterprise/multi-server-install"
  local env_file="$dir/mongo.env"
  local container="unic.chat.db.mongo"
  
  if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ DNS configuration not found. Run step 5 first."
    return 1
  fi
  source "$DNS_CONFIG"
  
  local pwd=$(grep -E '^MONGODB_ROOT_PASSWORD=' "$env_file" | cut -d '=' -f2 | tr -d '\r')
  local url="https://$APP_DNS"
  
  docker exec "$container" mongosh -u root -p "$pwd" --quiet --eval "db.getSiblingDB('unicchat_db').rocketchat_settings.updateOne({_id:'Site_Url'},{\$set:{value:'$url'}})"
  docker exec "$container" mongosh -u root -p "$pwd" --quiet --eval "db.getSiblingDB('unicchat_db').rocketchat_settings.updateOne({_id:'Site_Url'},{\\$set:{packageValue:'$url'}})"
  echo "✅ Site_Url updated to: $url"
}

# ===== ФУНКЦИИ ДЛЯ БАЗЫ ЗНАНИЙ =====

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

# ===== ОСНОВНОЕ МЕНЮ =====

auto_setup() {
  echo -e "\n⚙️ Running full automatic setup…"
  install_deps
  install_minio_client
  clone_repo
  check_avx
  setup_dns_names
  generate_nginx_conf
  deploy_nginx_conf
  setup_ssl
  activate_nginx
  prepare_unicchat
  login_yandex
  start_unicchat
  update_site_url
  prepare_knowledgebase
  deploy_knowledgebase
  echo -e "\n🎉 UnicChat setup complete! (including knowledge base)"
}

main_menu() {
  echo -e "\n✨ Welcome to UnicChat Installer"
  echo -e "✅ Email: $EMAIL\n"
  
  # Показываем текущие DNS настройки если есть
  if [ -f "$DNS_CONFIG" ]; then
    source "$DNS_CONFIG"
    echo "📋 Current DNS configuration:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    echo ""
  fi
  
  while true; do
    cat <<MENU
 [1]  Install dependencies
 [2]  Install MinIO client (mc)
 [3]  Clone repository
 [4]  Check AVX support
 [5]  Setup DNS names for all services
 [6]  Generate Nginx configs
 [7]  Deploy Nginx configs
 [8]  Setup SSL certificates (all domains)
 [9]  Activate Nginx sites
[10]  Prepare .env files
[11]  Login to Yandex registry
[12]  Start UnicChat containers
[13]  Update MongoDB Site_Url
[14]  Prepare knowledge base
[15]  Deploy knowledge base services
[99]  🚀 Full automatic setup (with knowledge base)
 [0]  Exit
MENU
    read -rp "👉 Select an option: " choice
    case $choice in
      1) install_deps ;;
      2) install_minio_client ;;
      3) clone_repo ;;
      4) check_avx ;;
      5) setup_dns_names ;;
      6) generate_nginx_conf ;;
      7) deploy_nginx_conf ;;
      8) setup_ssl ;;
      9) activate_nginx ;;
      10) prepare_unicchat ;;
      11) login_yandex ;;
      12) start_unicchat ;;
      13) update_site_url ;;
      14) prepare_knowledgebase ;;
      15) deploy_knowledgebase ;;
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
