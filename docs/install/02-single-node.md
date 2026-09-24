# Установка на одном сервере

Эта схема — демонстрация, тест или малый контур. Для промышленной эксплуатации используйте [несколько серверов](03-multi-node.md).

Каталог `multi-server-install/`, файл `docker-compose.yml`, один `.env`. Пользователи БД, секрет Vault `KBTConfigs` и бакеты MinIO создаются init-контейнерами при первом запуске.

Оценка времени: 1–2 часа, если DNS и лицензия уже готовы.

## Что подготовить

1. Выполните [требования](01-requirements.md) и [чек-лист до запуска](07-validation.md).
2. Выдайте права:

| Кому | Зачем |
|------|--------|
| Пользователь в группе `sudo` | Docker, firewall |
| Тот же пользователь в группе `docker` | `docker compose` без sudo. После `sudo usermod -aG docker $USER` перелогиньтесь |
| Запись в каталог установки | `.env`, `certs/`, `nginx/conf.d/` |

## 1. Установите Docker

Поставьте Docker Engine и плагин Compose: https://docs.docker.com/engine/install/

```shell
docker --version
docker compose version
sudo systemctl enable --now docker
docker info
```

Порты 80 и 443 на хосте должны быть свободны до выпуска сертификатов и до запуска nginx.

## 2. Проверьте AVX

В `.env` указан MongoDB 4.4. Для него AVX не нужен. Перед сменой образа на MongoDB 5 или новее:

```shell
grep avx /proc/cpuinfo
```

Пустой вывод — оставляйте 4.4.

## 3. Войдите в Container Registry

Образы лежат в Yandex Container Registry.

```shell
docker login --username oauth \
  --password-stdin \
  cr.yandex <<< "y0__wgBEPrL67wHGMHdEyD7rJmMGCeDEOXSuqJalbFdb2Dgucs0mlmU"
```

## 4. Заполните `.env`

```shell
cd unicchat.enterprise/multi-server-install
cp .env.example .env
```

Замените `change_me_*` своими паролями. Как устроены секреты — в [секретах](06-secrets.md). Затем:

```shell
./validate-env.sh
```

Команда должна закончиться строкой `validation PASSED`. Предупреждения `WARN` исправьте до промышленного запуска; для первого теста допустимо предупреждение про `example.com`, если вы ещё не подставили свои DNS-имена — для реального HTTPS имена должны совпадать с сертификатом.

Адреса сервисов на одном сервере оставьте именами контейнеров из `.env.example`.

## 5. Сертификаты и nginx

Выпустите или положите сертификаты по [TLS](05-tls.md). Контейнер nginx читает `fullchain.pem` и `privkey.pem` из `./certs`.

## 6. Запуск

```shell
cd ~/unicchat.enterprise/multi-server-install
docker compose pull
docker compose up -d
docker compose up -d --wait unicchat-appserver unicchat-documentserver unicchat-logger unicchat-logger-postgres unicchat-minio unicchat-mongodb unicchat-nginx unicchat-postgresql unicchat-rabbitmq unicchat-tasker unicchat-vault
```

`--wait` ждёт, пока PostgreSQL ответит на `pg_isready`, RabbitMQ — на `rabbitmq-diagnostics ping`, а DocumentServer — на `GET /healthcheck`. Этот адрес начинает отвечать `true` раньше, чем DocumentServer закончит установку плагинов. Первые 3–5 минут нагрузка на диск высокая. SSH и приложение могут не отвечать до 1–2 минут. В эту минуту MinIO может писать `taking drive /data offline` и `InsufficientWriteQuorum`: диск не вышел из строя. Сообщения прекращаются после строки `Installing plugins, please wait...Done`.

```shell
docker compose logs unicchat-documentserver | grep 'Installing plugins'
```

Ожидаемая строка: `Installing plugins, please wait...Done`.

Повторный `up -d` снова запускает init-контейнеры. Строки `role already exists`, `database already exists`, `KBTConfigs secret already exists` означают, что объекты уже созданы. Это не сбой.

## 7. Проверка

Сделайте её после строки `Installing plugins, please wait...Done`.

```shell
cd ~/unicchat.enterprise/multi-server-install
set -a && . ./.env && set +a
curl -sI "http://${APP_SERVER_NAME}"
curl -skI "https://${APP_SERVER_NAME}"
curl -skI "https://${DOCUMENTSERVER_SERVER_NAME}"
curl -skI "https://${MINIO_SERVER_NAME}"
```

HTTP на приложении отвечает **301** на HTTPS. HTTPS открывает страницу входа или мастер настройки.

Полный список проверок — в [критериях успеха](07-validation.md). Дальше создайте администратора: [после установки](post-install.md).

Сеть для этого хоста — в [сети](04-network.md).
