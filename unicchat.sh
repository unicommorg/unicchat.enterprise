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

# Load or initialize DOMAIN and EMAIL from domain.usr.txt
DOMAIN=""
EMAIL=""
CONFIG_FILE="domain.usr.txt"

load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    echo "📄 Loading domain and email from $CONFIG_FILE..."
    DOMAIN=$(grep '^DOMAIN=' "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r')
    EMAIL=$(grep '^EMAIL=' "$CONFIG_FILE" | cut -d '=' -f2- | tr -d '\r')
  else
    echo "🔧 First-time setup:"
    while [ -z "$DOMAIN" ]; do
      read -rp "🌍 Enter the domain name (e.g. example.com): " DOMAIN
    done
    while [ -z "$EMAIL" ]; do
      read -rp "📧 Enter contact email for Let's Encrypt: " EMAIL
    done
    echo "DOMAIN=$DOMAIN" > "$CONFIG_FILE"
    echo "EMAIL=$EMAIL" >> "$CONFIG_FILE"
    echo "✅ Configuration saved to $CONFIG_FILE"
  fi
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

setup_domain() {
  echo -e "\n🌐 Writing domain into configs and checking DNS…"
  echo "$DOMAIN" > "unicchat.enterprise/nginx/domain.txt"
  echo "$DOMAIN" > "unicchat.enterprise/domain.txt"
  dig "$DOMAIN" +short || true
  echo "✅ Domain set."
}

generate_nginx_conf() {
  echo -e "\n🛠️ Generating Nginx config…"
  (cd unicchat.enterprise && chmod +x ./nginx/generate_nginx_conf.sh && ./nginx/generate_nginx_conf.sh)
}

backup_nginx_conf() {
  local target="/etc/nginx/sites-available/$DOMAIN.conf"
  if [ -f "$target" ]; then
    local backup="${target}.bak_$(date +%Y%m%d%H%M%S)"
    echo "💾 Backing up existing config to $backup"
    cp "$target" "$backup"
  fi
}

deploy_nginx_conf() {
  echo -e "\n📤 Deploying Nginx config…"
  local conf=""
  for path in \
    "unicchat.enterprise/$DOMAIN.conf" \
    "unicchat.enterprise/$DOMAIN" \
    "unicchat.enterprise/nginx/$DOMAIN.conf" \
    "unicchat.enterprise/nginx/$DOMAIN"
  do
    [ -f "$path" ] && conf="$path" && break
  done

  if [ -z "$conf" ]; then
    echo "❌ Config not found. Run step 5 first."
    return
  fi

  backup_nginx_conf
  cp "$conf" "/etc/nginx/sites-available/$DOMAIN.conf"
  [ -f "unicchat.enterprise/nginx/options-ssl-nginx.conf" ] && cp "unicchat.enterprise/nginx/options-ssl-nginx.conf" "/etc/letsencrypt/"
  echo "✅ Config deployed."
}

setup_ssl() {
  echo -e "\n🔐 Requesting SSL certificate…"
  certbot --nginx --non-interactive --agree-tos --email "$EMAIL" -d "$DOMAIN"
  echo -e "\n⏳ Generating DH parameters…"
  mkdir -p /etc/letsencrypt
  openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
  echo "✅ SSL and DH ready."
}

activate_nginx() {
  echo -e "\n🚀 Activating Nginx site…"
  ln -sf "/etc/nginx/sites-available/$DOMAIN.conf" "/etc/nginx/sites-enabled/$DOMAIN.conf"
  rm -f /etc/nginx/sites-enabled/default || true
  nginx -t && systemctl reload nginx
  echo "✅ Nginx activated."
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
  local pwd=$(grep -E '^MONGODB_ROOT_PASSWORD=' "$env_file" | cut -d '=' -f2 | tr -d '\r')
  local url="https://$DOMAIN"
  docker exec "$container" mongosh -u root -p "$pwd" --quiet --eval "db.getSiblingDB('unicchat_db').rocketchat_settings.updateOne({_id:'Site_Url'},{\$set:{value:'$url'}})"
  docker exec "$container" mongosh -u root -p "$pwd" --quiet --eval "db.getSiblingDB('unicchat_db').rocketchat_settings.updateOne({_id:'Site_Url'},{\$set:{packageValue:'$url'}})"
  echo "✅ Site_Url updated."
}

# ===== НОВЫЕ ФУНКЦИИ ДЛЯ БАЗЫ ЗНАНИЙ =====

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

# ===== КОНЕЦ НОВЫХ ФУНКЦИЙ =====

auto_setup() {
  echo -e "\n⚙️ Running full automatic setup…"
  install_deps
  install_minio_client
  clone_repo
  check_avx
  setup_domain
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
  echo -e "✅ Domain: $DOMAIN | Email: $EMAIL\n"
  while true; do
    cat <<MENU
 [1]  Install dependencies
 [2]  Install MinIO client (mc)
 [3]  Clone repository
 [4]  Check AVX support
 [5]  Setup domain and check DNS
 [6]  Generate Nginx config
 [7]  Deploy Nginx config (with backup)
 [8]  Setup SSL certificate
 [9]  Activate Nginx site
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
      5) setup_domain ;;
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
