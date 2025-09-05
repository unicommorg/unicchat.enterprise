#!/bin/bash
# apply_nginx_configs.sh

DNS_CONFIG="dns_config.txt"

if [ ! -f "$DNS_CONFIG" ]; then
    echo "❌ Файл конфигурации $DNS_CONFIG не найден"
    echo "   Сначала запустите generate_nginx_conf.sh"
    exit 1
fi

source "$DNS_CONFIG"

echo "🔧 Применение Nginx конфигов..."
echo "📊 Будет применено:"
echo "   - ${APP_DNS}.conf"
echo "   - ${EDT_DNS}.conf" 
echo "   - ${MINIO_DNS}.conf"
echo ""

# Копируем все конфиги
sudo cp *.conf /etc/nginx/sites-available/

# Создаем симлинки
sudo ln -sf "/etc/nginx/sites-available/${APP_DNS}.conf" "/etc/nginx/sites-enabled/"
sudo ln -sf "/etc/nginx/sites-available/${EDT_DNS}.conf" "/etc/nginx/sites-enabled/"
sudo ln -sf "/etc/nginx/sites-available/${MINIO_DNS}.conf" "/etc/nginx/sites-enabled/"

# Удаляем дефолтный конфиг если есть
sudo rm -f /etc/nginx/sites-enabled/default

# Проверяем конфигурацию
echo "🔍 Проверка конфигурации Nginx..."
if sudo nginx -t; then
    echo "✅ Конфигурация верна, перезагружаем Nginx..."
    sudo systemctl reload nginx
    echo "🎉 Nginx успешно перезагружен!"
else
    echo "❌ Ошибка в конфигурации Nginx"
    exit 1
fi

echo ""
echo "📋 Активные сайты:"
ls -la /etc/nginx/sites-enabled/
