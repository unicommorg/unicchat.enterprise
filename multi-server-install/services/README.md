# UnicChat Services

Эталон — [`docker-compose.yml`](../docker-compose.yml). Теги образов — `IMAGE_*` в `.env`.

- Один сервер: сертификаты (README п. 2.5), затем `docker compose up -d --wait`
- Несколько серверов: свой `compose.<роль>.yml` (mongodb, vault, logger, minio, tasker, knowledgebase, appserver, nginx). Logger — Postgres + `logger-postgres-init`. Nginx — `nginx-config-init` + `unicchat-nginx`. См. README, шаг 2a.

YAML в этом каталоге (`mongodb.yml` и т.д.) — старые контуры, не используйте.
