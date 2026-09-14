# UnicChat Services — separate compose files

Канонический путь для новых установок — единый [`docker-compose.yml`](../docker-compose.yml) плюс override при необходимости:

| Задача | Файлы |
|--------|--------|
| Всё на одном хосте (вариант A) | `docker-compose.yml` |
| Nginx и certbot снаружи (вариант B) | `docker-compose.yml` + [`compose.external-nginx.yml`](../compose.external-nginx.yml) |
| База знаний и MinIO на другом хосте, app-сторона (вариант C/D) | `docker-compose.yml` + [`compose.external-kb.yml`](../compose.external-kb.yml) |
| База знаний и MinIO, KB-хост | [`compose.kb-host.yml`](../compose.kb-host.yml) |
| Edge + отдельная KB (вариант D) | на app-хосте оба override; на KB-хосте `compose.kb-host.yml`; nginx — [`nginx/examples/host/`](../nginx/examples/host/) |

Инструкция: корневой [README.md](../../README.md), разделы 2.10–2.12.

## Legacy YAML в этом каталоге

Файлы `mongodb.yml`, `appserver.yml`, `vault.yml`, `logger.yml`, `tasker.yml`, `minio.yml`, `documentserver.yml` оставлены для старых контуров. Образы и пути `env_file` в них **не совпадают** с текущим единым compose. Для клиентских установок их не используйте.

Если всё же запускаете их:

1. Сеть `unicchat-network` должна существовать (`docker network create unicchat-network`).
2. Env-файлы, на которые ссылаются YAML, нужно создать самостоятельно.
3. На разных серверах замените docker-DNS (`unicchat-mongodb` и т.д.) на реальные IP/hostname.
