# Сеть

Согласуйте доступы до `docker compose up`. Имена хостов ниже — роли из [установки на нескольких серверах](03-multi-node.md). На одном сервере те же порты слушаются локально; с интернета оставьте только 80/tcp и 443/tcp.

## Матрица для нескольких серверов

| Source | Destination | Port / Protocol | Purpose | Required |
|--------|-------------|-----------------|---------|----------|
| Пользователи | Nginx | 443/tcp | HTTPS и WebSocket | Required |
| Пользователи | Nginx | 80/tcp | Редирект на HTTPS, HTTP-01 | Required, если выпуск сертификата идёт через HTTP-01 |
| Nginx | AppServer | 8080/tcp | Прокси приложения | Required |
| Nginx | Knowledgebase | 8880/tcp | DocumentServer | Required |
| Nginx | Knowledgebase | 8443/tcp | HTTPS DocumentServer внутри контура | Optional |
| Nginx | MinIO | 9000/tcp | S3 API | Required |
| AppServer | MongoDB | 27017/tcp | Данные чата | Required |
| AppServer | Tasker | 8881/tcp | База знаний / задачи | Required |
| Vault | MongoDB | 27017/tcp | Хранилище Vault | Required |
| Tasker | MongoDB | 27017/tcp | Данные Tasker | Required |
| Tasker | Vault | 8200/tcp | Секрет `KBTConfigs` | Required |
| Tasker | MinIO | 9000/tcp | Файлы | Required |
| Tasker | Logger | 8082/tcp | Журнал | Required |
| Vault | Logger | 8082/tcp | Журнал | Required |
| Knowledgebase | MinIO | 9000/tcp | Документы | Required |
| Администратор | MinIO | 9002/tcp | Консоль MinIO | Optional |
| Любая роль | `cr.yandex` | 443/tcp | Загрузка образов | Required |
| AppServer | `push1.unic.chat` | 443/tcp | Лицензия и push | Required |
| Nginx | Let's Encrypt | 80/tcp и 443/tcp | Выпуск сертификата | Required только для Let's Encrypt |
| AppServer | LDAP | 389/tcp или 636/tcp | Каталог пользователей | Optional |
| AppServer | SMTP | 25, 465 или 587/tcp | Почта | Optional |

PostgreSQL и RabbitMQ DocumentServer наружу не публикуйте: они остаются на хосте Knowledgebase.

С интернета не должны быть доступны 8080, 8880, 8881, 9000, 9002, 27017, 8200, 8082 и порты PostgreSQL/RabbitMQ.

## Один сервер: что открыть снаружи

```shell
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

Порт 9002 открывайте только администратору консоли MinIO.

Порты локального ВКС на этот хост не вешайте. Медиасервер — отдельная машина, список портов в [локальном ВКС](12-vcs-local.md).

## Исходящие с UnicChat

| Куда | Порт | Зачем |
|------|------|--------|
| `push1.unic.chat` | 443/tcp | Лицензия и push |
| `lk-yc.unic.chat` | 443/tcp, 7881/tcp, 7882/udp, 50000–60000/udp | Только если выбран [внешний ВКС](11-vcs-external.md) |
| DNS | 53/tcp и 53/udp | Разрешение имён |

Если вы ставите локальный медиасервер, исходящие на `lk-yc.unic.chat` не нужны. Клиенты ходят на ваши имена LiveKit и TURN.
