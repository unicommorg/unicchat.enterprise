#!/bin/bash

# Директория, где находятся файлы .env
BASE_DIR="multi_server_install"

# Определите новые значения для переменных окружения здесь
# Замените эти значения-заполнители на ваши реальные значения
NEW_UNIC_SOLID_HOST="http://new.unic.chat.solid:8881"
NEW_ONLYOFFICE_HOST="https://new.dns.name.onlyoffice"
NEW_MONGODB_USERNAME="new_unicchat_admin"
NEW_MONGODB_PASSWORD="new_secure_password_456"
NEW_MONGODB_DATABASE="new_unicchat_db"
NEW_MINIO_IP_OR_HOST="new.minio.dns.name"
NEW_MINIO_ROOT_USER="new_minioadmin"
NEW_MINIO_ROOT_PASSWORD="new_minio_password_789"
NEW_MONGODB_ROOT_PASSWORD="new_mongodb_root_password"
NEW_MONGODB_INITIAL_PRIMARY_HOST="new_mongodb_host"
NEW_MONGODB_ADVERTISED_HOSTNAME="new_mongodb_advertised_host"
NEW_UNIC_LICENSE="new_license_code"

# Динамическое построение MONGO_URL и MONGO_OPLOG_URL
NEW_MONGO_URL="mongodb://${NEW_MONGODB_USERNAME}:${NEW_MONGODB_PASSWORD}@${NEW_MONGODB_INITIAL_PRIMARY_HOST}:27017/${NEW_MONGODB_DATABASE}?replicaSet=rs0"
NEW_MONGO_OPLOG_URL="mongodb://${NEW_MONGODB_USERNAME}:${NEW_MONGODB_PASSWORD}@${NEW_MONGODB_INITIAL_PRIMARY_HOST}:27017/local"

# Функция для экранирования специальных символов для sed
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Массив файлов и переменных для замены
declare -A FILES=(
    ["appserver_env.env"]="UNIC_SOLID_HOST=$NEW_UNIC_SOLID_HOST
ONLYOFFICE_HOST=$NEW_ONLYOFFICE_HOST"
    ["common_env.env"]="MONGODB_USERNAME=$NEW_MONGODB_USERNAME
MONGODB_PASSWORD=$NEW_MONGODB_PASSWORD
MONGODB_DATABASE=$NEW_MONGODB_DATABASE
MONGO_URL=$NEW_MONGO_URL
MONGO_OPLOG_URL=$NEW_MONGO_OPLOG_URL
MINIO_IP_OR_HOST=$NEW_MINIO_IP_OR_HOST
MINIO_ROOT_USER=$NEW_MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$NEW_MINIO_ROOT_PASSWORD"
    ["mongodb_env.env"]="MONGODB_ROOT_PASSWORD=$NEW_MONGODB_ROOT_PASSWORD
MONGODB_INITIAL_PRIMARY_HOST=$NEW_MONGODB_INITIAL_PRIMARY_HOST
MONGODB_ADVERTISED_HOSTNAME=$NEW_MONGODB_ADVERTISED_HOSTNAME"
    ["app/solid_env.env"]="UnicLicense=$NEW_UNIC_LICENSE"
)

# Проверка существования базовой директории
if [ ! -d "$BASE_DIR" ]; then
    echo "Ошибка: Директория $BASE_DIR не существует"
    exit 1
fi

# Обработка каждого файла
for file in "${!FILES[@]}"; do
    file_path="$BASE_DIR/$file"
    
    # Проверка существования файла
    if [ ! -f "$file_path" ]; then
        echo "Ошибка: Файл $file_path не найден"
        continue
    fi

    # Чтение замен для этого файла
    IFS=$'\n' read -d '' -r -a replacements <<< "${FILES[$file]}"

    # Обработка каждой замены
    for replacement in "${replacements[@]}"; do
        # Разделение замены на ключ и значение
        key="${replacement%%=*}"
        value="${replacement#*=}"
        
        # Экранирование специальных символов для sed
        escaped_value=$(escape_sed "$value")
        
        # Замена всей строки для ключа
        if grep -q "^$key=" "$file_path"; then
            sed -i "s|^$key=.*|$key=$escaped_value|" "$file_path"
            echo "Обновлен $key в $file_path"
        else
            echo "Предупреждение: $key не найден в $file_path"
        fi
    done
done

echo "Замена завершена"
