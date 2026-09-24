# Секреты

Пароли задаёте вы. Значения `change_me_*` и ключ реплики `rs0key` из примера в работу не берите.

## Что задаёт администратор

| Переменная | Назначение | После первого запуска |
|------------|------------|------------------------|
| `MONGODB_ROOT_PASSWORD` | root MongoDB | Смена в `.env` пароль в БД не обновляет |
| `MONGODB_PASSWORD` | пользователь приложения | То же |
| `MONGODB_REPLICA_SET_KEY` | ключ replica set | Не меняйте без процедуры пересоздания реплики |
| `VAULT_DB_PASSWORD` | БД Vault | Не меняйте в одиночку |
| `LOGGER_DB_PASSWORD` | БД Logger | Не меняйте в одиночку |
| `TASKER_DB_PASSWORD` | БД Tasker | Попадает в секрет Vault |
| `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | S3 | Попадают в секрет Vault |

Имена служебных пользователей тоже лучше задать свои.

Пароли попадают в URI MongoDB без URL-кодирования. Используйте только `[A-Za-z0-9_-]`.

```shell
gen() { openssl rand -base64 32 | tr -d '/+=' | cut -c1-24; }
echo "MONGODB_ROOT_PASSWORD=$(gen)"
echo "MONGODB_PASSWORD=$(gen)"
echo "VAULT_DB_PASSWORD=$(gen)"
echo "LOGGER_DB_PASSWORD=$(gen)"
echo "TASKER_DB_PASSWORD=$(gen)"
echo "MINIO_ROOT_PASSWORD=$(gen)"
echo "MONGODB_REPLICA_SET_KEY=$(gen)"
```

Разные площадки — разные пароли. Одинаковый пароль на все роли не используйте.

## Что создаётся само

При первом `up` init-контейнеры создают пользователей MongoDB и PostgreSQL, бакеты MinIO и секрет Vault `KBTConfigs`. Повторный запуск эти объекты не перезаписывает.

## Где лежат секреты

| Что | Где |
|-----|-----|
| Пароли установки | файл `multi-server-install/.env` на каждом хосте роли |
| Данные MongoDB, Vault, MinIO, PostgreSQL | тома Docker (`mongodb_data`, `vault-data`, `minio_data`, `postgresql_data`, `logger_postgres_data`) |
| Секрет Tasker | Vault, путь `KBTConfigs` |
| TLS | каталог `certs/` (в git не коммитьте) |

`.env` и `certs/` включите в резервную копию. В git их не кладите. См. [резервное копирование](08-backup-restore.md).

## Вход в реестр образов

```shell
docker login --username oauth \
  --password-stdin \
  cr.yandex <<< "y0__wgBEPrL67wHGMHdEyD7rJmMGCeDEOXSuqJalbFdb2Dgucs0mlmU"
```

Токен нужен, чтобы скачать образы. Не копируйте его в заявки и переписку сверх этой инструкции поставки.

## Секрет Vault KBTConfigs

Tasker читает адреса MongoDB и MinIO из секрета `KBTConfigs`. При первом запуске `vault-init` записывает его из `.env`:

| В секрете | Откуда |
|-----------|--------|
| строка MongoDB | `KBT_MONGO_HOST`, `TASKER_DB_*` |
| адрес MinIO | `KBT_MINIO_HOST` |
| доступ MinIO | `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` |

На одном сервере:

```
KBT_MONGO_HOST=unicchat-mongodb
KBT_MINIO_HOST=unicchat-minio:9000
```

На нескольких серверах подставьте IP и порт хоста. MongoDB и MinIO должны отвечать до Vault. `vault-init` проверяет их 10 раз с паузой 5 секунд. Если адрес недоступен, секрет не создаётся:

```
MongoDB or MinIO is not reachable from vault-init. KBTConfigs secret NOT created.
```

Исправьте адреса и запустите снова:

```shell
docker compose -f compose.vault.yml up --force-recreate vault-init
```

Ожидаемый лог: `KBTConfigs secret created.` и `Secret matches .env`.

Готовый секрет автоматически не перезаписывается. Если `.env` разошёлся с Vault, в логе будет предупреждение. Tasker продолжит ходить по адресам из Vault.

Посмотреть секрет (на сервере Vault, в сети `unicchat-network`):

```shell
TOKEN=$(docker run --rm --network unicchat-network curlimages/curl:8.8.0 \
  -fsS "http://unicchat-vault/api/token/0f8e160416b94225a73f86ac23b9118b?username=KBTservice")

docker run --rm --network unicchat-network curlimages/curl:8.8.0 \
  -sS -H "Authorization: Bearer ${TOKEN}" \
  "http://unicchat-vault/api/Secrets/KBTConfigs"
```

Адреса лежат в `metadata`. Запрос без суффикса `/data`. В ответе есть пароли — вывод не пересылайте.

Пересоздать секрет после смены `KBT_*`:

```shell
set -a && . ./.env && set +a
TOKEN=$(docker run --rm --network unicchat-network curlimages/curl:8.8.0 \
  -fsS "http://unicchat-vault/api/token/0f8e160416b94225a73f86ac23b9118b?username=KBTservice")

docker run --rm --network unicchat-network curlimages/curl:8.8.0 \
  -sS -X DELETE -H "Authorization: Bearer ${TOKEN}" \
  "http://unicchat-vault/api/Secrets/KBTConfigs"

docker compose -f compose.vault.yml up --force-recreate vault-init
```

Затем перезапустите Tasker.

Ротация паролей БД после первого запуска — отдельная процедура: смена в СУБД, затем в `.env`, затем пересоздание `KBTConfigs`, если пароль входит в секрет. Одной правки `.env` недостаточно.
