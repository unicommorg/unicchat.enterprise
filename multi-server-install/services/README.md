# UnicChat Services

Эталон — [`docker-compose.yml`](../docker-compose.yml) (все сервисы и теги `image:`).

- Один сервер: `docker compose up -d --wait`
- Несколько серверов: `-f docker-compose.yml -f compose.<роль>.yml up -d <сервисы…>`  
  Ролевые файлы **без** `image:` — теги не дублируются. См. README, шаг 2a.

YAML в этом каталоге (`mongodb.yml` и т.д.) — старые контуры, не используйте.
