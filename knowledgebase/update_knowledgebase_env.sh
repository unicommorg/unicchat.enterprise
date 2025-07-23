#!/bin/bash

# Директория, где находятся файлы .env
BASE_DIR="knowledgebase"

# Загрузка переменных из knowledgebase.env
ENV_FILE="$BASE_DIR/knowledgebase.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Ошибка: Файл $ENV_FILE не найден"
    exit 1
fi

source "$ENV_FILE"

# Функция для экранирования специальных символов для sed
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Массив файлов и переменных для замены
declare -A FILES=(
    ["minio/minio_env.env"]="MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD"
    ["Docker-DocumentServer/onlyoffice_env.env"]="DB_TYPE=$DB_TYPE
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
WOPI_ENABLED=$WOPI_ENABLED
AMQP_URI=$AMQP_URI
JWT_ENABLED=$JWT_ENABLED
ALLOW_PRIVATE_IP_ADDRESS=$ALLOW_PRIVATE_IP_ADDRESS
ALLOW_META_IP_ADDRESS=$ALLOW_META_IP_ADDRESS
USE_UNAUTHORIZED_STORAGE=$USE_UNAUTHORIZED_STORAGE"
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
