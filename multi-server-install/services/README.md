# UnicChat Services

Эталон — [`docker-compose.yml`](../docker-compose.yml) (все сервисы и теги `image:`).

- Один сервер: `docker compose up -d --wait`
- Несколько серверов: свой `compose.<роль>.yml` (mongodb, vault, logger, minio, tasker, knowledgebase, appserver, nginx). Перед запуском сверьте `image:` с эталоном. См. README, шаг 2a.

YAML в этом каталоге (`mongodb.yml` и т.д.) — старые контуры, не используйте.
