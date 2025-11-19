#!/bin/bash

# Файл для хранения настроек DNS
DNS_CONFIG="dns_config.txt"

# Получаем текущий IP адрес сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

# Порты по умолчанию для каждого сервиса
APP_PORT="8080"
EDT_PORT="8880" 
MINIO_PORT="9000"

# Функция для запроса DNS имени
ask_dns() {
    local service_name=$1
    local default_dns=$2
    local dns_var=""
    
    read -p "Введите DNS имя для $service_name [$default_dns]: " dns_var
    dns_var=${dns_var:-$default_dns}
    echo "$dns_var"
}

# Загружаем или запрашиваем DNS имена
if [ -f "$DNS_CONFIG" ]; then
    echo "📄 Загружаем DNS конфигурацию из $DNS_CONFIG..."
    source "$DNS_CONFIG"
else
    echo "🔧 Настройка DNS имен для сервисов:"
    echo "   IP сервера: $SERVER_IP"
    echo ""
    APP_DNS=$(ask_dns "App Server" "myapp.unic.chat")
    EDT_DNS=$(ask_dns "Document Server" "myedt.unic.chat")
    MINIO_DNS=$(ask_dns "MinIO" "myminio.unic.chat")
    
    # Сохраняем в конфиг
    cat > "$DNS_CONFIG" <<EOF
APP_DNS="$APP_DNS"
EDT_DNS="$EDT_DNS" 
MINIO_DNS="$MINIO_DNS"
EOF
    echo "✅ Конфигурация сохранена в $DNS_CONFIG"
fi

echo ""
echo "📋 Текущие DNS настройки:"
echo "   IP сервера:      $SERVER_IP"
echo "   App Server:      $APP_DNS → myapp:$APP_PORT"
echo "   Document Server: $EDT_DNS → edtapp:$EDT_PORT"
echo "   MinIO:           $MINIO_DNS → myminio:$MINIO_PORT"
echo ""

# Функция для генерации конфига Nginx
generate_nginx_config() {
    local domain=$1
    local upstream=$2
    local port=$3
    
    local output_file="${domain}.conf"
    
    echo "🔧 Генерация конфига для: $domain → $upstream:$port"
    
    cat > "$output_file" <<EOF
# Конфигурация для $domain
# Generated: $(date)
# Server IP: $SERVER_IP

upstream $upstream {
    server $SERVER_IP:$port;
}

# HTTPS Server
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
    
    echo "✅ Создан: $output_file"
    echo ""
}

# Генерируем конфиги для всех сервисов
generate_nginx_config "$APP_DNS" "myapp" "$APP_PORT"
generate_nginx_config "$EDT_DNS" "edtapp" "$EDT_PORT" 
generate_nginx_config "$MINIO_DNS" "myminio" "$MINIO_PORT"

echo "🎉 Все конфигурации Nginx успешно сгенерированы!"
echo ""
echo "📋 Созданные файлы:"
ls -la *.conf
echo ""
echo "ℹ️  Для применения конфигов выполните:"
echo "   sudo cp *.conf /etc/nginx/sites-available/"
echo "   sudo ln -sf /etc/nginx/sites-available/${APP_DNS}.conf /etc/nginx/sites-enabled/"
echo "   sudo ln -sf /etc/nginx/sites-available/${EDT_DNS}.conf /etc/nginx/sites-enabled/"
echo "   sudo ln -sf /etc/nginx/sites-available/${MINIO_DNS}.conf /etc/nginx/sites-enabled/"
echo "   sudo nginx -t && sudo systemctl reload nginx"
