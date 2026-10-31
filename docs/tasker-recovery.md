# Tasker и KnowledgeBase: проверка зависимостей и восстановление

Эта инструкция относится к клиентской установке из `multi-server-install`:
`unicchat-tasker`, UniVault и секрет `KBTConfigs`. Внутренний Solid `uc.score`,
сеть `vault_default` и `UniVaultToken` из инцидента 30.10.2026 — другая схема.
Команды от неё нельзя переносить в клиентскую установку буквально.

## Перед повторным запуском

На сервере Tasker установите Python 3 и Docker Compose. В `.env` должны быть
актуальные `API_VAULT_URL`, `KBT_MONGO_HOST`, `MONGODB_PORT_NUMBER`, `KBT_MINIO_HOST`.
При нескольких серверах это адреса соседних серверов и опубликованные порты.
Сначала запустите Mongo, MinIO и Vault, завершите init-контейнеры по основной инструкции.
Проверка не выполняет начальную установку и не создаёт секреты.

Из `multi-server-install` выполните:

```console
python3 ops/tasker_recovery.py
# Для нескольких серверов — на сервере Tasker:
python3 ops/tasker_recovery.py --compose-file compose.tasker.yml
```

Временный probe-контейнер проверяет зависимости из `unicchat-network` на сервере
Tasker. Проверка с сервера Vault или центрального Prometheus не заменяет её.
Если Tasker использует нестандартные DNS, extra_hosts, proxy или отдельную сеть,
сначала перенесите эти настройки в overlay: общая Docker-сеть не означает
идентичный сетевой namespace или все настройки контейнера.

Проверки:

- `vault`: получение токена и чтение `/api/Secrets/KBTConfigs/meta` тем же способом,
  что и клиентский Tasker. Одного открытого TCP-порта Vault недостаточно.
- `config`: адреса Mongo и MinIO в существующем секрете совпадают с `.env`.
  Секрет читается каждый раз, включая уже установленную систему. При расхождении
  запуск блокируется; секрет автоматически не изменяется.
- `mongo_tcp`: соединение с адресом Mongo **из секрета**. Это не проверка Mongo
  authentication, primary, прав пользователя или возможности записи.
- `minio_ready`: HTTP 200 от `/minio/health/ready` MinIO **из секрета**. Проверка
  не подтверждает права S3, наличие бакетов или выполнение операций с файлами.

Поддерживается текущий клиентский формат: один Mongo-хост в `mongodb://` и MinIO
`host:port` по HTTP. SRV, несколько Mongo seed-хостов и HTTPS MinIO не поддерживаются
этим probe и приводят к отказу проверки, а не пропуску зависимости.
Токены, metadata, пароли и текст исключений не выводятся.

## Управляемое пересоздание

После устранения причины, когда требуется перезапустить Tasker с конфигурацией:

```console
python3 ops/tasker_recovery.py --recreate
# Несколько серверов:
python3 ops/tasker_recovery.py --compose-file compose.tasker.yml --recreate
```

Каждый вызов сначала выполняет новую проверку. При ошибке код возврата ненулевой,
команда изменения Tasker не вызывается. При успехе пересоздаётся только
`unicchat-tasker` с `--no-deps`; данные и init-контейнеры не изменяются.
Обычные `docker compose up/restart` обходят этот gate. Для регламентных
пересозданий и CI используйте wrapper. Между проверкой и запуском возможен
новый отказ зависимости — preflight не обеспечивает атомарность.

Затем проверьте логи Tasker с момента запуска и пользовательский сценарий:
открытие Tasker, существующей страницы wiki и документа/вложения. Не создавайте
тестовые задачи в рабочем проекте без согласованного тестового пространства.
Код 0 wrapper означает успешный preflight и выполнение Compose, а не успешный
функциональный тест. Экспортёр также не доказывает загрузку модулей.

## Постоянный мониторинг

```console
docker compose -f docker-compose.yml -f compose.dependency-probe.yml up -d --no-deps dependency-probe
# Несколько серверов:
docker compose -f compose.tasker.yml -f compose.dependency-probe.yml up -d --no-deps dependency-probe
curl --fail http://127.0.0.1:9808/metrics
```

По умолчанию порт опубликован только на loopback. Для отдельного Prometheus
задайте `DEPENDENCY_PROBE_BIND` равным приватному IP сервера Tasker и разрешите
TCP/9808 только от коллектора. Повторите запуск exporter после изменения `.env`.
Для изолированной установки заранее зеркалируйте Python image, задав
`IMAGE_DEPENDENCY_PROBE` (предпочтительно проверенный digest).

Проверки повторяются через 30 секунд после завершения предыдущего цикла.
`/metrics` отдаёт последний результат без сетевых запросов к зависимостям.
До первого завершённого цикла значения равны 0. Последнее завершение публикуется
в `unicchat_dependency_check_timestamp_seconds`; зависший цикл обнаруживается
по возрасту результата. В `observability` подготовлены scrape job, пример targets
и правила на ошибки, отсутствие метрик и устаревание результата.

## Разбор сбоя

Если wiki выдаёт `526 Minio` / `ERROR getCurrentNode`, сначала проверьте MinIO,
маршрут и DNS с хоста приложения и Tasker. Исправный exporter на Tasker не
доказывает доступность MinIO с другого AppServer. Перезапуск AppServer без
восстановления MinIO причину не устраняет.

Если в старой Solid-схеме есть `can't load 3 times and was removed`, восстановите
Mongo, MinIO и Vault, затем используйте runbook именно той схемы для recreate
`uc.score`. Для клиентского `unicchat-tasker` такой механизм удаления плагинов
по этому отчёту не подтверждён: не применяйте команды Solid к нему.

После исправления зависимостей зелёные метрики не исключают оставшуюся ошибку
инициализации Tasker. Проверьте логи и пользовательский сценарий отдельно.
Не удаляйте `KBTConfigs` при обычной сетевой ошибке. Если секрет устарел,
сверьте настройки и следуйте разделу основной инструкции «Секрет Vault KBTConfigs».

## Проверка изменений без деплоя

```console
cd multi-server-install/ops
python3 -m unittest -v test_dependency_probe.py
cd ..
docker compose --env-file .env.example -f docker-compose.yml -f compose.dependency-probe.yml --profile operations config --quiet
docker compose --env-file .env.example -f compose.tasker.yml -f compose.dependency-probe.yml --profile operations config --quiet
```

Создание нового `KBTConfigs` также использует `MONGODB_PORT_NUMBER`: раньше
порт проверки задавался из `.env`, а в секрет записывался жёстко заданный 27017.
Существующий секрет этот фикс не перезаписывает.
