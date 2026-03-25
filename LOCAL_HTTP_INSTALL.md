# Локальная установка UnicChat Enterprise по HTTP (без HTTPS / nginx)

Этот документ фиксирует **то, что мы меняли**, чтобы поднять стенд **локально и только по HTTP**. Основной инсталлятор/README не переписываем.

## Предпосылки

- Сначала выполните **штатную установку по скрипту** из основного README (чтобы он сгенерировал `.env`/секреты/volume/network), а уже потом применяйте шаги ниже.
- У вас уже есть рабочая папка проекта и вы поднимаете сервисы через `docker compose`.
- Порты по умолчанию из `multi-server-install/docker-compose.yml`:
  - AppServer: `8080 -> 3000`
  - Tasker: `8881 -> 8080`
  - MinIO: `9000` (S3 API) и `9002` (console)
  - DocumentServer: `8880 -> 80` (HTTP) и (может присутствовать) `8443 -> 443`
  - Vault: `8200 -> 80`

## Что именно делаем

0. Сначала запускаем установку по скрипту (из основного README)
1. Правим/создаём env-файлы для HTTP
2. Удаляем и создаём заново секрет `KBTConfigs` в Vault (MinIO строго HTTP)
3. Удаляем базу `unicchat_db` в MongoDB от root
4. Перезапускаем `docker compose up -d`
5. Проверяем, что Tasker/DocumentServer/MinIO видят друг друга по HTTP

---

## 1) AppServer: `ROOT_URL` и `DOCUMENT_SERVER_HOST` только по HTTP

### Где править

Файл берётся из `multi-server-install/docker-compose.yml`:

- `multi-server-install/appserver.env`

Если файла нет в репозитории (часто он генерируется инсталлятором) — **создайте его** по этому пути.

### Что поставить

Минимально важные строки:

```ini
ROOT_URL=http://<HOST_IP>:8080
DOCUMENT_SERVER_HOST=http://<HOST_IP>:8880
UNIC_SOLID_HOST=http://unicchat-tasker:8080
```

- `<HOST_IP>`: IP хоста, на котором открываете веб (не docker bridge). Обычно это LAN-IP сервера/VM.

### Откуда брать значения

- `HOST_IP`: `hostname -I` (или ваш известный адрес), затем подставить в `ROOT_URL` и `DOCUMENT_SERVER_HOST`.
- Порты: см. `multi-server-install/docker-compose.yml`.

---

## 2) DocumentServer: разрешить private/meta IP и отключить JWT (для локального стенда)

### Почему это нужно

При попытке открыть/создать документ DocumentServer скачивает файл из MinIO по presigned URL. В docker-сети имя `unicchat-minio` резолвится в приватный IP (например, `172.18.x.x`), и DocumentServer по умолчанию **может блокировать** такие адреса. Это проявлялось как:

- “загрузка не удалась”
- в логах DocumentServer: `DNS lookup ... is not allowed. Because, It is private IP address.`

### Где править

Файл подключён в compose как:

- `multi-server-install/env/documentserver_env.env`

Если папки/файла нет — **создайте** `multi-server-install/env/` и сам файл.

### Что поставить

```ini
JWT_ENABLED=false

ALLOW_PRIVATE_IP_ADDRESS=true
ALLOW_META_IP_ADDRESS=true
```


### Откуда брать значения

- Нужные ключи/значения выше фиксированы для локального стенда.
- Базовые переменные (DB/AMQP) — из вашего текущего `documentserver_env.env`, если он уже был сгенерирован.

---

## 3) Vault: пересоздать секрет `KBTConfigs` (Mongo + MinIO по HTTP)

Tasker берёт параметры подключения к Mongo и MinIO из секрета Vault с именем `KBTConfigs`.

### 3.0. Как понять внешний и внутренний адрес Vault

- Внешний адрес (с хоста/браузера): `http://<HOST_IP>:8200`
- Внутренний адрес (из контейнеров в docker-сети): `http://unicchat-vault:80`

Проверить, что имя резолвится внутри сети:

```bash
docker exec -it unicchat-tasker sh -lc 'getent hosts unicchat-vault || true'
```

### 3.1. Откуда взять `VAULT_URL` и `TOKEN`

- `VAULT_URL`: **внешний** адрес Vault на хосте (по compose это `http://<HOST_IP>:8200`)
- `TOKEN`: root/admin token Vault (**в документе не храним и не коммитим**)

Источники:

- Если у вас есть файл `vault_creds.env` (часто генерируется инсталлятором) — берите оттуда (локально).
- Иначе смотрите переменные контейнера Vault (локально):

```bash
docker inspect unicchat-vault --format '{{range .Config.Env}}{{println .}}{{end}}' | sed -n 's/^VAULT_.*//p'
```

Если в образе токен/ключи иначе называются — используйте тот способ, которым вы ранее входили в Vault для создания секретов.

Пример (не настоящий токен), как должны выглядеть переменные в shell:

```bash
export VAULT_URL="http://<HOST_IP>:8200"
export TOKEN="<PASTE_VAULT_ROOT_TOKEN_HERE>"
```

### 3.2. Удалить старый `KBTConfigs`

```bash
curl -sS -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "$VAULT_URL/api/secrets/KBTConfigs"
```

### 3.3. Создать новый `KBTConfigs` (HTTP для MinIO)

Важно:

- `MinioHost` **без схемы**, в формате `host:port`
- `MinioSecure` — **строкой** `"false"` (Vault API ожидает string)

```bash
curl -sS -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "$VAULT_URL/api/secrets" \
  -d '{
    "id": "KBTConfigs",
    "name": "KBTConfigs",
    "type": "Password",
    "data": "All info in META",
    "metadata": {
      "MongoCS": "mongodb://<user>:<pass>@unicchat-mongodb:27017/<db>?directConnection=true&authSource=<db>&authMechanism=SCRAM-SHA-256",
      "MinioHost": "unicchat-minio:9000",
      "MinioUser": "<MINIO_ROOT_USER>",
      "MinioPass": "<MINIO_ROOT_PASSWORD>",
      "MinioSecure": "false"
    },
    "tags": ["KB", "Tasker", "Mongo", "Minio"],
    "expiresAt": "2030-12-31T23:59:59.999Z"
  }'
```

### Откуда брать значения (credentials)

- `MongoCS`:
  - Если у вас есть `logger_creds.env` / `appserver_creds.env` / `mongo_creds.env` (генерируемые файлы) — берите логин/пароль оттуда.
  - Иначе посмотрите переменные контейнеров:

```bash
docker inspect unicchat-logger --format '{{range .Config.Env}}{{println .}}{{end}}'
docker inspect unicchat-appserver --format '{{range .Config.Env}}{{println .}}{{end}}'
docker inspect unicchat-mongodb --format '{{range .Config.Env}}{{println .}}{{end}}'
```

- `MinioUser` / `MinioPass`:
  - Если есть `multi-server-install/env/minio_env.env` (или иной env MinIO) — берите из него.
  - Иначе:

```bash
docker inspect unicchat-minio --format '{{range .Config.Env}}{{println .}}{{end}}'
```

---

## 4) MongoDB: удалить `unicchat_db` от root

### Откуда взять root-credentials

- Если есть `mongo_creds.env` (генерируемый файл) — используйте `MONGODB_ROOT_PASSWORD`.
- Иначе смотрите переменные `unicchat-mongodb`:

```bash
docker inspect unicchat-mongodb --format '{{range .Config.Env}}{{println .}}{{end}}'
```

### Команда удаления базы

```bash
docker exec -it unicchat-mongodb mongosh \
  -u "root" -p "<MONGODB_ROOT_PASSWORD>" \
  --authenticationDatabase "admin" \
  --eval 'db.getSiblingDB("unicchat_db").dropDatabase()'
```

---

## 5) Перезапуск сервисов

Запускать из папки `multi-server-install/`:

```bash
cd multi-server-install
docker compose up -d
```

---

## 6) Быстрые проверки (ожидаемые результаты)

### 6.0. Как найти “внутренние адреса” сервисов (container-to-container)

Внутри docker-сети сервисы ходят друг к другу по схеме:

- `http://<container_name>:<container_port>`

Примеры (из `multi-server-install/docker-compose.yml`):

- Vault: `http://unicchat-vault:80`
- MinIO (S3): `http://unicchat-minio:9000`
- Logger: `http://unicchat-logger:8080`
- Tasker: `http://unicchat-tasker:8080`
- MongoDB: `mongodb://unicchat-mongodb:27017`

Как узнать IP конкретного контейнера (обычно не нужно, но полезно для диагностики):

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' unicchat-minio
```

### 6.1. Контейнеры подняты

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Ожидаемо: `unicchat-appserver`, `unicchat-vault`, `unicchat-mongodb`, `unicchat-minio`, `unicchat-tasker`, `unicchat-documentserver` в статусе `Up`.

### 6.2. Проверка секрета `KBTConfigs`

```bash
curl -sS \
  -H "Authorization: Bearer $TOKEN" \
  "$VAULT_URL/api/secrets/KBTConfigs" | head -c 4000 ; echo
```

Ожидаемо в `metadata`:

- `"MinioHost":"unicchat-minio:9000"`
- `"MinioSecure":"false"`

### 6.3. Проверка наличия/удаления базы

```bash
docker exec -it unicchat-mongodb mongosh \
  -u "root" -p "<MONGODB_ROOT_PASSWORD>" \
  --authenticationDatabase "admin" \
  --eval 'show dbs'
```

Ожидаемо: `unicchat_db` отсутствует (или появился заново только после запуска/инициализации приложения).

---

## Важно (scope)

- Этот документ **не включает** настройку `nginx`, TLS/SSL, домены, сертификаты.
- Для локального стенда мы фиксируем **HTTP-only** и правки, которые понадобились для MinIO/DocumentServer внутри docker-сети.


