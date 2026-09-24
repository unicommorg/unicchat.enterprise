# Резервное копирование и восстановление

Снимайте копию до обновления и после первой успешной установки. Храните копию вне сервера установки.

Каталог команд ниже — `multi-server-install/`. На нескольких серверах выполняйте команду на хосте той роли, где лежит том.

## Что копировать

| Объект | Где | Зачем |
|--------|-----|--------|
| `.env` | каждый хост роли | пароли и адреса |
| `certs/` | хост Nginx | TLS |
| `nginx/templates/` и ваш хостовый nginx | хост Nginx | правила прокси |
| Том `mongodb_data` | MongoDB | чаты и пользователи |
| Том `postgresql_data` | Knowledgebase | DocumentServer |
| Том `logger_postgres_data` | Logger | журнал |
| Том `minio_data` | MinIO | файлы |
| Том `vault-data` | Vault | секреты, включая `KBTConfigs` |

Тома приложения (`chat_data`, кэш DocumentServer) восстанавливайте вместе с остальным контуром, если откатываете всю площадку.

## MongoDB

На хосте MongoDB, контейнер `unicchat-mongodb`:

```shell
docker exec unicchat-mongodb mongodump \
  --username root \
  --password "$MONGODB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --archive=/tmp/unicchat.archive --gzip
docker cp unicchat-mongodb:/tmp/unicchat.archive ./unicchat.archive
```

Пользователь дампа — root из переменной окружения контейнера (`MONGODB_ROOT_PASSWORD` в `.env`). Имя пользователя root у образа Bitnami по умолчанию `root`.

Восстановление на остановленном приложении (AppServer и Tasker остановлены):

```shell
docker cp ./unicchat.archive unicchat-mongodb:/tmp/unicchat.archive
docker exec unicchat-mongodb mongorestore \
  --username root \
  --password "$MONGODB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --archive=/tmp/unicchat.archive --gzip --drop
```

`--drop` заменяет коллекции данными из архива. Запускайте его только на той базе, которую восстанавливаете.

## PostgreSQL

DocumentServer:

```shell
docker exec unicchat-postgresql pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc -f /tmp/ds.dump
docker cp unicchat-postgresql:/tmp/ds.dump ./ds.dump
```

Logger:

```shell
docker exec unicchat-logger-postgres pg_dump -U "$LOGGER_DB_USER" -d "$LOGGER_DB" -Fc -f /tmp/logger.dump
docker cp unicchat-logger-postgres:/tmp/logger.dump ./logger.dump
```

Восстановление: остановите DocumentServer или Logger, затем `pg_restore` в ту же базу. Пароль возьмите из `.env` той же площадки.

## MinIO

На хосте MinIO, после `mc alias`:

```shell
docker run --rm --network unicchat-network \
  -v "$(pwd)/minio-backup:/backup" \
  --entrypoint /bin/sh \
  "${IMAGE_MINIO_MC}" \
  -c "mc alias set local http://unicchat-minio:9000 \"${MINIO_ROOT_USER}\" \"${MINIO_ROOT_PASSWORD}\" && mc mirror local/${MINIO_BUCKET} /backup/${MINIO_BUCKET} && mc mirror local/${MINIO_DOCS_BUCKET} /backup/${MINIO_DOCS_BUCKET}"
```

На нескольких серверах подставьте адрес `KBT_MINIO_HOST` вместо `unicchat-minio:9000`. Обратный `mc mirror` из `/backup` возвращает бакеты.

## Vault, `.env`, nginx, сертификаты

```shell
tar -C /var/lib/docker/volumes -czf vault-data.tgz <имя_тома_vault-data>
cp -a .env .env.backup.$(date +%F)
tar -czf certs.tgz certs
tar -czf nginx-templates.tgz nginx/templates nginx/examples
```

Имя тома Docker смотрите через `docker volume ls | grep vault`. Не копируйте `vault-data` с работающего Vault в момент записи: остановите `unicchat-vault` на время архива тома либо используйте снимок диска гипервизора.

## Порядок полного восстановления

1. Поднимите чистые хосты с теми же версиями образов, что в копии `.env`.
2. Верните `.env`, `certs/` и шаблоны nginx.
3. Восстановите MongoDB, обе базы PostgreSQL, MinIO, затем том Vault.
4. Запустите роли в порядке из [нескольких серверов](03-multi-node.md) или один `docker compose up -d` .
5. Пройдите [критерии успеха](07-validation.md).

Если восстановили только MongoDB, а Vault и MinIO остались старыми, адреса в `KBTConfigs` должны совпадать с живыми сервисами. Иначе Tasker не найдёт файлы.
