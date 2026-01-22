#!/usr/bin/env bash
#
# Скрипт для управления SSL сертификатами и nginx для множественных сервисов
# Использует данные из dns_config.txt
#

set -euo pipefail

# Получаем данные из dns_config.txt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../dns_config.txt"

# Функция для выбора команды docker compose
docker_compose() {
    if command -v docker compose >/dev/null 2>&1; then
        docker compose "$@"
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    else
        echo "❌ docker compose not found. Установите Docker и Docker Compose."
        exit 1
    fi
}

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Файл dns_config.txt не найден: $CONFIG_FILE"
        return 1
    fi

    source "$CONFIG_FILE"

    if [ -z "$APP_DNS" ] || [ -z "$EDT_DNS" ] || [ -z "$MINIO_DNS" ]; then
        echo "❌ DNS names not found in dns_config.txt"
        echo "   Required: APP_DNS, EDT_DNS, MINIO_DNS"
        return 1
    fi

    # Load email if available
    EMAIL=""
    if [ -f "$SCRIPT_DIR/../unicchat_config.txt" ]; then
        EMAIL=$(grep '^EMAIL=' "$SCRIPT_DIR/../unicchat_config.txt" | cut -d '=' -f2- | tr -d '\r' | tr -d ' ')
    fi

    if [ -z "$EMAIL" ]; then
        read -rp "📧 Введите email для Let's Encrypt (для уведомлений о сертификате): " EMAIL
        if [ -z "$EMAIL" ]; then
            echo "❌ Email обязателен для получения SSL сертификатов"
            return 1
        fi
        # Сохраняем email для будущего использования
        echo "EMAIL=$EMAIL" >> "$SCRIPT_DIR/../unicchat_config.txt"
    fi

    return 0
}

generate_ssl() {
    if [[ $EUID -ne 0 ]]; then
        echo "🚫 This function must be run as root or with sudo."
        return 1
    fi

    load_config || return 1
    cd "$SCRIPT_DIR"

    echo "🔐 Генерация SSL сертификатов для доменов:"
    echo "   App Server: $APP_DNS"
    echo "   Document Server: $EDT_DNS"
    echo "   MinIO: $MINIO_DNS"
    echo "📧 Email: $EMAIL"
    echo ""

    # Создаем необходимые директории
    mkdir -p ssl www
    chmod 755 ssl www

    # Скачиваем options-ssl-nginx.conf если его нет
    if [ ! -f "ssl/options-ssl-nginx.conf" ]; then
        echo "📥 Скачивание options-ssl-nginx.conf..."
        curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > ssl/options-ssl-nginx.conf
        echo "   ✅ Файл скачан"
    fi

    # Генерируем DH parameters если их нет
    if [ ! -f "ssl/ssl-dhparams.pem" ]; then
        echo "⏳ Генерация DH parameters (это может занять несколько минут)..."
        docker run --rm \
          -v "$(pwd)/ssl:/etc/letsencrypt" \
          alpine:latest \
          sh -c "apk add --no-cache openssl && openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048"
        echo "   ✅ DH parameters сгенерированы"
    fi

    # Проверяем что сеть существует
    if ! docker network inspect unicchat-network >/dev/null 2>&1; then
        echo "🌐 Создание сети unicchat-network..."
        docker network create unicchat-network
        echo "   ✅ Сеть создана"
    fi

    # Останавливаем nginx если запущен
    echo "🛑 Остановка nginx (если запущен) для освобождения портов 80/443..."
    docker stop unicchat.nginx 2>/dev/null || true
    docker rm unicchat.nginx 2>/dev/null || true
    sleep 2

    # Проверяем что порты 80 и 443 свободны
    if ss -tuln 2>/dev/null | grep -E ':(80|443) ' || netstat -tuln 2>/dev/null | grep -E ':(80|443) '; then
        echo "⚠️ Порты 80 или 443 заняты. Проверьте что их использует:"
        ss -tulpn 2>/dev/null | grep -E ':(80|443) ' || netstat -tulpn 2>/dev/null | grep -E ':(80|443) ' || true
        echo ""
        read -rp "Продолжить anyway? (y/N): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo "❌ Отменено"
            return 1
        fi
    fi

    # Генерируем SSL сертификаты для всех доменов
    echo "🔐 Генерация SSL сертификатов через Let's Encrypt..."
    echo ""

    docker run --rm \
      --network unicchat-network \
      -p 80:80 \
      -p 443:443 \
      -v "$(pwd)/ssl:/etc/letsencrypt" \
      certbot/certbot certonly \
      --standalone \
      --preferred-challenges http \
      --email "$EMAIL" \
      --agree-tos \
      --no-eff-email \
      --non-interactive \
      --verbose \
      -d "$APP_DNS" \
      -d "$EDT_DNS" \
      -d "$MINIO_DNS" || {
        echo ""
        echo "❌ Не удалось получить SSL сертификаты"
        echo ""
        echo "⚠️ Проверьте:"
        echo "   1. Домены указывают на IP сервера"
        echo "   2. Порты 80/443 свободны и доступны извне"
        echo "   3. Firewall разрешает входящие соединения"
        echo ""
        return 1
      }

    echo ""
    echo "✅ SSL сертификаты успешно получены!"
    echo ""

    # Генерируем конфигурацию nginx
    echo "📝 Генерация конфигурации nginx для всех сервисов..."
    generate_config_files
    echo ""

    # Запускаем nginx через функцию start_nginx
    # (не дублируем код, используем готовую функцию с правильными проверками)
    if ! start_nginx; then
        echo "❌ Не удалось запустить nginx"
        return 1
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ Готово! SSL сертификаты установлены и nginx запущен."
    echo ""
    echo "📁 Расположение сертификатов:"
    echo "   $(pwd)/ssl/live/$APP_DNS/"
    echo ""
    echo "🌐 Проверьте работу:"
    echo "   curl https://$APP_DNS"
    echo "   curl https://$EDT_DNS"
    echo "   curl https://$MINIO_DNS:9002"
    echo ""
}

generate_config_files() {
    load_config || return 1
    cd "$SCRIPT_DIR"

    echo "📝 Генерация конфигурации nginx для трех сервисов..."

    # Создаем главный конфигурационный файл
    cat > config/nginx.conf <<EOF
# Nginx configuration for UnicChat Enterprise
# Auto-generated configuration for multiple services

# Upstream для App Server
upstream app_server {
    server unicchat.appserver:3000;
}

# Upstream для Document Server  
upstream doc_server {
    server unicchat.documentserver:80;
}

# Upstream для MinIO
upstream minio_server {
    server unicchat.minio:9000;
}

upstream minio_console {
    server unicchat.minio:9002;
}

# ============================================================================
# App Server (UnicChat Application)
# ============================================================================
server {
    listen 443 ssl;
    http2 on;
    server_name $APP_DNS;

    client_max_body_size 200M;

    error_log /var/log/nginx/app.error.log;
    access_log /var/log/nginx/app.access.log;

    # CORS headers
    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Credentials true;
    add_header "Access-Control-Allow-Methods" "GET, POST, OPTIONS, HEAD, PUT, DELETE";
    add_header "Access-Control-Allow-Headers" "Authorization, Origin, X-Requested-With, Content-Type, Accept";

    # Preflight requests
    if (\$request_method = OPTIONS) {
        return 204;
    }

    location / {
        proxy_pass http://app_server;
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

    ssl_certificate /etc/letsencrypt/live/$APP_DNS/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$APP_DNS/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name $APP_DNS;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# ============================================================================
# Document Server (OnlyOffice)
# ============================================================================
server {
    listen 443 ssl;
    http2 on;
    server_name $EDT_DNS;

    client_max_body_size 200M;

    error_log /var/log/nginx/edt.error.log;
    access_log /var/log/nginx/edt.access.log;

    location / {
        proxy_pass http://doc_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_redirect off;
    }

    ssl_certificate /etc/letsencrypt/live/$APP_DNS/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$APP_DNS/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name $EDT_DNS;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# ============================================================================
# MinIO S3 API
# ============================================================================
server {
    listen 443 ssl;
    http2 on;
    server_name $MINIO_DNS;

    client_max_body_size 500M;

    error_log /var/log/nginx/minio.error.log;
    access_log /var/log/nginx/minio.access.log;

    # Disable buffering for large files
    proxy_buffering off;
    proxy_request_buffering off;

    location / {
        proxy_pass http://minio_server;
        proxy_http_version 1.1;
        proxy_set_header Host \$http_host;

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # MinIO-specific headers
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-NginX-Proxy true;

        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }

    ssl_certificate /etc/letsencrypt/live/$APP_DNS/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$APP_DNS/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name $MINIO_DNS;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# ============================================================================
# MinIO Console (Web UI) - port 9002
# ============================================================================
server {
    listen 9002 ssl;
    http2 on;
    server_name $MINIO_DNS;

    error_log /var/log/nginx/minio-console.error.log;
    access_log /var/log/nginx/minio-console.access.log;

    location / {
        proxy_pass http://minio_console;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;

        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_redirect off;
    }

    ssl_certificate /etc/letsencrypt/live/$APP_DNS/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$APP_DNS/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
EOF

    echo "   ✅ Конфигурация создана: config/nginx.conf"
}

start_nginx() {
    if [[ $EUID -ne 0 ]]; then
        echo "🚫 This function must be run as root or with sudo."
        return 1
    fi

    load_config
    cd "$SCRIPT_DIR"

    echo "🌐 Запуск nginx..."

    # Проверяем что сеть существует
    if ! docker network inspect unicchat-network >/dev/null 2>&1; then
        echo "🌐 Создание сети unicchat-network..."
        docker network create unicchat-network
    fi

    # Генерируем конфигурацию
    if [ -f "ssl/live/$APP_DNS/fullchain.pem" ]; then
        echo "📝 Обновление конфигурации nginx с SSL..."
        generate_config_files
    else
        echo "⚠️ SSL сертификаты не найдены. Сначала сгенерируйте их (опция 1)."
        return 1
    fi

    docker_compose up -d nginx
    
    echo "   ⏳ Ожидание запуска nginx..."
    sleep 3
    
    if docker ps --filter "name=unicchat.nginx" --filter "status=running" | grep -q "unicchat.nginx"; then
        echo "   ✅ Nginx контейнер запущен"
        
        # Проверяем что worker process запустился
        if docker exec unicchat.nginx sh -c "ps aux | grep 'nginx: worker process' | grep -v grep" >/dev/null 2>&1; then
            echo "   ✅ Nginx worker process активен"
        fi
        
        # Проверяем конфигурацию
        if docker exec unicchat.nginx nginx -t 2>&1 | grep -q "successful"; then
            echo "   ✅ Конфигурация nginx корректна"
        else
            echo "   ⚠️ Ошибка в конфигурации nginx"
            docker exec unicchat.nginx nginx -t
        fi
        
        # Показываем healthcheck статус (если есть)
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' unicchat.nginx 2>/dev/null || echo "none")
        if [ "$health_status" != "none" ]; then
            echo "   ℹ️  Healthcheck: $health_status"
        fi
        
        return 0
    else
        echo "   ❌ Nginx контейнер не запустился. Проверьте логи:"
        echo "      docker logs unicchat.nginx"
        return 1
    fi
    echo ""
}

stop_nginx() {
    if [[ $EUID -ne 0 ]]; then
        echo "🚫 This function must be run as root or with sudo."
        return 1
    fi

    cd "$SCRIPT_DIR"
    echo "🛑 Остановка nginx..."
    docker_compose stop nginx 2>/dev/null || docker stop unicchat.nginx 2>/dev/null || true
    echo "   ✅ Nginx остановлен"
    echo ""
}

restart_nginx() {
    if [[ $EUID -ne 0 ]]; then
        echo "🚫 This function must be run as root or with sudo."
        return 1
    fi

    load_config
    cd "$SCRIPT_DIR"

    echo "🔄 Перезапуск nginx..."

    # Обновляем конфигурацию
    if [ -f "ssl/live/$APP_DNS/fullchain.pem" ]; then
        generate_config_files
    fi

    docker restart unicchat.nginx 2>/dev/null || docker_compose restart nginx
    sleep 2

    if docker ps | grep -q "unicchat.nginx"; then
        echo "   ✅ Nginx перезапущен"
    else
        echo "   ⚠️ Nginx не запустился. Проверьте логи"
    fi
    echo ""
}

status() {
    cd "$SCRIPT_DIR"
    load_config 2>/dev/null || true

    echo "📊 Статус сервисов:"
    echo ""

    # Статус nginx
    if docker ps --filter "name=unicchat.nginx" --filter "status=running" | grep -q "unicchat.nginx"; then
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' unicchat.nginx 2>/dev/null || echo "none")
        if [ "$health_status" = "healthy" ]; then
            echo "✅ Nginx: запущен (healthy)"
        elif [ "$health_status" = "unhealthy" ]; then
            echo "⚠️ Nginx: запущен (unhealthy)"
        elif [ "$health_status" = "starting" ]; then
            echo "🔄 Nginx: запускается..."
        else
            echo "✅ Nginx: запущен (no healthcheck)"
        fi
        docker ps --filter "name=unicchat.nginx" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ Nginx: остановлен"
    fi
    echo ""
    
    # Статус certbot
    if docker ps --filter "name=unicchat.certbot" --filter "status=running" | grep -q "unicchat.certbot"; then
        local certbot_health=$(docker inspect --format='{{.State.Health.Status}}' unicchat.certbot 2>/dev/null || echo "none")
        if [ "$certbot_health" = "healthy" ]; then
            echo "✅ Certbot: запущен (healthy)"
        elif [ "$certbot_health" = "unhealthy" ]; then
            echo "⚠️ Certbot: запущен (unhealthy)"
        else
            echo "✅ Certbot: запущен (no healthcheck)"
        fi
    else
        echo "⚠️ Certbot: остановлен (авто-обновление сертификатов недоступно)"
    fi
    echo ""

    # Проверка SSL сертификатов
    if [ -n "${APP_DNS:-}" ] && [ -f "ssl/live/$APP_DNS/fullchain.pem" ]; then
        echo "✅ SSL сертификаты: найдены"
        echo "   Путь: ssl/live/$APP_DNS/"
        if command -v openssl >/dev/null 2>&1; then
            echo "   Срок действия:"
            openssl x509 -in "ssl/live/$APP_DNS/fullchain.pem" -noout -dates 2>/dev/null | sed 's/^/      /' || true
        fi
        
        # Проверяем домены в сертификате
        echo "   Домены в сертификате:"
        openssl x509 -in "ssl/live/$APP_DNS/fullchain.pem" -noout -text 2>/dev/null | grep -A 1 "Subject Alternative Name" | tail -1 | sed 's/^/      /' || true
    else
        echo "❌ SSL сертификаты: не найдены"
    fi
    echo ""

    # Проверка портов
    echo "🔌 Прослушиваемые порты:"
    if ss -tuln 2>/dev/null | grep -E ':(80|443)' >/dev/null; then
        ss -tuln 2>/dev/null | grep -E ':(80|443)' | sed 's/^/   /'
    elif netstat -tuln 2>/dev/null | grep -E ':(80|443)' >/dev/null; then
        netstat -tuln 2>/dev/null | grep -E ':(80|443)' | sed 's/^/   /'
    else
        echo "   ⚠️ Порты 80/443 не слушаются"
    fi
    echo ""
}

logs_nginx() {
    cd "$SCRIPT_DIR"
    echo "📋 Логи nginx (последние 50 строк):"
    echo ""
    docker logs --tail 50 unicchat.nginx 2>&1 || echo "Контейнер nginx не найден"
    echo ""
}

test_config() {
    if [[ $EUID -ne 0 ]]; then
        echo "🚫 This function must be run as root or with sudo."
        return 1
    fi

    cd "$SCRIPT_DIR"
    if docker ps | grep -q "unicchat.nginx"; then
        echo "🔍 Проверка конфигурации nginx:"
        docker exec unicchat.nginx nginx -t
    else
        echo "❌ Nginx не запущен"
    fi
    echo ""
}

main_menu() {
    # Загружаем конфигурацию
    if load_config 2>/dev/null; then
        :
    else
        APP_DNS=""
        EDT_DNS=""
        MINIO_DNS=""
    fi
    
    while true; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔐 Управление SSL и Nginx для UnicChat Enterprise"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        if [ -n "${APP_DNS:-}" ]; then
            echo "📋 Конфигурация:"
            echo "   App Server: $APP_DNS"
            echo "   Document Server: $EDT_DNS"
            echo "   MinIO: $MINIO_DNS"
            echo ""
        else
            echo "⚠️  Файл dns_config.txt не найден или DNS имена не указаны"
            echo "   Запустите сначала основной скрипт установки (unicchat.sh)"
            echo ""
        fi

        cat <<MENU
 [1] 🔐 Генерация SSL сертификатов (Let's Encrypt)
 [2] 📝 Генерация/обновление конфигурации nginx
 [3] 🌐 Запуск nginx
 [4] 🛑 Остановка nginx
 [5] 🔄 Перезапуск nginx
 [6] 📊 Статус сервисов
 [7] 📋 Логи nginx
 [8] 🔍 Проверка конфигурации nginx
[99] 🚀 Полная автоустановка (SSL + nginx)
 [0] 🚪 Выход
MENU
        echo ""
        read -rp "👉 Выберите опцию: " choice
        echo ""

        case $choice in
            1) generate_ssl ;;
            2) 
                if [ -z "${APP_DNS:-}" ]; then
                    load_config
                fi
                generate_config_files 
                ;;
            3) start_nginx ;;
            4) stop_nginx ;;
            5) restart_nginx ;;
            6) status ;;
            7) logs_nginx ;;
            8) test_config ;;
            99)
                echo "🚀 Запуск полной автоустановки SSL и nginx..."
                echo ""
                if generate_ssl; then
                    echo ""
                    echo "✅ SSL сертификаты успешно созданы"
                    echo "🔄 Запуск nginx и certbot..."
                    echo ""
                    start_nginx
                    echo ""
                    echo "🔄 Запуск certbot для автоматического обновления..."
                    docker_compose up -d certbot
                    echo "   ✅ Certbot запущен (обновление каждые 12 часов)"
                    echo ""
                    echo "✅ Автоустановка завершена!"
                    echo ""
                    status
                else
                    echo "❌ Ошибка при генерации SSL сертификатов"
                fi
                ;;
            0) echo "👋 До свидания!" && exit 0 ;;
            *) echo "❌ Неверный выбор. Нажмите Enter для продолжения..." && read ;;
        esac

        if [ "$choice" != "0" ]; then
            echo ""
            read -rp "Нажмите Enter для продолжения..."
        fi
    done
}

# Запуск меню
main_menu
