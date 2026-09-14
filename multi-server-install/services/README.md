# UnicChat Services

Эталон — [`docker-compose.yml`](../docker-compose.yml) (все сервисы и теги `image:`).

- Один сервер: `docker compose up -d --wait`
- Несколько серверов: `docker compose -f compose.<роль>.yml up -d`. Перед запуском сверьте `image:` в файле роли с эталоном. См. README, шаг 2a.

YAML в этом каталоге (`mongodb.yml` и т.д.) — старые контуры, не используйте.
