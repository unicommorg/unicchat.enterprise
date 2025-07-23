#!/bin/bash

# Директория, где находятся файлы .env
BASE_DIR=$PWD

# Загрузка переменных из multi_server_env.env
ENV_FILE="$BASE_DIR/multi_server_env.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Ошибка: Файл $ENV_FILE не найден"
    exit 1
fi

source "$ENV_FILE"

# Динамическое построение MONGO_URL и MONGO_OPLOG_URL
MONGO_URL="mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@${MONGODB_INITIAL_PRIMARY_HOST}:27017/${MONGODB_DATABASE}?replicaSet=rs0"
MONGO_OPLOG_URL="mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@${MONGODB_INITIAL_PRIMARY_HOST}:27017/local"

# Функция для экранирования специальных символов для sed
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Массив файлов и переменных для замены
declare -A FILES=(
    ["appserver_env.env"]="UNIC_SOLID_HOST=$UNIC_SOLID_HOST
ONLYOFFICE_HOST=$ONLYOFFICE_HOST"
    ["common_env.env"]="MONGODB_USERNAME=$MONGODB_USERNAME
MONGODB_PASSWORD=$MONGODB_PASSWORD
MONGODB_DATABASE=$MONGODB_DATABASE
MONGO_URL=$MONGO_URL
MONGO_OPLOG_URL=$MONGO_OPLOG_URL
MINIO_IP_OR_HOST=$MINIO_IP_OR_HOST
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD"
    ["mongodb_env.env"]="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD
MONGODB_INITIAL_PRIMARY_HOST=$MONGODB_INITIAL_PRIMARY_HOST
MONGODB_ADVERTISED_HOSTNAME=$MONGODB_ADVERTISED_HOSTNAME"
    ["app/solid_env.env"]="UnicLicense=$UNIC_LICENSE"
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
