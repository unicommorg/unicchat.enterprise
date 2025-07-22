#!/bin/bash

# Директория, где находятся файлы .env
BASE_DIR="knowledgebase"

# Определите новые значения для переменных окружения здесь
# Замените эти значения-заполнители на ваши реальные значения
NEW_MINIO_ROOT_USER="new_minioadmin"
NEW_MINIO_ROOT_PASSWORD="new_minio_password_789"
NEW_DB_TYPE="postgres"
NEW_DB_HOST="new_onlyoffice_postgresql"
NEW_DB_PORT="5432"
NEW_DB_NAME="new_dbname"
NEW_DB_USER="new_dbuser"
NEW_WOPI_ENABLED="true"
NEW_AMQP_URI="amqp://new_guest:new_guest@new_onlyoffice_rabbitmq"
NEW_JWT_ENABLED="false"
NEW_ALLOW_PRIVATE_IP_ADDRESS="true"
NEW_ALLOW_META_IP_ADDRESS="true"
NEW_USE_UNAUTHORIZED_STORAGE="true"

# Функция для экранирования специальных символов для sed
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Массив файлов и переменных для замены
declare -A FILES=(
    ["minio/minio_env.env"]="MINIO_ROOT_USER=$NEW_MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$NEW_MINIO_ROOT_PASSWORD"
    ["Docker-DocumentServer/onlyoffice_env.env"]="DB_TYPE=$NEW_DB_TYPE
DB_HOST=$NEW_DB_HOST
DB_PORT=$NEW_DB_PORT
DB_NAME=$NEW_DB_NAME
DB_USER=$NEW_DB_USER
WOPI_ENABLED=$NEW_WOPI_ENABLED
AMQP_URI=$NEW_AMQP_URI
JWT_ENABLED=$NEW_JWT_ENABLED
ALLOW_PRIVATE_IP_ADDRESS=$NEW_ALLOW_PRIVATE_IP_ADDRESS
ALLOW_META_IP_ADDRESS=$NEW_ALLOW_META_IP_ADDRESS
USE_UNAUTHORIZED_STORAGE=$NEW_USE_UNAUTHORIZED_STORAGE"
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
