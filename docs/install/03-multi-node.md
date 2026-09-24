# Установка на нескольких серверах

Эта схема — промышленная. Роли разнесены по хостам. Один `.env` копируете на все серверы: пароли и `IMAGE_*` одинаковые, адреса соседей — IP и порт на хосте.

Оценка времени: от половины дня, если firewall и DNS уже согласованы.

## Состав

| Сервер | Файл | Сервисы |
|--------|------|---------|
| MongoDB | `compose.mongodb.yml` | `unicchat-mongodb`, `vault-mongo-init` |
| Vault | `compose.vault.yml` | `unicchat-vault`, `vault-init` |
| Logger | `compose.logger.yml` | `unicchat-logger` |
| MinIO | `compose.minio.yml` | `unicchat-minio`, `minio-init` |
| Tasker | `compose.tasker.yml` | `unicchat-tasker` |
| Knowledgebase | `compose.knowledgebase.yml` | `unicchat-documentserver`, `unicchat-postgresql`, `unicchat-rabbitmq` |
| AppServer | `compose.appserver.yml` | `unicchat-appserver` |
| Nginx | `compose.nginx.yml` | `unicchat-nginx`, `nginx-config-init` |

Пример адресации (подставьте свою):

| Роль | IP |
|------|-----|
| MongoDB | `10.0.10.11` |
| Vault | `10.0.10.12` |
| Logger | `10.0.10.13` |
| MinIO | `10.0.10.14` |
| Tasker | `10.0.10.15` |
| Knowledgebase | `10.0.10.16` |
| AppServer | `10.0.10.17` |
| Nginx | `10.0.10.18` |

Порты между серверами — в [сети](04-network.md). Откройте их до запуска.

## Подготовка каждого хоста

1. Docker и вход в реестр — как в [установке на одном сервере](02-single-node.md), шаги 1–3.
2. Скопируйте каталог `multi-server-install/` и один и тот же `.env`.
3. Замените имена контейнеров на IP соседа:

| Переменная | Один сервер | Несколько серверов |
|------------|-------------|--------------------|
| `MONGODB_HOST` | `unicchat-mongodb` | IP MongoDB |
| `MONGODB_ADVERTISED_HOSTNAME` | `unicchat-mongodb` | IP MongoDB |
| `API_VAULT_URL` | `http://unicchat-vault/` | `http://<vault>:8200/` |
| `API_LOGGER_URL` | `http://unicchat-logger:8080/` | `http://<logger>:8082/` |
| `UNIC_SOLID_HOST` | `http://unicchat-tasker:8080` | `http://<tasker>:8881` |
| `KBT_MONGO_HOST` | `unicchat-mongodb` | IP MongoDB |
| `KBT_MINIO_HOST` | `unicchat-minio:9000` | `<minio>:9000` |
| `MINIO_HOST` | `unicchat-minio` | IP MinIO |
| `DOCUMENT_SERVER_PROXY` | `unicchat-documentserver` | `<kb>:8880` |
| `UNICCHAT_HOST` | `unicchat-appserver` | IP AppServer |
| `NGINX_APP_PORT` | не задавать | `8080` |
| `ROOT_URL` | `https://<APP_SERVER_NAME>` | то же |

`DB_HOST` и `AMQP_URI` не меняйте: PostgreSQL и RabbitMQ живут на сервере Knowledgebase.

`KBT_MONGO_HOST` и `KBT_MINIO_HOST` попадают в секрет Vault. Задайте их до первого `vault-init`. Подробности — в [секретах](06-secrets.md).

На каждом хосте:

```shell
./validate-env.sh
```

## Что должно быть заполнено на роли

| Роль | Переменные |
|------|------------|
| MongoDB | `MONGODB_*` |
| Vault | `VAULT_DB_*`, `MONGODB_HOST`, `API_LOGGER_URL` |
| Logger | `LOGGER_DB_*`, `API_LOGGER_URL` |
| MinIO | `MINIO_ROOT_*`, бакеты |
| Tasker | `API_VAULT_URL`, `API_LOGGER_URL`, `TASKER_DB_*` |
| Knowledgebase | `DB_*`, `AMQP_URI`, `JWT_*` |
| AppServer | `MONGODB_*`, `UNIC_SOLID_HOST`, `ROOT_URL`, `LICENSE_HOST` |
| Nginx | домены, `UNICCHAT_HOST`, `NGINX_APP_PORT`, `DOCUMENT_SERVER_PROXY`, `MINIO_HOST`, пути сертификатов |

## Порядок запуска

На каждом сервере только свой файл:

```shell
docker compose -f compose.<роль>.yml pull
docker compose -f compose.<роль>.yml up -d
```

1. **MongoDB** — дождитесь healthy. В логах `vault-mongo-init` пользователи созданы.
2. **Logger**.
3. **MinIO** — дождитесь `minio-init`.
4. **Vault** — только когда MongoDB и MinIO отвечают. В логах: `KBTConfigs secret created.`
5. **Tasker**.
6. **Knowledgebase**.
7. **AppServer**.
8. **Nginx** — сначала сертификаты по [TLS](05-tls.md), затем `compose.nginx.yml`.

Проверка — [критерии успеха](07-validation.md). Если роль не стартует, смотрите [диагностику](10-troubleshooting.md).
