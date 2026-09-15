# UnicChat Services

Эталон — [`docker-compose.yml`](../docker-compose.yml). Теги образов — `IMAGE_*` в `.env`.

- Один сервер: `docker compose up -d --wait`
- Несколько серверов: свой `compose.<роль>.yml` (mongodb, vault, logger, minio, tasker, knowledgebase, appserver, nginx). См. README, шаг 2a.

YAML в этом каталоге (`mongodb.yml` и т.д.) — старые контуры, не используйте.
